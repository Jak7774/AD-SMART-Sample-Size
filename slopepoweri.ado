*! version 2.1	19November2020
*! Stephen Nash
*! Katy Morgan	katy.morgan@lshtm.ac.uk
*! Amy Mulick	amy.mulick@lshtm.ac.uk

/*
DESCRIPTION
Sample size and power calculator for slope outcomes using a linear mixed model on 
data in memory for estimation of key parameters.

slopepower performs a sample size or power calculation for a proposed randomised 
clinical trial, based partly upon data in Stata’s memory and partly on user 
input. A linear mixed model is run (using mixed) on the data in memory to 
estimate a plausible treatment effect and its variance; the remaining parameters
are specified by the user. The data should come from an observational study or 
a similar clinical trial and contain repeated measurements of the outcome in 
long format.

The data in memory will not be altered by this program.    

NOTE!!
25th March 2024
This is slopepoweri - above description to be changed to reflect alteration to a user input version of command
*! Matthew Burnell m.burnell@ucl.ac.uk  (MB) 
Further changes added by Katy Morgan (KM)
*/


cap prog drop slopepoweri  // been reading up on how this omnipresent line is irrelevant!
program define slopepoweri , rclass
	version 13.0 // Due to use of the -mixed- command, which was introduced in v13 ** Would it be best to change to a newer/different version given no use of mixed command?
	syntax ,  SCHEDule(numlist ascending >=0) [ EFFectiveness(string) ///
				CONTrolslope(string) DIFFerence(string) SCAle(real 1) Alpha(real 0.05) ///
				COVariance(string) ERRorvar(string) MIXED DROPouts(numlist >=0 <=1)) ///
				STRECruitment(numlist >=0 <=1) POWer(string) n(string) ]
			** Either CONTrolslope now needed as argument + EFFectiveness as no fitted model to automatically provide 'control' slope i.e % change (EFF) vs what? Can be a number or a string of the name of the variable that is the slope term in a mixed model in memory. Note CONTrolslope can be number or the name of variable in (mixed) model in memory used as mean slope term.
			** Or can just use DIFFererence to state the absolute difference in slope per unit of time. 
			** MIXED allows user to use the returned covariance from a mixed model in memory
			** Or input version is a matrix for COVariance. The matrix can be inputted dircectly into the brackets after COVariance option, or can be a name of matrix. Matrix must be 2x2 symmetric. This option needs a value for ERRorvar too.  
			** STREC for staggered recruitment requires numlist that is n+1 where n is the length of SCHEDULE and DROPouts. STREC requires that numbers represent p(make first k visits but no further), incuding for baseline. Need to sum to one. If some patients not yet entered trial then currently you need to downscale n and upscale the probabilities so sum still==1
			** KM: STREC changed to length n, where final number is 1 - the others, to avoid issues with checks on strec adding to 1.
			
			/* syntax issues to consider (Post slopepower2):  
			# how to entrer COVariance numbers  - number list (n=3) or matrix like drawnorm? DONE
			# allow Schedule to have fractional values directly? and how to incorporate NOT DONE - not possible with matrix code as is - would require complete rewrite
			# therefore still keep scale? - SCALE KEPT for purposes only of fractional schedule time. The output reflects the scale you actually are 'interested in'
			# currently effect size only % change (EFFectiveness) but what about absolute slope change? DONE
			# specifying DROPouts and STRECruitment values - currently different format but should they be the same format? Should DROPouts be changed to p(make first k visits but no further)? KEPT as different length specifications
			
			# plus - change name to slopepoweri ! DONE
			*/
			
		preserve // We're going to change the data - drop rows and create new vars DROP? - Leaving preserve and restore in for now - MB

			 {

				* CHECK THE OPTIONS ARE VALID - including how to input data: following a mixed model (MIXED) in memory or giving covariance and error arguments directly MB
				
				** Check either MIXED or ERRorvar & COVariance used
								*  Check either used Effectiveness + Controlslope OR Difference
				if "`covariance'"!="" & "`mixed'"!="" {
					dis as error "You cannot specify both covariance (together with errorvar) and mixed"
					exit 198
				}
				if "`covariance'"=="" & "`errorvar'"=="" & "`mixed'"=="" {
					dis as error "No variance parameter specification: please specify either covariance and errorvar OR mixed"
					exit 198
				}
				
				* check errorvar and mixed not both specified
				if "`errorvar'"!="" & "`mixed'"!="" {
					dis as error "You cannot specify both errorvar (together with covariance) and mixed"
					exit 198
				} 
				* Check  error variance included if covariance used 
				if "`covariance'"!="" & "`errorvar'"=="" {
					dis as error "You must specify errorvar as well as covariance"
					exit 198
				}
				* Check covariance included if errorvar used 
				if "`covariance'"=="" & "`errorvar'"!="" {
					dis as error "You must specify covariance as well as errorvar"
					exit 198
				}
				
				
				** Check values
				* Check COVariance is a 2x2 symmetric matrix
				if "`covariance'"!="" {
					tempname cov_mat
					mat `cov_mat'=`covariance'
					local col=colsof(`cov_mat')
					local sym= issymmetric(`cov_mat')

					if `sym' ==0 | `col'!=2 {
						dis as error "matrix must be symmetric 2x2"
						exit 198
					}
				}
				
				**  Check either used Effectiveness + Controlslope OR Difference
				
				
				if "`effectiveness'"!="" & "`difference'"!="" {
					dis as error "You cannot specify both effectiveness (together with controlslope) and difference"
					exit 198
				}
				if "`effectiveness'"=="" & "`difference'"=="" {
					dis as error "No target treatment effect specification: please specify either effectiveness and controlslope OR difference"
					exit 198
				}
				
				* check errorvar and mixed not both specified
				if "`controlslope'"!="" & "`difference'"!="" {
					dis as error "You cannot specify both controlslope (together with effectiveness) and difference"
					exit 198
				} 
				* Check  error variance included if covariance used 
				if "`effectiveness'"!="" & "`controlslope'"=="" {
					dis as error "You must specify both effectiveness and controlslope"
					exit 198
				}
				* Check covariance included if errorvar used 
				if "`effectiveness'"=="" & "`controlslope'"!="" {
					dis as error "You must specify both effectiveness and controlslope"
					exit 198
				}
				
				
				
				
				* Now check effectiveness is a number >0 and <= 1   
				if "`effectiveness'"!="" { // Effectiveness is specified
					capture confirm number `effectiveness'
					if _rc!=0 {
						dis as error "Effectiveness must be a number greater than 0 and less than or equal to 1"
						exit 198
					}
					* So eff is specified and it's a number
					if `effectiveness' > 1 {
						dis as error "Effectiveness must be less than or equal to 1"
						exit 198
					}
					if `effectiveness' <=0 {
						dis as error "Effectiveness must be strictly greater than 0"
						exit 198
					}

					* Now check controlslope is a number - or instead variable name for slope term in mixed model in memory
					if "`controlslope'"!="" { // controlslope is specified
						capture confirm number `controlslope'
						if _rc==0 {
							local sm_num=1
						}
						if _rc!=0 {
							local sm_num=0
							local b_name "`controlslope'"
							tempname beta
							capture scalar `beta'=_b[`b_name'] // using the slope from mixed - doesn't always work if the variable isn't in the dataset! though can just create a fake variable  with that name...					
						}

					}
							
					if "`controlslope'"=="" {
						dis as error "the expected mean slope in the control group (controlslope) must be a number or the name of the slope in a mixed model in memory"
						exit 198
					}
									
									
				} // If statement "eff is specified"
								
								
				* Now check if using difference that it is a number   
				if "`difference'"!="" { // difference is specified
					capture confirm number `difference'
					if _rc!=0 {
						dis as error "difference must be specified as a numerical value"
						exit 198
					}
				}
		
		
				* ALPHA: Should be between 0 and 1 
				if `alpha'<=0 | `alpha'>=1 {
					dis as error "Alpha must be a number greater than 0 and less than 1"
					exit 198
				}
				
				
				*POWER AND N 						
					* Must specify one of power or N: 4 possible cases...
					
				* 1. 1. Both power an n specified - error
				if "`power'"!="" & "`n'"!="" {
					display as error "Only one of power and n may be specified, not both"
					exit 184
				}
				
				* 2. Power is specified, n is missing - okay - we'll calculate SAMPLE SIZE (N)
				if "`power'"!="" & "`n'"=="" {
					local given_power=real("`power'")
					if missing(`given_power') { // ...but power isn't a number
						dis as error "Power must be a number greater than 0 and less than 1"
						exit 198
					}
					local power_or_n power
				}
				
				* 3. Power is absent, n is specified - okay - we'll calculate POWER
				if "`power'"=="" & "`n'"!="" { // 
					local given_n=floor(real("`n'"))
					if missing(`given_n') { // ...but n isn't a number
						dis as error "n must be a numerical value"
						exit 198
					}
					if `given_n' != `n' { // The floor of n must be the same as n... ie n cannot be fractional
						dis as error "n must be a whole number greater than or equal to 2"
						exit 198
					}
					if `given_n' < 2 { // N must be at least 2
						dis as error "n must be at least 2"
						exit 198
					}
					local n = ceil(`given_n')
					local power_or_n n
				}
				
				* 4. Both power and n absent: okay, use default value for power - we'll calculate SAMPLE SIZE (N)
				if "`power'"=="" & "`n'"=="" {
					local given_power = 0.8 // Default power is 80%
					local power_or_n power
				}
				
				* Check values
				if "`power_or_n'"=="power" { // Power is specified - we already know it's a number.
					if `given_power'>=1 {
						dis as error "Power must be a value strictly less than 1"
						exit 198
					}
					if `given_power'<=0 {
						dis as error "Power must be a value greater than 0"
						exit 198
					}
				}
				if "`power_or_n'" == "n" { // N is specified - we already know it's a number
					* Make sure it's even, or round down
					local actual_n = 2 * floor(`given_n' / 2)
					if `given_n'<2 {
						dis as error "n must be a number greater or equal to 2"
						exit 198
					}
				}
					
					
				* SCALE  
				if `scale' <= 0 {
					dis as error "Scale must be a positive number"
					exit 198
				}
				
					
				** PARAMETERS TO PASS TO MATRIX ALGEBRA (RE covariance terms and error variance) AND SS/POWER CALCULATIONS (so plus Control slope and TTE or DIFFerence term) AND GO THROUGH POTENTIAL SCALING PHASE
					
				qui tempname  var_slope var_int cov_slopeint corr_slopeint var_res tte ///
					controlslope_sc mean_cont_slope difference_sc 
	
				** Error variances
				if "`errorvar'"!="" { // version for if numbers entered directly
					capture confirm number `errorvar'
					if _rc!=0 {
						dis as error "error variance must be a number greater than 0"
						exit 198
					}
					else if `errorvar' <= 0 {
						dis as error "error variance must be greater than 0"
						exit 198
					}
					scalar `var_res'=`errorvar' // error variance
				}
				if "`mixed'"!="" { // version for if using mixed model in memory
					if e(redim)!="2" {
						dis as error "mixed model does not contain a random intercept and a random slope only"
						exit 198
					}
					scalar `var_res'=(exp(_b[lnsig_e:_cons]))^2
				}
					
				
				** Random effect covariance matrix	
				if "`covariance'"!="" { // version for if numbers entered directly as matrix
					local intvar= el(`cov_mat', 1, 1)  
					if `intvar' <= 0 {
						dis as error "intercept variance must be a positive number"
						exit 198
					}
						
					local slvar= el(`cov_mat', 2, 2)  
					if `slvar' <= 0 {
						dis as error "slope variance must be a positive number"
						exit 198
					}
					
					local cov= el(`cov_mat', 1, 2)  
						
					** Rescale the variance terms that need rescaling (random intercept variance doesn't) - scale==1 if unspecified i.e no rescaling		
					scalar `var_slope'=(`scale'*(sqrt(`slvar')))^2 // Variance of time (random slopes)  - rescaled if necessary 
					scalar `var_int'=`intvar' // Variance of random intercepts 
					scalar `corr_slopeint'=`cov'/(sqrt(`slvar')*sqrt(`intvar')) // correlation of random effects 
					
					if `corr_slopeint' < -1 | `corr_slopeint' > 1 {
						dis as error "correlation between random intercepts and slopes must be between -1 and +1"
						exit 198
					}
					
					scalar `cov_slopeint'=`corr_slopeint'*sqrt(`var_int')*sqrt(`var_slope')  // rescaled covariance, if necessary		
				}
					
					
				if "`mixed'"!="" { // version for if using mixed model in memory
					scalar `var_slope'=(`scale'*(exp(_b[lns1_1_1:_cons])))^2 // Variance of time  - rescaled if necessary 
					scalar `var_int'=(exp(_b[lns1_1_2:_cons]))^2 // Variance of  intercept 
					if e(vartypes)=="Unstructured" {
						scalar `corr_slopeint'=tanh(_b[atr1_1_1_2:_cons]) // correlation of random effects 
					}
					if e(vartypes)=="Independent" {
						dis as error "Warning: mixed model has been fitted using Independent option, forcing the correlation between random intercepts and slopes to be zero"
						scalar `corr_slopeint'=0 // correlation of random effects 
					}	
					scalar `cov_slopeint'=`corr_slopeint'*sqrt(`var_int')*sqrt(`var_slope')  // rescaled covariance, if necessary		
				}
					
					
				** Rescale Control mean slope
					
				if "`controlslope'"!="" {	
					if `sm_num'==1 { // version if slope specified as number
						scalar `controlslope_sc'=`controlslope'*`scale'
						scalar `mean_cont_slope'=`controlslope'
						scalar `tte' =  abs(`mean_cont_slope') * `effectiveness'
					}
					if `sm_num'==0 { // version if slope value taken from mixed model slope (`beta')
						scalar `controlslope_sc'=`beta'*`scale'
						scalar `mean_cont_slope'=`beta'
						scalar `tte' =  abs(`mean_cont_slope') * `effectiveness'
					}
				}	
					
				** Rescale Slope Difference parameter
				if "`difference'"!="" {
					scalar `difference_sc'=`difference'*`scale'
					scalar `tte'=abs(`difference')
				
				}
				

				
				* SCHEDULE LIST 
				* Length of schedule list:
				local sched_length = 0
				foreach i of numlist `schedule' {
					local sched_length = `sched_length ' + 1
				}
				* Decant the schedule numlist into locals
				local j = 1 // counter - position number
				foreach i of numlist `schedule' {
					local sched`j' = `i'
					local j=`j'+1
				}
				* Get a nice schedule string with commas for output
				foreach i of numlist `schedule' {
					local sched_string `"`sched_string'`i', "' // Adds commas to the numlist, for use in output
				}
				* Remove the last comma from the schedule string
				local ss = strlen("`sched_string'") - 2
				local sched_string = substr("`sched_string'", 1, `ss')
				
				
				*
				* DROPOUTS    
				* Is there a dropout list specified?
				local drop_yes = 0
				if "`dropouts'"!="" local drop_yes = 1
				* Decant dropout numlist into locals and calculate people who attend all visits
				local dfrac_complete = 1 // The proportion attending all visits - one unless dropouts specified

				if `drop_yes'==1 {
					local j = 1 // counter - position number
					foreach fr of numlist `dropouts' {
						*local dfrac`sched`j'' = `fr'
						* second version that doesn't use sched`j' in name
						local dfrac2_`j' = `fr'
						local j = `j' + 1
						local dfrac_complete = `dfrac_complete' - `fr'
					}
					* Check the drop matrix adds up to less than 100%
					if `dfrac_complete' < 0 {
						display as error _n "Dropouts cannot exceed 100%"
						exit 198
					}
					* Drop matrix must be same length as Schedule matrix
					* Length of dropout list
					local drop_length = 0
					foreach i of numlist `dropouts' {
						local drop_length = `drop_length ' + 1
					}
					* Is this equal to schedule matrix?
					if `sched_length' != `drop_length' {
						dis as error _n "Dropout list must correspond with visit schedule"
						exit 198
					}
						
					** NEW BIT FOR DROPOUT SECTION
					* Turn dropouts proportions into proportion list where number (each<1 and together sum to 1) represents proportion that make it only 'upto' that visit, including a value for visit 0 i.e baseline, to make same as STREC
					local visD_pr  "`dropouts' `dfrac_complete'"
				}
					

					
				* STAGGERED RECRUITMENT     -- Have this section structured as same for DROPouts above, in case we change way of specifying STREC: but currently not used in the calculation part as we are asking to give the proportions that make upto visit k but no further, which is what we ultimately want for calculations. Note though does check length is 'one longer' than schedule.
					
				* Is there a strec list specified?
				local strec_yes = 0
				if "`strecruitment'"!="" local strec_yes = 1
				* Decant strec numlist into locals and calculate people who attend all visits
				local rfrac_complete = 1 // The proportion attending all visits - one unless dropouts specified
				if `strec_yes'==1 {
					local j = 1 // counter - position number
					foreach rfr of numlist `strecruitment' {
						*local rfrac`sched`j'' = `rfr'
						* second version that doesn't use sched`j' in name
						local rfrac2_`j' = `rfr'
						local j = `j' + 1
						local rfrac_complete = `rfrac_complete' - `rfr'   
					}
					* Check the strec matrix adds up to less than 100%
					if `rfrac_complete' < 0 {
						display as error _n "Staggered recruitment list cannot exceed 100%"
						exit 198
					}
					* Strec numlist must be same length Schedule numlist
					* Length of strec list
					local strec_length = 0
					foreach i of numlist `strecruitment' {
						local strec_length = `strec_length' + 1
					}
					* Is this equal to schedule numlist+1?
					if `sched_length' != `strec_length' {
						dis as error _n "Staggered recruitment list must correspond with visit schedule"
						exit 198
					}		
					
					* add final entry to strec list of 1 - the other numbers
					local visS_pr "`strecruitment' `rfrac_complete'"
				}
					
					
				** Now produce integrated weightings if strec list and dropout list both specified - THIS CODE PROBABLY NEEDS CHECKING - MAYBE ALSO BE MORE EFFICIENTLY CODED??
				/* basic idea is 
					For those that reach visit k (and no further) due to staggered recruitment and a fixed analysis timepoint in calendar time, they have have a unique 'dropout' function where upto k-1 the probs equal the same dropout values (i.e `visD_pr' NOT `dropout') but the last one (k) is the remainder probability
					Then multiply strec weight and dropout weight and sum over all occasions that relate to that visit schedule 'experience' i.e. k visits and no further
				*/
				if "`strecruitment'"!="" &  "`dropouts'"!="" {
					/*
					local totalwgt 
					local count1: word count `strecruitment'
					local count2: word count `visD_pr'
					forvalues j=1/`count2' {
						local ttlwgt`j'
						local fwgt`j'=0
					}
					local finalwgts 
								
					forvalues i=1/`count1' {
						local w3=0
						local w1: word `i' of `strecruitment'
						forvalues j=1/`i'	{							
							local w2: word `j' of `visD_pr'
							local w4=1-`w3'	// the 'remainder' probability
							local w3=`w3'+`w2'
						
							if `j'==`i' {
								local prodwgt`j'=`w1'*`w4'
								local prodwgt=`w1'*`w4'
							}
							else {
								local prodwgt`j'=`w1'*`w2'
								local prodwgt=`w1'*`w2'
							}
					
							local k=`j'
							local  totalwgt "`totalwgt' `prodwgt'"
							local ttlwgt`j' "`ttlwgt`j'' `prodwgt`j''"
							local fwgt`k'= `fwgt`j''+ `prodwgt`j''
												
						}				
					}

					forvalues i=1/`count1' {
						local  finalwgts "`finalwgts' `fwgt`i''"				
					}	
					*/
					
					local count: word count `visS_pr'

					local finalwgts
					forval i = 1/`count' {
						local w_inv = 1
						local w1: word `i' of `visS_pr'
				
						forval j = 1/`i' {
							local w2: word `j' of `visD_pr'

							if `i' == `j' {
								local weight_`j' = `weight_`j'' + `w1'*`w_inv'
							}
							else {
								local weight_`j' = `weight_`j'' + `w1'*`w2'
							}
							
							local w_inv = `w_inv' - `w2'		
						}
					}
					
					forvalues i=1/`count' {
						local  finalwgts "`finalwgts' `weight_`i''"
					} 
					
					
				}
					

					
				** Choose which weights to use  - dropout only, strec only... or the integration of both version (above)
					
				if "`strecruitment'"!="" &  "`dropouts'"!="" {
					local ct1: word count `finalwgts' 
					*local ct1_1=`ct1'-1
					local fwgts_m1 
					forvalues i=1/`=`ct1'-1' {			// was reporting back from i=2/`ct1' hence the loop to create list but now keeping list of reported probabilities in line with original slopepower
						local iwgt1: word `i' of `finalwgts'
						local fwgts_m1 "`fwgts_m1' `iwgt1'"
					}
					
					local	dropouts "`fwgts_m1'"
				}
				
				if "`strecruitment'"=="" &  "`dropouts'"!="" {					
					local	dropouts "`dropouts'"	
				}
				
				if "`strecruitment'"!="" &  "`dropouts'"=="" {					
					local	dropouts "`strecruitment'"
				}
				

				
				** put chosen weights back into dropout section code - KEPT THE ABOVE CODE FOR DROPOUT REPEATED AS EASIEST - THE CHECKING OF LENGTH AND VALUES ONCE MORE NOT REALLY NEEDED AGAIN!
				
				* Is there a dropout list specified?
				local drop_yes = 0
				if "`dropouts'"!="" local drop_yes = 1
				* Decant dropout numlist into locals and calculate people who attend all visits
				local dfrac_complete = 1 // The proportion attending all visits - one unless dropouts specified
				if `drop_yes'==1 {
					local j = 1 // counter - position number
					foreach fr of numlist `dropouts' {
						*local dfrac`sched`j'' = `fr'
						* second version that doesn't use sched`j' in name
						local dfrac2_`j' = `fr'
						local j = `j' + 1
						local dfrac_complete = `dfrac_complete' - `fr'
					}

					* Get a nice schedule string with commas for output
					local j = 0 // counter - position in schedule list
					local sched_string ""
					foreach i of numlist `schedule' {
						local j = `j'+1
						local dfrac2_`j'_display: display %3.2f `dfrac2_`j''
						if `dfrac2_`j'' != 0 local sched_string `"`sched_string'`i' (`dfrac2_`j'_display'), "' // Adds commas to the numlist, for use in output
						else local sched_string `"`sched_string'`i' (0), "' // Adds commas to the numlist, for use in output
					}
					
					* Remove the last comma from the schedule string
					local ss = strlen("`sched_string'") - 2
					local sched_string = substr("`sched_string'", 1, `ss')	
					
					* Get second schedule string for output, containing fraction of "completers" - i.e. those who are still in the trial at each visit
					local j = 1 // counter - position number
					local frac_comp0 = 1
					local sched_string2 ""
					
					foreach fr of numlist `dropouts' {
						local frac_comp`j': display %3.2f `frac_comp`=`j'-1'' - `fr'
						local sched_visit`j': word `j' of `schedule'
						local sched_string2 `"`sched_string2'`sched_visit`j'' (`frac_comp`j''), "' // Adds commas to the numlist, for use in output					
						local j = `j' + 1
					}
					
					* Remove the last comma from the schedule string
					local ss = strlen("`sched_string2'") - 2
					local sched_string2 = substr("`sched_string2'", 1, `ss')
				}				
		
			
			} // End quietly
			



			*************************************
			**
			** MATRIX SECTION
			** completely unchanged MB
			*************************************
			quietly {
/*
				tempname V VSTAR X DSTAR XSTAR F1STAR FSTAR visit_matrix COV
				
				foreach i of numlist `schedule' {
					tempname DROP`i' DROP`i'STAR DROP
				}
*/
				
				* First, need to make a visit schedule matrix
				* from the user inputted visit schedule, which is just a numlist...
	
				* What's the biggest number (=number of timepoints), and how many are in the list? (vvv)
				local vvv = 0 // This will count the elements of the numlist
				foreach i of numlist `schedule' { // We want: (i) timepoint of last visit (ii) number of visits and (iii) a nice string of visit times
					local tpoints = `i' + 1
					local vvv = `vvv' + 1
				}
/*				
				* Add one to the number in the list to get the number of rows we need visit_matrix to have
				local vplus1 = `vvv' + 1
				
				* Make a `vplus1' x `tpoints' matrix, all zeros
				matrix `visit_matrix' = J(`vplus1', `tpoints', 0)
				
				* Make the first row 1, 0, 0... 
				matrix `visit_matrix'[1,1] = 1
				
				* Fill in the (i+1,j+1) element (=1) where j is the value of the ith number
				local i = 2 // We need the +1's because our matric starts with timepoint 0
				foreach j of numlist `schedule' {
					local jjj = `j' + 1
					matrix `visit_matrix'[`i', `jjj'] = 1
					local i = `i' + 1
				}

				* These scalars make a matrix
				local tpminus1 = `tpoints' - 1
				
				* Do diagonal first
				forvalues i=1/`tpoints' {
					local v_`i'_`i' = (`var_int')+(`var_res')+(((`i'-1)^2)*(`var_slope'))+ (2*(`i'-1)*`cov_slopeint')
				}
				
				* Then the bottom left corner
				forvalues j=1/`tpminus1' {
					local jplus1 = `j' + 1
					forvalues i=`jplus1' / `tpoints' {
						local v_`i'_`j' = (`var_int') + ( (`j'-1)*(`i'-1)*`var_slope') + ( (`j'-1+`i'-1)*`cov_slopeint' )
					} // i
				} // j
				
				* Now fill in the top right corner by symmetry
				forvalues i=1 / `tpoints' {
					local iplus1 = `i' + 1
					forvalues j=`iplus1' / `tpoints' {
						local v_`i'_`j' = `v_`j'_`i''
					}
				}
				
				* This matrix V is constructed in a loop using the above values
				matrix `V' = J(`tpoints', `tpoints', 0) // create a blank matrix of the right size
				forvalues i=1/`tpoints' {
					forvalues j=1 / `tpoints' {
						matrix `V'[`i', `j'] = `v_`i'_`j''	
					} // i
				} // j

				* Matrix VSTAR
				* Define bottom-left and top-right matrices (COV)
				matrix `COV' = 0*I(`tpoints') // Zeroes everywhere in a square matrix
				
				* Vstar
				matrix `VSTAR'=(`V',`COV' \ `COV',`V')

				* Matrix X
				matrix `X' = J(`tpoints', 2, 1)
				forvalues i=1/`tpoints' {
					matrix `X'[`i', 2] = `i' - 1
				}
					
				* Make dropout matrices: one for each visit (dropping out BEFORE that visit)
				if `drop_yes'==1 {
					* First, make an indicator matrix
					* Start making it the right size, all zeros, then add 1's...
					local j = 1 // row counter = position in schedule numlist
					matrix `DROP`sched1'' = J(1,`tpoints', 0)
					matrix `DROP`sched1''[1,1] = 1
					forvalues i=2/`vvv' {
						local lag = `i' - 1
						matrix `DROP`sched`i''' = `DROP`sched`lag''' \ J(1, `tpoints', 0) // Add one row at a time
						* Get correct column pos'n for the 1
						local ccc = `sched`lag'' + 1
						matrix `DROP`sched`i'''[`i',`ccc'] = 1
					}
					
					* Matrix DROPSTAR
					foreach nnn of numlist `schedule' {
						matrix `DROP`nnn'STAR'=(`DROP`nnn'', 0*`DROP`nnn'' \ 0*`DROP`nnn'',`DROP`nnn'')
					}
				} // End if drop_yes

				* Make matrix DSTAR
				matrix `DSTAR'=(`visit_matrix',0*`visit_matrix' \ 0*`visit_matrix',`visit_matrix')

				* Make matrix XSTAR
				matrix `XSTAR' = J(2*`tpoints', 3, 1) // So the first colum is done - all 1s
				forvalues j=1/`tpoints' { // Top of the second column
					matrix `XSTAR'[`j', 2] = `j' - 1
				}
				local aa = `tpoints' + 1
				local bb = `tpoints' * 2
				forvalues j=`aa'/`bb' { // Bottom half of second column
					matrix `XSTAR'[`j', 2] = `j' - 1 - `tpoints'
				}
				forvalues j=1/`tpoints' { // Top of the third column
					matrix `XSTAR'[`j', 3] = 0
				}
				forvalues j=`aa'/`bb' { // Bottom half of third column
					matrix `XSTAR'[`j', 3] = `j' - `tpoints' - 1
				}

				* Matrices FDROPiSTAR
				if `drop_yes'==1 {
					foreach nnn of numlist `schedule' {
						if `nnn'==`sched1' continue
						tempname FDROP`nnn'STAR
						matrix `FDROP`nnn'STAR' = inv((`DROP`nnn'STAR'*`XSTAR')' * ///
										inv(`DROP`nnn'STAR'*`VSTAR'*`DROP`nnn'STAR'') * ///
										`DROP`nnn'STAR'*`XSTAR')
					}
				} //end if drop_yes


				* Matrix FSTAR
				matrix `FSTAR' = inv((`DSTAR'*`XSTAR')'* /// That last ' is for "matrix transpose"
									inv(`DSTAR'*`VSTAR'*`DSTAR'')* ///
									`DSTAR'*`XSTAR')
*/
									
			} // End of quietly
			


			* KM: Version 2  - creating matrices that are identical to above but are named using visit 1, 2, 3... rather than schedule numbers
			tempname V2 VSTAR2 X2 DSTAR2 XSTAR2 F1STAR2 FSTAR2 visit_matrix2 COV2
			tempname G R SIGMA ONES TIMES Z
			local tpoints2: word count `schedule'
			forval i = 1/`tpoints2' {
				tempname DROP`i'_2 DROP`i'STAR2 DROP2
			}
			
			* want a matrix for G, R, Sigma
			matrix `G' = (`var_int', `cov_slopeint' \ `cov_slopeint', `var_slope')
			local tpoints2 = `tpoints2' + 1 // add 1 for baseline visit 
			matrix `R' = `var_res'*I(`tpoints2')
			matrix `ONES' = J(`tpoints2', 1, 1)
			matrix `TIMES' = J(`tpoints2', 1, 0)
			local j = 1
			foreach i of numlist `schedule' {
				local j = `j' + 1
				matrix `TIMES'[`j', 1] = `i'
			}
			matrix `Z' = `ONES', `TIMES'
			matrix `SIGMA' = `Z'*`G'*`Z'' + `R'

			* Matrix VSTAR - SIGMA for 2 people
			* Vstar
			matrix `VSTAR2'=(`SIGMA', 0*`SIGMA' \ 0*`SIGMA',`SIGMA')

			
			* Make dropout matrices: one for each visit (dropping out BEFORE that visit)
			if `drop_yes'==1 {
				* First, make an indicator matrix
				* Start making it the right size, all zeros, then add 1's...
				local j = 1 // row counter = position in schedule numlist
				matrix `DROP1_2' = J(1,`tpoints2', 0)
				matrix `DROP1_2'[1,1] = 1
				forvalues i=2/`vvv' {
					local lag = `i' - 1
					matrix `DROP`i'_2' = `DROP`lag'_2' \ J(1, `tpoints2', 0) // Add one row at a time	
					* Get correct column pos'n for the 1
					local ccc = `lag' + 1
					matrix `DROP`i'_2'[`i',`ccc'] = 1
				}
				* Matrix DROPSTAR
				forvalues nnn=1/`vvv' {
					matrix `DROP`nnn'STAR2'=(`DROP`nnn'_2', 0*`DROP`nnn'_2' \ 0*`DROP`nnn'_2', `DROP`nnn'_2')
				}
			} // End if drop_yes
			* Make matrix XSTAR
			matrix `XSTAR2' = (`ONES', `TIMES', 0*`ONES' \ `ONES', `TIMES', `TIMES')

			* Matrices FDROPiSTAR - need to do this bit
			if `drop_yes'==1 {
				local j = 0
				foreach nnn of numlist `schedule' {
					local j = `j'+1
					if `nnn'==`sched1' continue
					tempname FDROP`j'STAR2
					matrix `FDROP`j'STAR2' = inv((`DROP`j'STAR2'*`XSTAR2')' * ///
									  inv(`DROP`j'STAR2'*`VSTAR2'*`DROP`j'STAR2'') * ///
									  `DROP`j'STAR2'*`XSTAR2')
				}
			} //end if drop_yes

			* Matrix FSTAR
			matrix `FSTAR2' = inv((`XSTAR2')' * inv(`VSTAR2') * `XSTAR2')



			*************************************
			**
			** CALCULATE THE POWER / SAMPLE SIZE
			**
			*************************************
			* quietly 
			{
				tempname es_slope var1 sampfactor alpha_tail sampsize sampsize_arm power z_power
				
				** Original version if specifying EFFectiveness
			
				if "`effectiveness'"!=""		{	
				
					/*
					* Slope
					scalar `es_slope'=`controlslope_sc'  // NOTE NAME CHANGE OF RECEIVED SCALAR FROM ORIGINAL SLOPEPOWER 
					* Main variance and effect size component
					scalar `var1' = `FSTAR'[3,3] // This is var_tte
					local part_effsize =  `es_slope' / sqrt(`var1') // use this to get an N (below)  // THIS IS THE BIT WITH EFFSIZE=CONTROL SLOPE/VARIANCE(INTERACTION)

					* Dropout variances and effect size components
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn' == `sched1' continue
							tempname var_drop_`nnn'
							scalar `var_drop_`nnn'' = `FDROP`nnn'STAR'[3,3]
							local effsize_drop`nnn' = `es_slope' / sqrt(`var_drop_`nnn'')
						} // End for
					} // end if drop_yes

					* Combine all effect size components into one overall effect size
					local eff_bit = `dfrac_complete' * (`part_effsize')^2
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn' == `sched1' continue
							local eff_bit = `eff_bit' + (`dfrac`nnn'' * (`effsize_drop`nnn'')^2)
						}
					} // end if drop_yes

					* Calculate the EFFECT SIZE
					local effsize=sign(`es_slope') * sqrt(`eff_bit')
					
					* CALCULATE THE MAIN RESULT: Either sample size or power
					if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
						scalar `alpha_tail' = 1 - (0.5 * `alpha')
						scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
						scalar `sampsize_arm' = ceil( ( `sampfactor' / (`effsize')^2) / `effectiveness'^2)
						scalar `sampsize' = 2 * `sampsize_arm'
						scalar `power' = `given_power' // Transferring the local into the scalar...
					}
					else { // Calc POWER
						// Calc the power here
						scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
						scalar `sampsize_arm' = `actual_n' / 2
						scalar `z_power' = ( abs(`effsize')*`effectiveness'*sqrt(`actual_n'/2) ) - invnormal(1-`alpha'/2) // So effect size only comes in here (or line 679) once combined weighted effsize calculated. Makes it hard to just calculate power for interaction term only where 'control' slope is irrelevant. Not sure how to proceed...
						scalar `power' = normal(`z_power')
					}
					*/					
				
									
					* KM: Repeat using version 2 matrices 
					* Slope
					scalar `es_slope'=`controlslope_sc'  // NOTE NAME CHANGE OF RECEIVED SCALAR FROM ORIGINAL SLOPEPOWER 
					* Main variance and effect size component
					scalar `var1' = `FSTAR2'[3,3] // This is var_tte
					local part_effsize =  `es_slope' / sqrt(`var1') // use this to get an N (below)  // THIS IS THE BIT WITH EFFSIZE=CONTROL SLOPE/VARIANCE(INTERACTION)

					* Dropout variances and effect size components
					if `drop_yes'==1 {
						local j = 0
						foreach nnn of numlist `schedule' {
							local j = `j' + 1
							if `nnn' == `sched1' continue
							tempname var_drop_`j'
							scalar `var_drop_`j'' = `FDROP`j'STAR2'[3,3]
							local effsize_drop`j' = `es_slope' / sqrt(`var_drop_`j'')
						} // End for
					} // end if drop_yes

					* Combine all effect size components into one overall effect size
					local eff_bit = `dfrac_complete' * (`part_effsize')^2
					if `drop_yes'==1 {
						local j = 0
						foreach nnn of numlist `schedule' {
							local j = `j' + 1
							if `nnn' == `sched1' continue
							local eff_bit = `eff_bit' + (`dfrac2_`j'' * (`effsize_drop`j'')^2)
						}
					} // end if drop_yes

					* Calculate the EFFECT SIZE
					local effsize=sign(`es_slope') * sqrt(`eff_bit')
				
					* CALCULATE THE MAIN RESULT: Either sample size or power
					if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
						scalar `alpha_tail' = 1 - (0.5 * `alpha')
						scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
						scalar `sampsize_arm' = ceil( ( `sampfactor' / (`effsize')^2) / `effectiveness'^2)
						scalar `sampsize' = 2 * `sampsize_arm'
						scalar `power' = `given_power' // Transferring the local into the scalar...
					}
					else { // Calc POWER
							// Calc the power here
						scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
						scalar `sampsize_arm' = `actual_n' / 2
						scalar `z_power' = ( abs(`effsize')*`effectiveness'*sqrt(`actual_n'/2) ) - invnormal(1-`alpha'/2) // So effect size only comes in here (or line 679) once combined weighted effsize calculated. Makes it hard to just calculate power for interaction term only where 'control' slope is irrelevant. Not sure how to proceed...
						scalar `power' = normal(`z_power')
					}

				
				}  // end of 'effectiveness' version


				
				** New version if specifying difference (thought it would be easiest just to redo this section is DIFFerence specified)
			
				if "`difference'"!=""		{	
/*
					* Slope
					scalar `es_slope'=`difference_sc'  
						
					* Main variance and effect size component
					scalar `var1' = `FSTAR'[3,3] // This is var_tte
					local part_effsize =  `es_slope' / sqrt(`var1') // use this to get an N (below)  // THIS IS THE BIT WITH EFFSIZE=CONTROL SLOPE/VARIANCE(INTERACTION)

					* Dropout variances and effect size components
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn' == `sched1' continue
							tempname var_drop_`nnn'
							scalar `var_drop_`nnn'' = `FDROP`nnn'STAR'[3,3]
							local effsize_drop`nnn' = `es_slope' / sqrt(`var_drop_`nnn'')
						} // End for
					} // end if drop_yes

					* Combine all effect size components into one overall effect size
					local eff_bit = `dfrac_complete' * (`part_effsize')^2
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn' == `sched1' continue
							local eff_bit = `eff_bit' + (`dfrac`nnn'' * (`effsize_drop`nnn'')^2)
						}
					} // end if drop_yes

					* Calculate the EFFECT SIZE
					local effsize=sign(`es_slope') * sqrt(`eff_bit')
					
					* CALCULATE THE MAIN RESULT: Either sample size or power
					if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
						scalar `alpha_tail' = 1 - (0.5 * `alpha')
						scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
						scalar `sampsize_arm' = ceil( ( `sampfactor' / (`effsize')^2) )
						scalar `sampsize' = 2 * `sampsize_arm'
						scalar `power' = `given_power' // Transferring the local into the scalar...
					}
					else { // Calc POWER
							// Calc the power here
						scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
						scalar `sampsize_arm' = `actual_n' / 2
						scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/2) ) - invnormal(1-`alpha'/2) // 
						scalar `power' = normal(`z_power')
					}
*/
					
					
					* KM: Repeat using version 2 matrices
					* Slope
					scalar `es_slope'=`difference_sc'  
						
					* Main variance and effect size component
					scalar `var1' = `FSTAR2'[3,3] // This is var_tte
					local part_effsize =  `es_slope' / sqrt(`var1') // use this to get an N (below)  // THIS IS THE BIT WITH EFFSIZE=CONTROL SLOPE/VARIANCE(INTERACTION)

					* Dropout variances and effect size components
					if `drop_yes'==1 {
						local j = 0
						foreach nnn of numlist `schedule' {
							local j = `j' + 1
							if `nnn' == `sched1' continue
							tempname var_drop_`j'
							scalar `var_drop_`j'' = `FDROP`j'STAR2'[3,3]
							local effsize_drop`j' = `es_slope' / sqrt(`var_drop_`j'')
						} // End for
					} // end if drop_yes

					* Combine all effect size components into one overall effect size
					local eff_bit = `dfrac_complete' * (`part_effsize')^2
					if `drop_yes'==1 {
						local j = 0
						foreach nnn of numlist `schedule' {
							local j = `j' + 1
							if `nnn' == `sched1' continue
							local eff_bit = `eff_bit' + (`dfrac2_`j'' * (`effsize_drop`j'')^2)
						}
					} // end if drop_yes

					* Calculate the EFFECT SIZE
					local effsize=sign(`es_slope') * sqrt(`eff_bit')
					
					* CALCULATE THE MAIN RESULT: Either sample size or power
					if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
						scalar `alpha_tail' = 1 - (0.5 * `alpha')
						scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
						scalar `sampsize_arm' = ceil( ( `sampfactor' / (`effsize')^2) )
						scalar `sampsize' = 2 * `sampsize_arm'
						scalar `power' = `given_power' // Transferring the local into the scalar...
					}
					else { // Calc POWER
							// Calc the power here
						scalar `sampsize' = `actual_n' // As specified by the user; transferring to output scalar
						scalar `sampsize_arm' = `actual_n' / 2
						scalar `z_power' = ( abs(`effsize')*sqrt(`actual_n'/2) ) - invnormal(1-`alpha'/2) // 
						scalar `power' = normal(`z_power')
					}

				}  // end of 'difference' version
					

			} // close quietly
			

			
			
			
			
			*************************************
			**
			** OUTPUT SECTION
			**
			**
			*************************************
			quietly { 
				tempname RESULTS
				mat `RESULTS' = J(1, 9 ,.)
				mat colnames `RESULTS' = alpha power N N1 N2 effectiveness tte var_tte ///
											mean_cont_slope 
				mat `RESULTS'[1,1] = `alpha'
				mat `RESULTS'[1,2] = `power'
				mat `RESULTS'[1,3] = `sampsize'
				mat `RESULTS'[1,4] = `sampsize_arm'
				mat `RESULTS'[1,5] = `sampsize_arm'
				if "`effectiveness'"!="" {
					mat `RESULTS'[1,6] = `effectiveness'
				}
				if "`difference'"!="" {
					mat `RESULTS'[1,6] = .
				}
					
				mat `RESULTS'[1,7] = `tte'
				mat `RESULTS'[1,8] = `var1'
				if `drop_yes'==1 {
					mat `RESULTS'[1,8] = `sampsize_arm' * (`tte')^2 / (invnormal(1-`alpha'/2)+invnormal(`power'))^2
				}
				if "`effectiveness'"!="" {
					mat `RESULTS'[1,9] = `mean_cont_slope'
				}
				if "`difference'"!="" {
					mat `RESULTS'[1,9] = .
				}
					
				return matrix table = `RESULTS'
			}

			

					
			**
			** return values
			if "`effectiveness'"!="" {
				return scalar mean_cont_slope = `mean_cont_slope'
			}
			if "`difference'"!="" {
				return scalar mean_cont_slope =.
				local mean_cont_slope =.
			}
							
			if `drop_yes'==1 {
				return scalar var_tte = `sampsize_arm' * (`tte')^2 / (invnormal(1-`alpha'/2)+invnormal(`power'))^2 // if there is dropout get tte variance by inverting sample size formula
			}
			else {
				return scalar var_tte = `var1'
			}
			return scalar tte = `tte' 
			if "`effectiveness'"!="" {
				return scalar effectiveness = `effectiveness'
			}
			if "`difference'"!="" {
				return scalar effectiveness =.
				local effectiveness=.
			}
							
			return scalar sampsize = `sampsize'
			return scalar fupvisits = `vvv'
			return scalar power = `power'
			return scalar alpha = `alpha'
							

			** ** ** ** ** ** ** **
			**
			** on-screen text


			if "`power_or_n'"=="power" { // Power is given, so we're calculating SAMPLE SIZE
				display as text "                                               alpha = " as ////
																	result %5.3f round(`alpha', 0.001)
				display as text "                                               power = " as ///
																	result %5.3f round(`power', 0.001)
																		
				if "`difference'"=="" {													
					display as text "                           mean slope of control arm = " as ///
																	result %5.3f ///
																	round(`mean_cont_slope', 0.001)
							
					display as text "                                       effectiveness = " as ///
																	result %5.3f ///
																	round(`effectiveness', 0.001)
				}
				
				display as text "               target treatment difference in slopes = " as ///
																	result %5.3f round(`tte', 0.001)
																		
				display as text "                          number of follow-up visits = " as ///
																	result `vvv'
				
				if "`dropouts'" == "" & "`strecruitment'" == "" {
					display as text "                                            schedule = " as ///
																	result "`sched_string'"
				}
				else {
					display as text "schedule (fraction whose f/u ends at previous visit) = " as ///
																	result "`sched_string'"
					display as text "              schedule (fraction remaining in trial) = " as ///
																	result "`sched_string2'"		
				}
				
				display as text "                                               scale = " as ///
																	result `scale'
				
				display as text _n "  Estimated sample size:"
				display as text "                                                   N = " as ///
																	result `sampsize'
				display as text "                                           N per arm = " as ///
																	result `sampsize_arm'
			}
			else { // we're calculating POWER
				display as text "                                               alpha = " as ///
																	result %5.3f round(`alpha', 0.001)
				display as text "                                         specified N = " as ///
																	result `given_n'
				display as text "                                            actual N = " as ///
																	result `actual_n'
				display as text "                                           N per arm = " as ///
																	result `actual_n' / 2
				
				if "`difference'"=="" {
					display as text "                           mean slope of control arm = " as ///
																	result %5.3f ///
																	round(`mean_cont_slope', 0.001)							
					display as text "                                       effectiveness = " as ///
																	result %5.3f ///
																	round(`effectiveness', 0.001)
				}
				
				display as text "               target treatment difference in slopes = " as ///
																	result %5.3f round(`tte', 0.001)
																		
				display as text "                          number of follow-up visits = " as ///
																	result `vvv'
						
				if "`dropouts'" == "" & "`strecruitment'" == "" {
					display as text "                                            schedule = " as ///
																	result "`sched_string'"
				}
				else {
					display as text "schedule (fraction whose f/u ends at previous visit) = " as ///
																	result "`sched_string'"
					display as text "              schedule (fraction remaining in trial) = " as ///
																	result "`sched_string2'"		
				}
																		
				display as text "                                               scale = " as ///
																	result `scale'
				
				display as text "Estimated power:"
				display as text "                                               power = " as ///
																	result %5.3f round(`power', 0.001)
			}
			




			* FINAL STEP - RESTORE THE DATA BACK TO HOW WE FOUND IT
			restore

end
