# ------------------------------------------------
# Sample Size Estimates for AD-SMART
# - Overall Power for Each Stage
# ------------------------------------------------

library(expm)
library(condMVNorm)
library(MASS)
library(ggplot2)
library(tidyr)
library(dplyr)
library(pwr)

# ----------------------------------------
# MHRA Updated Power Calculation
# ----------------------------------------

set.seed(123)
actualpower_diffcorrs<-function(corr12, corr23, corr13, ntrials, nperarm=NULL, effectsize=NULL, sd=NULL, power=NULL, alpha=NULL , show){
  
  if(!is.null(sd)){
    sd1<-sd[1]
    sd2<-sd[2]
    sd3<-sd[3]
    alpha1<-alpha[1]
    alpha2<-alpha[2]
    alpha3<-alpha[3]
    
    power1<-pwr.t.test(n=nperarm, d=0.5*effectsize/sd1, sig.level=alpha1, type="two.sample", alternative="greater")$power
    power2<-pwr.t.test(n=nperarm, d=effectsize/sd2, sig.level=alpha2, type="two.sample", alternative="greater")$power
    power3<-pwr.t.test(n=nperarm, d=1.5*effectsize/sd3, sig.level=alpha3, type="two.sample", alternative="greater")$power
  } else{
    power1<-power[1]
    power2<-power[2]
    power3<-power[3]
  }
  
  my.Sigma<-matrix(c(1, corr12, corr13, corr12, 1 , corr23, corr13, corr23, 1), ncol=3)
  W<-mvrnorm(n=ntrials, mu=c(0,0,0), Sigma = matrix(c(1, corr12, corr13, corr12, 1 , corr23, corr13, corr23, 1), ncol=3))
  
  crit1<-qnorm(power1)
  crit2<-qnorm(power2)
  crit3<-qnorm(power3)
  
  power_stage1<-sum(W[,1]>-crit1)/ntrials
  power_stage2<-sum(W[,2]>-crit2 & W[,1]>-crit1)/ntrials
  power_stage3<-sum(W[,3]>-crit3 & W[,2]>-crit2 & W[,1]>-crit1)/ntrials
  
  if(show=="T"){
    cat("Stage powers...", "\n")
    cat("Stage power at stage 1:", power1, "\n")
    cat("Stage power at stage 2:", power2, "\n")
    cat("Stage power at stage 3:", power3, "\n")
    
    cat("\n", "Overall powers...", "\n")
    cat("Power at stage 1:", power_stage1, "\n")
    cat("Power at stage 2:", power_stage2, "\n")
    cat("Power at stage 3:", power_stage3, "\n")
    cat("Given correlations between stagewise estimates are: between stages 1 and 2:", corr12, ", between stages 2 and 3:", corr23, ", between stages 1 and 3:", corr13, "\n \n")
  }
  c(power_stage1, power_stage2, power_stage3)
}

actualpower_diffcorrs(corr12=0.8,corr23=0.8,corr13=0.6, ntrials=1000000, power=c(0.943,0.985,0.838), show="T")
actualpower_diffcorrs(corr12=0.8,corr23=0.8,corr13=0.6, ntrials=1000000, power=c(0.943,0.987,0.859), show="T")
