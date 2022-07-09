library(RODBC)
library(dplyr)
library(glmnet)
library(Metrics)

#load the features table
load("X_features.Rda")


#create a prediction table - take only contact id's for prediction
db = odbcConnect("mysql_server_64", uid="root", pwd="")
sqlQuery(db, "USE ma_charity_full")
query = "
SELECT contact_id, calibration, donation, amount from assignment2;"
a2_table = sqlQuery(db, query)
odbcClose(db)

a2_table= left_join(a2_table, X_features)


# Train set (calibration=1)
data_train = a2_table %>% filter(calibration == 1)
data_train$recency[is.na(data_train$frequency)] <- 50
data_train[is.na(data_train)] <- 0


# Train set only for amount model (we need to take only donation=1)
data_train_amt = a2_table %>% filter(calibration == 1)
data_train_amt = data_train_amt %>% filter(donation == 1)
data_train_amt$recency[is.na(data_train_amt$frequency)] <- 50
data_train_amt[is.na(data_train_amt)] <- 0


# Create test set (calibration=0)
data_test = a2_table %>% filter(calibration == 0)
data_test$recency[is.na(data_test$frequency)] <- 50
data_test[is.na(data_test)] <- 0



#output table
out=data.frame(contact_id=data_test$contact_id)


##############################Probability Model####################################

x = cbind(data_train$recency, 
          data_train$frequency,
          data_train$recency * data_train$frequency,
          log(data_train$recency+1), 
          log(data_train$frequency+1),
          data_train$recency_2017, 
          data_train$recency_2017 * data_train$frequency,
          log(data_train$recency_2017+1), 
          data_train$avgamount,
          data_train$maxamount,
          data_train$minamount,
          data_train$firstdonation, 
          data_train$recency * data_train$maxamount,
          data_train$recency * data_train$minamount,
          data_train$frequency * data_train$maxamount,
          data_train$frequency * data_train$firstdonation,
          data_train$frequency * data_train$avgamount,
          data_train$frequency * data_train$minamount,
          data_train$loyal,
          data_train$n_2018 * data_train$frequency,
          data_train$n_2018 * data_train$row_mean,
          data_train$n_2018 * data_train$recency,
          data_train$MR, 
          data_train$MME, 
          data_train$MLLE,
          data_train$ratio_success,
          data_train$message_success,
          data_train$row_mean,
          data_train$freq_last,
          data_train$last_in_year,
          data_train$first_in_year,
          data_train$n_2018)
y = data_train$donation


ridge = glmnet(x, y, family = "binomial", alpha=0)
lasso = glmnet(x, y, family = "binomial", alpha=1)
cv.lasso = cv.glmnet(x, y, family = "binomial", alpha=1)
best.lambda = cv.lasso$lambda.min

new_x = cbind(data_test$recency, 
              data_test$frequency,
              data_test$recency * data_test$frequency,
              log(data_test$recency+1), 
              log(data_test$frequency+1),
              data_test$recency_2017, 
              data_test$recency_2017 * data_test$frequency,
              log(data_test$recency_2017+1), 
              data_test$avgamount,
              data_test$maxamount,
              data_test$minamount,
              data_test$firstdonation, 
              data_test$recency * data_test$maxamount,
              data_test$recency * data_test$minamount,
              data_test$frequency * data_test$maxamount,
              data_test$frequency * data_test$firstdonation,
              data_test$frequency * data_test$avgamount,
              data_test$frequency * data_test$minamount,
              data_test$loyal,
              data_test$n_2018 * data_test$frequency,
              data_test$n_2018 * data_test$row_mean,
              data_test$n_2018 * data_test$recency,
              data_test$MR, 
              data_test$MME, 
              data_test$MLLE,
              data_test$ratio_success,
              data_test$message_success,
              data_test$row_mean,
              data_test$freq_last,
              data_test$last_in_year,
              data_test$first_in_year,
              data_test$n_2018)

out$probs = predict(lasso, new_x, s = best.lambda, type = "response")

#######################RMSE
#train_predict_prb = data.frame(contact_id=data_train$contact_id)
#train_predict_prb$donation = predict(lasso, x, s = best.lambda, type = "response")
#train_predict_prb = cbind(train_predict_prb$donation)

#train_actual_prb=data.frame(contact_id=data_train$contact_id)
#train_actual_prb$donation = data_train$donation
#train_actual_prb = cbind(train_actual_prb$donation)
#rmse(train_predict_prb,train_actual_prb)
#######################RMSE


##############################Amount Model####################################

x_amt = cbind(data_train_amt$recency_2017 * data_train_amt$frequency, 
              data_train_amt$recency,
              data_train_amt$recency * data_train_amt$frequency,
              log(data_train_amt$recency_2017+1), 
              log(data_train_amt$frequency+1), 
              data_train_amt$loyal,
              data_train_amt$avgamount,
              #data_train_amt$avgamount * data_train_amt$maxamount,
              data_train_amt$maxamount,
              data_train_amt$minamount,
              data_train_amt$avgamount_2017,
              data_train_amt$MR, 
              data_train_amt$MME, 
              data_train_amt$MLLE,
              data_train_amt$ratio_success,
              data_train_amt$message_success,
              data_train_amt$row_mean,
              data_train_amt$freq_last,
              data_train_amt$last_in_year,
              data_train_amt$first_in_year)
y_amt = data_train_amt$amount


ridge = glmnet(x_amt, y_amt, family = "gaussian", alpha=0)
lasso = glmnet(x_amt, y_amt, family = "gaussian", alpha=1)
cv.lasso = cv.glmnet(x_amt, y_amt, family = "gaussian", alpha=1)
best.lambda = cv.lasso$lambda.min

new_x_amt = cbind(data_test$recency_2017 * data_test$frequency, 
                  data_test$recency,
                  data_test$recency * data_test$frequency,
                  log(data_test$recency_2017+1), 
                  log(data_test$frequency+1), 
                  data_test$loyal,
                  data_test$avgamount,
                  #data_test$avgamount * data_test$maxamount,
                  data_test$maxamount,
                  data_test$minamount,
                  data_test$avgamount_2017,
                  data_test$MR, 
                  data_test$MME, 
                  data_test$MLLE,
                  data_test$ratio_success,
                  data_test$message_success,
                  data_test$row_mean,
                  data_test$freq_last,
                  data_test$last_in_year,
                  data_test$first_in_year)


out$amount = predict(lasso, new_x_amt, s = best.lambda, type = "response")

#######################RMSE

#train_predict_amt=data.frame(contact_id=data_train_amt$contact_id)
#train_predict_amt$amount = predict(lasso, x_amt, s = best.lambda, type = "response")
#train_predict_amt = cbind(train_predict_amt$amount)

#train_actual_amt=data.frame(contact_id=data_train_amt$contact_id)
#train_actual_amt$amount = data_train_amt$amount
#train_actual_amt = cbind(train_actual_amt$amount)
#rmse(train_predict_amt,train_actual_amt)
#######################RMSE

#checking = cbind(train_actual_amt$amount, train_predict_amt$amount)
#checking_1 = cbind(checking, train_predict_amt$amount)


#output based on scoring model: if probability * amount is higher than 2, then solicit = 1 
out$score = out$probs * out$amount
z = which(out$score > 2)
print(length(z))


out$solicit = ifelse(out$score >= 2, 1, 0)


save(out,file="out.Rda")



text = data.frame(contact_id = out$contact_id, score = out$solicit)
nrow(text)
write.table(text, file = "output.txt", sep = "\t", row.names =FALSE, col.names = FALSE)


