{smcl}
{* *! version 2.1)}
{hline}
{cmd:help slopepoweri}{right: ({})}
{hline}
{vieweralsosee "[R] mixed" "help mixed"}{...}
{viewerjumpto "Syntax" "slopepoweri##syntax"}{...}
{viewerjumpto "Menu" "slopepoweri##menu"}{...}
{viewerjumpto "Description" "slopepoweri##description"}{...}
{viewerjumpto "Options" "slopepoweri##options"}{...}
{viewerjumpto "Examples" "slopepoweri##examples"}{...}
{viewerjumpto "Stored results" "slopepoweri##results"}{...}
{viewerjumpto "Authors" "slopepoweri##authors"}{...}

{title:Title}
{p2colset 5 20 20 2}{...}
{p2col :{hi:slopepoweri} {hline 2}}"Immediate" sample size and power calculator for
outcomes analysed using a slope (ie repeated measures across multiple timepoints). {cmd: slopepoweri} is a
modification to the original {cmd: slopepower} command, allowing users to input their random effect
and error variance estimates directly into the command line rather than fit a mixed model to
data in memory within the command to obtain estimates. 

{p2col : }Additional modifications also give the
option for the user to specify the slope (treatment) effect as the absolute difference per unit time in addition to 
specification as a proportional change, and to also adjust for the impact of staggered recruitment in a trial when 
analysing available
 data at a fixed point in calendar time. This could be done using the {opt drop:outs} option in {cmd: slopepower}, but 
{cmd: slopepoweri}
 allows for both factors to be simultaneously accounted for. Users can also specify the schedule list in decimal time directly in the {opt sched:ule} option, instead of {cmd: slopepower}'s requirement of integer time values combined with the {opt sca:le} option.
{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:slopepoweri}
        {cmd:,}
        {opth sched:ule(numlist)}
        [{it:{help slopepower##options_table:options}}]


{synoptset 29 tabbed}{...}
{marker options}
{marker options_table}{...}
{synopthdr}
{synoptline}

{p2coldent :* {opth sched:ule(numlist)}}the visit times for the proposed study. 
Visit times must be integer values. Use scale option to allow for fractional time{p_end}
{synopt :{opth drop:outs(numlist)}}the proportion of dropouts at each visit. 
Length must correspond to the schedule list{p_end}
{synopt :{opth strec:ruitment(numlist)}}the proportion who have (currently) only reached the previous visit. Length must correspond to the schedule number list {p_end}
{synopt :{opt sca:le(#)}}the ratio of the timescale used for the variance parameter esimtates and the timescale for the schedule number list; default is 1{p_end}
{synopt :{opt a:lpha(#)}}significance level; default is 0.05{p_end}
{synopt :{opt pow:er(#)}}power; default is 0.8, required to compute sample size{p_end}
{synopt :{opt n(#)}}total sample size; required to compute power{p_end}
{synopt :{opt eff:ectiveness(#)}}the hypothesised effectiveness of the treatment in proportionate terms relative to control group slope{p_end}
{synopt :{opth cont:rolslope(#|varname)}}the mean control group slope that the effectiveness option is relative to, entered as either a number or the name of a variable representing the apppropriate slope from a mixed model in memory{p_end}
{synopt :{opt diff:erence(#)}}alternative specification of the treatment slope effect as the absolute differece per unit time{p_end}
{synopt :{opth cov:ariance(matrix)}}user input of the random effect covariance matrix{p_end}
{synopt :{opt error:var(#)}}user input of the random error variance{p_end}
{synopt :{opt mixed}}alternative specification of variance parameters that provides automatic input of variance estimates from a suitable mixed model in memory{p_end}

{synoptline}
{pstd}*this option is required.
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:slopepoweri} performs a sample size or power calculation directly from user-supplied values for a proposed two-arm
randomised clinical trial (RCT) based on a linear mixed model, where the outcome of interest is a slope 
measured over time and the hypothesised treatment effect is a change to the slope of the control group but with a common
 intercept i.e. a proportionate change of the slope. As with the original {cmd:slopepower} command, this effect can be 
specified by that proportion relative to the mean control slope (required). New for {cmd: slopepoweri} the effect can also be 
specified by the absolute difference per unit time,
corresponding to the slope#time interaction term estimate in a linear model. For the latter specification, input of a 
control slope is not required. It allows calculation of power or sample size for the situation when either the control slope 
is zero (flat) or when the control slope is positive (negative) and the treatment slope is negative (positive). 

{pstd}
The variance parameters may be supplied either as a matrix (random effects) and number (error) by the user or by using 
the mixed option which will utilise the variance estimates from a suitable mixed model in memory. In addition to adjusting 
for dropout {cmd:slopepoweri} can also account for the impact of staggered recruitment, where at a given point in calendar time  
cohorts of participants grouped by their start of study date will have only reached a certain  measurement point (visit) in the 
schedule. The mathematical adjustment for either factor is essentially identical but the integrated impact of both 
factors can be obtained by using both options.

{marker options}{...}
{title:Options}

{dlgtab:Required option}

{phang}
{opth sched:ule(numlist)} specifies the visit times for the proposed trial. A baseline
 visit at time 0 is assumed; this list should describe subsequent visits, in 
 whole number units of time. Additionally use the scale option if you wish to specify visit times in decimal units.
 
{dlgtab:Other options} 

{phang}
{opt eff:ectiveness(#)}  specify the effect size you would like 
to be able to detect in the trial. {opt eff:ectiveness} indicates this effect size as
a proportional change to the mean slope of the control group. Hence one must also specify
{opt cont:rolslope}, the control group slope. Alternatively, just use {opt diff:erence}.

{phang}
{opth cont:rolslope(#|varname)} this option is to be used in conjunction with {opt eff:ectiveness} and represents the slope 
of the control group that the treatment group is proportionate to by a factor of {opt eff:ectiveness(#)}. Enter either a 
number representing the value of the slope or the {varname} of the slope term from a mixed model in memory to transfer that parameter estimate to the calculations. Alternatively, just use {opt diff:erence}.

{phang}
{opt diff:erence(#)} this option is an alternative specification of the treatment effect and is the absolute difference between treatment and control group slopes per unit time. This option obviates the need for {opt cont:rolslope}.

{phang}
{opt sca:le(#)} use this option if you wish to specify visit times in a different scale to that used for the variance parameters. 
For example, if your variance parameter estimates came from a model where time was specified in years, but you wished to calculate power for a trial that had a visit schedule specified in months you could use {opt sca:le(`=1/12')}.
 
{phang} 
{opth cov:ariance(matrix)} the covariance matrix of the random effects. Enter as a 2x2 symmetrical matrix with the random 
intercept variance in the top left position and the random slope variance in the bottom right position. You may either 
first define a matrix (for example {cmd: matrix} G=(3,1\1,8)) and then insert the matrix name within the option (for 
example {opt cov:ariance(G)}) or instead define the matrix within the option (for example {opt cov:ariance(3,1\1,8)}). 
Inputting 0 for the off-diagonal terms allows the user to specify a random effects model with independent random 
intercepts and slopes, which may not be a sensible choice. See option {opt mixed} for a shortcut to using {opt cov:ariance} and {opt err:orvar}.

{phang}
{opt err:orvar(#)} the error variance term. See option {opt mixed} for a shortcut to using {opt cov:ariance} and
{opt err:orvar}.

{phang}
{opt mixed} use of this option will automatically transfer the random effect and error variance values from a suitable 
mixed model in memory, and is an alternative to using using {opt cov:ariance} and {opt err:orvar}. It is the user's 
responsibility to ensure the model is 'suitable'. Specifically, {cmd: slopepoweri}, {opt mixed} looks for the parameter 
names _b[lns1_1_1:_cons], _b[lns1_1_2:_cons], _b[atr1_1_1_2:_cons] and _b[lnsig_e:_cons] amongst the returned estimates 
from the mixed model. {opt mixed} will accept the returned values from a mixed model with no covariance term between random 
effects (and input a zero value for the covariance), though this may not be a sensible model specification. 

{phang}
{opt a:lpha(#)} sets the significance level (also known as Type I error rate) 
to be used in the planned study. The default is alpha(0.05).

{phang}
{opt pow:er(#)} sets the power for the planned study. The default is power(0.8).
This option is required to compute the sample size.

{phang}
{opt n(#)} specifies the total number of participants who will be in the trial. Note if you are using the
 {opt strec:ruitment} option then be aware that this number is the total number who have been randomised so far
 - not the ultimate planned study total. If an odd number is given, (n-1) will be used to allow equal numbers per arm.
Only one of {opt pow:er} and {opt n} may be specified. This option is required to compute the power.

{phang}
{opth drop:outs(numlist)} specifies the estimated proportion of dropouts you 
expect at each study visit. It must correspond exactly to the schedule list. 
Each number in the list is a proportion between 0 and 1; this is the fraction of
subjects (of those who start the study - not of those who made the previous visit) you estimate will fail to attend that 
visit. We follow the pattern mixture method of Dawson and Lagakos.

{phang}
{opth strec:ruitment(numlist)} specifies the proportion who have only reached as far as the prior visit due to the effect of a staggered recruitment to the trial. It must correspond exactly to the schedule list. Each number in the list is a 
 proportion between 0 and 1 and must sum to less than  or equal to 1. If the sum  is less than 1 then the remainder is the proportion who have only had a baseline measure so far. Note, baseline measurements provide no statistical information
 concerning the treatment effect. If 
 both {opt strec:ruitment} and {opt drop:outs} are specified then the integrated cohort proportions (weights) are returned in the output.

{marker examples}{...}
{title:Examples}
    {hline}

{pstd}
Initially use {cmd: slopepower} as a point of comparison. Load example observational data with no healthy controls (slpower1.dta, available as an ancillary file with {cmd: slopepower}): 
{p_end}

{pmore}{bf:{stata `". use slpower1, clear"'}}{p_end}

{pstd} 
Use {cmd: slopepower} to give the sample size for an RCT with annual visits over four years, assuming no dropouts, with 
80% power to detect a treatment effect that will eliminate one-third of the slope in the outcome sdmt. See helpfile for 
{help slopepower} (if installed). Assume there is a dropout rate (out of the full sample) of 5% at the year 1 visit, another 5% at the year 2 visit, 20% at the year 3 visit and 30% dropout before the final visit. The default value of 5% Type I error rate is used.{p_end}

{pmore}{bf:{stata `". slopepower sdmt, schedule(1 2 3 4) subject(id) time(visit) obs nocontrol eff(0.33) dropouts(0.05 0.05 0.2 0.3) n(500)"'}}{p_end}


{pstd} 
Demonstrate that {cmd: slopepower} quietly fits a mixed model by replaying the results and inspecting those variance parameter estimates.{p_end}

{pmore}{bf:{stata `". mixed"'}} {p_end}

{pstd} 
Reproduce the results of {cmd: slopepower} using {cmd: slopepoweri} by inputting those variance estimates plus the control slope estimate in the command line .{p_end}

{pmore}{bf:{stata `". slopepoweri, schedule(1 2 3 4)  effectiveness(0.33) controlslope(-1.6725) covariance(111.7867, 2.81074\2.81074, 2.350055) errorvar(9.159749)  n(500) dropout(0.05 0.05 0.2 0.3)"'}} {p_end}


{pstd}
Alternate version where the covariance matrix is first defined, and then named in the {opt cov:ariance} option : 
{p_end}

{pmore}{bf:{stata `". mat def covRE=(111.7867, 2.81074\2.81074, 2.350055)"'}}{p_end}
{pmore}{bf:{stata `". slopepoweri, schedule(1 2 3 4)  effectiveness(0.33) controlslope(-1.6725) covariance( covRE) errorvar(9.159749)  n(500) dropout(0.05 0.05 0.2 0.3)"'}} 
{p_end}

{pstd} 
Alternate version where the variance estimates are supplied from the mixed model in memory (fitted by the first
 {cmd: slopepower} command) by just using {opt mixed} option, and the control slope is entered by naming the slope variable 
 from the mixed model in the {opt cont:rolslope} option . {p_end}

{pmore}{bf:{stata `". slopepoweri, schedule(1 2 3 4)  effectiveness(0.33) controlslope(visit) mixed  n(500) dropout(0.05 0.05 0.2 0.3)"'}} 
{p_end}

{pstd} 
Produce same result using just the {opt diff:erence} option instead {opt eff:ectiveness} plus {opt cont:rolslope}. {p_end}

{pmore}{bf:{stata `". slopepoweri, schedule(1 2 3 4)  difference(0.552) mixed  n(500) dropout(0.05 0.05 0.2 0.3)"'}} {p_end}


{pstd}
Also introduce the effect of staggered recruitment. In this example only 10% have a baseline measurement (so far), 10% only 
have a baseline plus year 1 measurement, 20% have baseline plus year 1 and year 2, 20% have baseline plus year 1, year 2 and 
year 3 and 40% have all visit measurements - that is, they were randomised sufficiently long ago to have reached the last 
visit. However, this 40% is not explicitly provided in the number list - it is the remainder given the 4 supplied probabilities. Note the integrated cohort weights in the output.
{p_end}

{pmore}{bf:{stata `". slopepoweri, schedule(1 2 3 4)  effectiveness(0.33) controlslope(visit) mixed  n(500) dropout(0.05 0.05 0.2 0.3) strec(0.1 0.1 0.2 0.2)"'}} {p_end}



 {hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:slopepoweri} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 20 4: Scalars}{p_end}
{synopt:{cmd:r(alpha)}}Type I error rate (significance level) of the planned trial{p_end}
{synopt:{cmd:r(power)}}power of the planned trial{p_end}
{synopt:{cmd:r(fupvisits)}}specified number of follow up visits{p_end}
{synopt:{cmd:r(sampsize)}}total sample size{p_end}
{synopt:{cmd:r(effectiveness)}}specified target effectiveness of the proposed treatment (empty if {opt diff:erence} used){p_end}
{synopt:{cmd:r(tte)}}target treatment effect{p_end}
{synopt:{cmd:r(var_tte)}}variance of the target treatment effect for a hypothetical future two-person trial{p_end}
{synopt:{cmd:r(mean_cont_slope)}}the assumed slope of the control group (empty if {opt diff:erence} used) {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}table of results{p_end}

{p2colreset}{...}

{marker references}{...}
{title:References}

{phang}
Chris Frost, Michael G. Kenward, Nick C. Fox. Optimizing the design of clinical 
trials where the outcome is a rate. Can estimating a baseline rate in a run-in 
period increase efficiency? Statist. Med. 2008; 27:3717–3731 doi: 10.1002/sim.3280

{phang}
JD Dawson, SW Lagakos. Analyzing laboratory marker changes in AIDS clinical 
trials. J AIDS 1991;4:667-676 PMID: 2051307

{phang}
Dawson JD, Lagakos SW. Size and power of two-sample tests of repeated measures 
data. Biometrics 1993;49:1022-1032

{marker Authors}{...}
{title:Authors}
Matthew Burnell
MRC Clinical Trials Unit, University College London 
London, UK
m.burnell@ucl.ac.uk
Katy Morgan
London School of Hygiene and Tropical Medicine
London, UK
katy.morgan@lshtm.ac.uk

{marker Authors}{...}
{title:Authors of {cmd:slopepower}}
Stephen Nash, Katy Morgan, Amy Mulick
London School of Hygiene and Tropical Medicine
London, UK

