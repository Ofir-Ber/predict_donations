# Predict Donations

The goal is to predict who is likely to make a donation to the charity for a specific fundraising campaign (%),
and  how  much  money  they  are  likely  to  give  if  they  do  (€).  By  combining  these  two 
predictions (% * €), we will obtain an expected revenue from each individual.
Every solicitation costs 2.00 €

If the expected revenue we have predicted exceeds that figure of 2 €, we will recommend the charity 
to solicit that individual (solicit = 1), since the expected profit is positive. If it is below 2 €, we will 
recommend the charity not to solicit that individual (solicit = 0), since on average we expect a loss. 
Our objective is to maximize the financial performance of that campaign for the charity.


# Data set
On the last day of data available in the database, the charity has solicited 123,672 donors for their 
June campaign. 
Out  of  these  123 ,672  solicited  donors,  about  ~12,700  have  made  a  subsequent  donation. 
We don't know which contacts have decided to make a donation and for how much, and who did not, has been observed and is 
known by the professor. 
These 123,672 solicited donors have been divided into two batches of approximately equal sizes. 
For the first batch (N = 61,928), called the “calibration” data, we have complete information about 
their responses to the fundraising campaign. This batch will be used for calibration. 
For the second batch (N = 61,744), called the “prediction” data, we only know that they have been 
solicited, but their actual responses have not been communicated to us, and have been excluded 
from the data we have received. This batch will be used for performance evaluation. 

All that information is contained in the “assignment2” table: 
- contact_id: The  list  of  individuals  who  have  been  solicited  by  the  charity  for  this 
specific fundraising campaign. 
- calibration 1: if part of the calibration data, 0 if part of the prediction data. 
- donation 1: if the donor has made a donation, 0 if the donor has not, NULL if the 
information  is  unknown  to  you.  By  design,  the  value  is  set  to  NULL  if 
calibration = 0. 
- amount: The actual donation amount observed, in EUR. The value is NULL if the 
donor has not made any donation (donation = 0) or if the response has 
not been communicated to you for this individual (calibration = 0). 
- act_date  The date at which the donation has been made. The value is NULL if the 
donor has not made any donation (donation = 0) or if the response has 
not been communicated to you for this individual (calibration = 0). 


# Process
1. Calibrate  a  discrete model  (%)  to  predict  the  likelihood  of  donation  (on  individuals  where 
calibration = 1) 
2. Calibrate  a  continuous  model  (€)  to  predict  the  most  likely  donation  amount  in  case  of 
donation (on the subset of individuals where donation = 1) 
3. Apply both models to the prediction data (i.e., individuals where calibration = 0), and multiply 
these predictions (% and €) to obtain expected (predicted) revenue if solicited. 
4. If expected revenue is superior to 2.00 €, solicit (=1); otherwise do not (=0).
