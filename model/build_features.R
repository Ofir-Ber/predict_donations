#rm(list = ls())
# Load the package
library(RODBC)
library(dplyr)
library(glmnet)
library(Metrics)

#Recency, frequency, avgamount, maxamount, minamount, firstdonation, loyal Features
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, recency, frequency, avgamount, maxamount, minamount, firstdonation from assignment2 as a2
left join
(SELECT a.contact_id,
                DATEDIFF(20180626, MAX(a.act_date)) / 365 AS 'recency',
                COUNT(a.amount) AS 'frequency',
                AVG(a.amount) AS 'avgamount',
                MIN(a.amount) AS 'minamount',
                MAX(a.amount) AS 'maxamount',
                DATEDIFF(20180626, MIN(a.act_date)) / 365 AS 'firstdonation'
         FROM acts a
         WHERE (act_type_id = 'DO')
         GROUP BY 1) as d
on a2.contact_id = d.contact_id
GROUP BY 1"

#create a matrix of features
X_features = sqlQuery(db, query)
odbcClose(db)

#Recency 2017
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, recency_2017 from assignment2 as a2
LEFT JOIN
(SELECT a.contact_id,DATEDIFF(20170626, MAX(a.act_date)) / 365 AS 'recency_2017'
         FROM acts a
         WHERE (act_type_id = 'DO') AND (act_date < 20170626)
         GROUP BY 1) as d
on a2.contact_id = d.contact_id
GROUP BY 1"

recency_2017 = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, recency_2017)


# loyal Feature
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, IF(c.counter IS NULL, 0, 1) AS 'loyal' from assignment2 as a2
LEFT JOIN (SELECT contact_id, COUNT(amount) AS counter
           FROM Acts
           WHERE (act_date >= 20170626) AND
           (act_date <  20180626) AND
           (act_type_id = 'DO')
           GROUP BY contact_id) AS c
ON c.contact_id = a2.contact_id
GROUP BY 1"

loyal = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, loyal)


# Prefix feature 
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, c.prefix_id from assignment2 as a2
left join
(SELECT id, prefix_id FROM contacts) as c
on a2.contact_id = id"

prefix = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, prefix)


#we know if this person is a male or a female, if he or she is not a male or a female than other (0,0,0))
X_features$MR = ifelse(X_features$prefix_id == 'MR', 1, 0)
X_features$MME = ifelse(X_features$prefix_id == 'MME', 1, 0)
X_features$MLLE = ifelse(X_features$prefix_id == 'MLLE', 1, 0)
#drop the prefix column
#X_features <- X_features[-c(9)]



## ratio of successful campaigns in terms of contact_id since 2008

db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT a2.contact_id, c.success / a.num_camp AS 'ratio_success'
FROM assignment2 as a2
LEFT JOIN
(SELECT contact_id, 
count(contact_id) as num_camp FROM actions 
WHERE action_date >= 20080101
GROUP BY 1) AS a
ON a.contact_id = a2.contact_id
LEFT JOIN 
(SELECT contact_id, COUNT(campaign_id) AS success FROM acts 
WHERE act_type_id = 'DO' AND act_date >=20080101 AND campaign_id IS NOT NULL 
GROUP BY 1) AS c
ON a2.contact_id = c.contact_id;"

ratio_success = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, ratio_success)


#Success of messages
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT a2.contact_id, c.mes_success / a.num_mess AS 'message_success'
FROM assignment2 as a2
LEFT JOIN
(SELECT contact_id, 
count(contact_id) as num_mess FROM actions 
WHERE action_date >= 20080101
GROUP BY 1) AS a
ON a.contact_id = a2.contact_id
LEFT JOIN 
(SELECT contact_id, COUNT(message_id) AS mes_success FROM acts 
WHERE act_type_id = 'DO' AND act_date >=20080101 AND message_id IS NOT NULL 
GROUP BY 1) AS c
ON a2.contact_id = c.contact_id;"

message_success = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, message_success)



