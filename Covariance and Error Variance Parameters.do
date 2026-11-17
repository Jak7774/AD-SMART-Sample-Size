* -------------------------------------------------------
*  Analysis of CPAD Data for ADAS-COG Outcomes
*	to look at correlation, SD, linear trend etc
*  Version 2.0
*  5nd Sept 2023
* -------------------------------------------------------

* Data From James Carpenter
cd "/Users/emsujcar/MRC-CTU/neuro/Alzheimers/EME_2nd_round/data"

clear
import delimited using "ADASCOG_FLAT", varnames(1) delimiters(",")
  
  
* ------------------------------------------
* Data Cleaning Steps
* ------------------------------------------

replace score="." if score=="NA"
destring score, replace

replace qsdy="." if qsdy=="NA"
destring qsdy, replace

replace age="." if age=="NA"
destring age, replace

sort qsdy

* Sort Out Time WIndows
count  if (qsdy > 5 & qsdy < 40 & studyid=="1000") // 92
summ score  if (qsdy > 5 & qsdy < 40 & studyid=="1000")

* if qsdy < 15 then call it baseline
count if qsdy <=0 // N=8703
count if qsdy >0 & qsdy <15 // N=23

gen time=.
label var time "rounded visit time in years from baseline"
replace time=0 if qsdy < 15
count if qsdy > 150 & qsdy < 200 // N=4713
replace time=0.5 if qsdy > 150 & qsdy < 200

count if qsdy > 340 & qsdy < 380 // N=2759
replace time=1 if qsdy >340  & qsdy < 380

count if qsdy >520 & qsdy < 560 // N=1547 
replace time=1.5 if qsdy > 520  & qsdy <560

drop if time==. // N=19961 deleted 

* ------------------------------------------
* Remove Multiple Rows with Same Time Value
* ------------------------------------------

* some people with multiple readings at a particular 'time'
* only keep 1. don't worry about which is closest to the actual time

sort usubjid time
by usubjid time: gen ono=_n

count if time==0 // N=8726
count if time==0 & ono>1 // N=2908
count if time==0.5 // N=4713
count if time==0.5 & ono>1 // N=17
count if time==1 // N=2759
count if time==1 & ono>1 // N=44
count if time==1.5 // N=1547
count if time==1.5 & ono>1 // N=0


count if ono>1 // N=2969
drop if ono > 1
 
drop ono 
drop qsdy

* Convert Time to Days
replace time = time*365
replace time=182 if time==182.5
replace time=547 if time==547.5

* Summarise ADAS-COG Scores

reshape wide score , i(usubjid) j(time)
tabstat score* , stat(mean sd n)

*
*   stats |    score0  score182  score365  score547
*---------+----------------------------------------
*    mean |  21.98762  22.56934  22.51115  22.68793
*      sd |  9.936666  11.15621  11.97056  13.34439
*       N |      5761      4603      2658      1509
*--------------------------------------------------

pwcorr score*


*             |   score0 score182 score365 score547
*-------------+------------------------------------
*      score0 |   1.0000 
*    score182 |   0.8717   1.0000 
*    score365 |   0.8351   0.8947   1.0000 
*    score547 |   0.8007   0.8666   0.9083   1.0000 


* centre age
gene cage = age-25
reshape long

* ---------------------------------------------------
*Overall mixed model: (fixed effect for study)
* ---------------------------------------------------

* Generate Dummy Variables
gene nsex=0
replace nsex=1 if sex=="M"

replace time=time/365

gen temp=studyid
replace temp="1049" if studyid=="AD-1049"
destring temp, replace
rename temp nstudyid

* Run Mixed Effect Model
mixed score time cage i.nsex i.nstudyid || usubjid: time , var reml cov(un)


/*


Mixed-effects REML regression                   Number of obs     =     14,527
Group variable: usubjid                         Number of groups  =      5,786

                                                Obs per group:
                                                              min =          1
                                                              avg =        2.5
                                                              max =          4

                                                Wald chi2(21)     =    2289.19
Log restricted-likelihood = -47996.465          Prob > chi2       =     0.0000


------------------------------------------------------------------------------
       score |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
        time |   2.731971   .1073853    25.44   0.000       2.5215    2.942443
        cage |   .0010616   .0014068     0.75   0.450    -.0016956    .0038189
      1.nsex |   -.866504   .2306849    -3.76   0.000    -1.318638   -.4143699
             |
    nstudyid |
       1009  |   9.874574   1.123122     8.79   0.000     7.673295    12.07585
       1013  |   8.841569   .9340348     9.47   0.000     7.010895    10.67224
       1014  |    6.70035   .9411562     7.12   0.000     4.855717    8.544982
       1049  |   2.059476    1.06309     1.94   0.053    -.0241419    4.143094
       1055  |    10.1011   1.145535     8.82   0.000     7.855889     12.3463
       1056  |   10.05793   .9637287    10.44   0.000     8.169056     11.9468
       1057  |    11.3261   .9625042    11.77   0.000     9.439624    13.21257
       1058  |   10.89864   1.121489     9.72   0.000     8.700562    13.09672
       1105  |   7.814653   1.004233     7.78   0.000     5.846393    9.782913
       1131  |   6.556489   1.465463     4.47   0.000     3.684233    9.428745
       1132  |   5.891793   .9783648     6.02   0.000     3.974233    7.809353
       1133  |   13.32376   1.121487    11.88   0.000     11.12568    15.52183
       1135  |   10.75159   1.028016    10.46   0.000     8.736714    12.76646
       1137  |    13.9201   1.065981    13.06   0.000     11.83082    16.00938
       1138  |   14.33458   1.077264    13.31   0.000     12.22318    16.44598
       1140  |   5.486791   1.159542     4.73   0.000      3.21413    7.759452
       1141  |  -3.280708   .9591332    -3.42   0.001    -5.160574   -1.400841
       1142  |   7.771179   .9755777     7.97   0.000     5.859082    9.683276
             |
       _cons |   14.42154   .8859012    16.28   0.000      12.6852    16.15787
------------------------------------------------------------------------------

------------------------------------------------------------------------------
  Random-effects Parameters  |   Estimate   Std. Err.     [95% Conf. Interval]
-----------------------------+------------------------------------------------
usubjid: Unstructured        |
                   var(time) |   24.69075   1.151252      22.53437    27.05348
                  var(_cons) |   66.46747   1.448623        63.688    69.36823
             cov(time,_cons) |   20.39907   1.061318      18.31893    22.47922
-----------------------------+------------------------------------------------
               var(Residual) |   12.10415   .2464492      11.63063    12.59695
------------------------------------------------------------------------------
LR test vs. linear model: chi2(3) = 11573.61              Prob > chi2 = 0.0000


*/

