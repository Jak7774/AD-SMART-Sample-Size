* -------------------------------------------------------
*  Power Calculation for Slope Difference
*	for each primary outcome
* -------------------------------------------------------


* -------------------------------------
* ADAS-COG
* -------------------------------------

*stage 1:
slopepoweri, schedule(0.5 1 1.5) difference(1.5)  alpha(0.8) covariance(66.46747, 20.39907\ 20.39907, 24.69075) errorvar(12.10415) dropout(0.05 0.05 0.05) n(480) strec(0.27777778 0.27777778 0.24027778)
*94.3%
local n = r(sampsize)/2
local var = r(var_tte)
local z_alphaover2 = 1-(r(alpha)/2)
di invnorm(`z_alphaover2')*sqrt(`var')/sqrt(`n')
*critical value = 0.21

*stage 2:
slopepoweri, schedule(0.5 1 1.5) difference(1.5)  alpha(0.6) covariance(66.46747, 20.39907\ 20.39907, 24.69075) errorvar(12.10415) dropout(0.05 0.05 0.05) n(734) strec( 0.1818182 0.1818182 0.1818182)
*98.5%
local n = r(sampsize)/2
local var = r(var_tte)
local z_alphaover2 = 1-(r(alpha)/2)
di invnorm(`z_alphaover2')*sqrt(`var')/sqrt(`n')
*critical value = 0.29

*stage 3:
*using no levelling off program:
slopepoweri, schedule(0.5 1 1.5) difference(1.5)  alpha(0.025) covariance(66.46747, 20.39907\ 20.39907, 24.69075) errorvar(12.10415) dropout(0.05 0.05 0.05) n(934) strec(0.14285714 0.14285714 0.14285714)
*83.8%

local n = r(sampsize)/2
local var = r(var_tte)
local z_alphaover2 = 1-(r(alpha)/2)
di invnorm(`z_alphaover2')*sqrt(`var')/sqrt(`n')


* -------------------------------------
* A-IADL-Q
* -------------------------------------

*stage 1:
slopepoweri, schedule(0.5 1 1.5) difference(4)  alpha(0.8) covariance(409.2529, 36.041768 \ 36.041768, 109.8304) errorvar(127.4641) dropout(0.05 0.05 0.05) n(480) strec(0.27777778 0.27777778 0.24027778 )
*94.3%
local n = r(sampsize)/2
local var = r(var_tte)
local z_alphaover2 = 1-(r(alpha)/2)
di invnorm(`z_alphaover2')*sqrt(`var')/sqrt(`n')
*critical value = 0.55

*stage 2:
slopepoweri, schedule(0.5 1 1.5) difference(4)  alpha(0.6) covariance(409.2529, 36.041768 \ 36.041768, 109.8304) errorvar(127.4641) dropout(0.05 0.05 0.05) n(734) strec(0.1818182 0.1818182 0.1818182)
*98.7%
local n = r(sampsize)/2
local var = r(var_tte)
local z_alphaover2 = 1-(r(alpha)/2)
di invnorm(`z_alphaover2')*sqrt(`var')/sqrt(`n')
*critical value = 0.76

*stage 3:
*using no levelling off program:
slopepoweri, schedule(0.5 1 1.5) difference(4)  alpha(0.025) covariance(409.2529, 36.041768 \ 36.041768, 109.8304) errorvar(127.4641) dropout(0.05 0.05 0.05) n(934) strec(0.14285714 0.14285714 0.14285714)
*85.9% power