#Avg days between donations: the average number of days between a donor's donations
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT a2.contact_id, a.days/a.num_donation as 'num_between' from assignment2 as a2
left join
(select contact_id, 
  count(contact_id) as num_donation,
  datediff(max(act_date), min(act_date))/365 as days
  from acts
  where act_type_id = 'DO'
  group by 1) as a
on a2.contact_id = a.contact_id
group by 1;"

Avg_days = sqlQuery(db, query)
odbcClose(db)

X_features = left_join(X_features, Avg_days)



# Average of donations in the last 3 years
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT a2.contact_id,
                     IF(y_2015.counter IS NULL, 0, y_2015.counter) AS 'n_2015',
                     IF(y_2016.counter IS NULL, 0, y_2016.counter) AS 'n_2016',
                     IF(y_2017.counter IS NULL, 0, y_2017.counter) AS 'n_2017'
FROM assignment2 as a2

LEFT JOIN (SELECT contact_id, COUNT(amount) AS counter FROM acts 
WHERE (act_date >= 20150101) AND (act_date <= 20151231) AND (act_type_id = 'DO') 
GROUP BY contact_id) as y_2015
ON y_2015.contact_id = a2.contact_id

LEFT JOIN (SELECT contact_id, COUNT(amount) AS counter FROM acts 
WHERE (act_date >= 20160101) AND (act_date <= 20161231) AND (act_type_id = 'DO') 
GROUP BY contact_id) as y_2016
ON y_2016.contact_id = a2.contact_id

LEFT JOIN (SELECT contact_id, COUNT(amount) AS counter FROM acts 
WHERE (act_date >= 20170101) AND (act_date <= 20171231) AND (act_type_id = 'DO') 
GROUP BY contact_id) as y_2017
ON y_2017.contact_id = a2.contact_id
GROUP BY 1"

average_in_last = sqlQuery(db, query)
odbcClose(db)
average_in_last$row_mean <- rowMeans(average_in_last[ , c(2,3,4)], na.rm=TRUE)
average_in_last <- average_in_last[c(1,5)]

X_features= left_join(X_features, average_in_last)


# Number of times in 2018
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT a2.contact_id,IF(y_2018.counter IS NULL, 0, y_2018.counter) AS 'n_2018'
FROM assignment2 as a2
LEFT JOIN (SELECT contact_id, COUNT(amount) AS counter FROM acts 
WHERE (act_date >= 20180101) AND (act_date <= 20181231) AND (act_type_id = 'DO') 
GROUP BY contact_id) as y_2018
ON y_2018.contact_id = a2.contact_id
GROUP BY 1"

num_2018 = sqlQuery(db, query)
odbcClose(db)

X_features= left_join(X_features, num_2018)


#number of donation at the beginning of the year
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, first_in_year from assignment2 as a2
left join
(select contact_id, count(Month(act_date)) as first_in_year from acts 
where act_type_id = 'DO' and (Month(act_date)<7)
group by 1) as d
on a2.contact_id = d.contact_id
GROUP BY 1"
first_in_year = sqlQuery(db, query)
odbcClose(db)

X_features= left_join(X_features, first_in_year)

#number of donation at the end of the year
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, last_in_year from assignment2 as a2
left join
(select contact_id, count(Month(act_date)) as last_in_year from acts 
where act_type_id = 'DO' and (Month(act_date)>=7)
group by 1) as d
on a2.contact_id = d.contact_id
GROUP BY 1"
last_in_year = sqlQuery(db, query)
odbcClose(db)

X_features= left_join(X_features, last_in_year)


#average amount in 2017
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "select a2.contact_id, avgamount_2017 from assignment2 as a2
left join
(SELECT contact_id,AVG(amount) AS 'avgamount_2017'
         FROM acts
         WHERE (act_type_id = 'DO') AND (act_date >= 20170101) AND (act_date <  20180101)
         GROUP BY 1) as d
on a2.contact_id = d.contact_id
GROUP BY 1"

avgamount_2017 = sqlQuery(db, query)
odbcClose(db)

X_features= left_join(X_features, avgamount_2017)


#save table of features
save(X_features,file="X_features.Rda")




