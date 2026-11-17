
corr12 <- 0.8
corr23 <- 0.8
corr13 <- 0.6
ntrials <- 10000
power1 <- 0.886
power2 <- 0.965
power3 <- 0.867

my.Sigma<-matrix(c(1, corr12, corr13, corr12, 1 , corr23, corr13, corr23, 1), ncol=3)
W<-mvrnorm(n=ntrials, mu=c(0,0,0), Sigma = matrix(c(1, corr12, corr13, corr12, 1 , corr23, corr13, corr23, 1), ncol=3))

crit1<-qnorm(power1)
crit2<-qnorm(power2)
crit3<-qnorm(power3)

power_stage1<-sum(W[,1]>-crit1)/ntrials
power_stage2<-sum(W[,2]>-crit2 & W[,1]>-crit1)/ntrials
power_stage3<-sum(W[,3]>-crit3 & W[,2]>-crit2 & W[,1]>-crit1)/ntrials
sum(W[,1])
summary(W[,1])
summary(W[,2])
summary(W[,3])


hist(W[,1])
abline(v = -crit1, col = "red", lwd = 2, lty = 2)


# ---------------------------------
# Recruitment Rate @ Analysis Timepoints
# ---------------------------------

# Recruitment Rate (ramp up to Linear after 1.5 years)
recruit<-function(x, linrate){
  if(x>=0){
    linrate/3*(x^2)*(x<1.5)+(linrate*(x-1.5)+linrate/3*1.5^2)*(x>=1.5)
  }else{
    NA
  }
}

# Plot Function to Visualise
plot_recruit<-function(yr,linrate){
  curve(linrate/3*(x^2)*(x<1.5)+(linrate*(x-1.5)+linrate/3*1.5^2)*(x>=1.5), 
        from =0, to=6, ylim=c(0,700),xlab="Trial time (years)", ylab="Cumulative recruitment of participants")
  abline(v=yr, lty=c(2))
  title(paste0("Recruitment plot when aiming for ", `linrate`, " participants per arm in linear recruitment phase"))
}

# Calculate Proportion of Participants at 6, 12, 18 Months
weights<-function(yr,linrate){
  recrwgts<-c()
  i<-0
  while((i+1)*0.5<2){
    recrwgts<-c(recrwgts,(recruit(yr-0.5*i,linrate)-recruit(yr-0.5*(i+1),linrate))/recruit(yr,linrate))
    i<-i+1
  }
  cat("Max visit timepoint:", 0.5*i, "years", "Out of", recruit(yr,linrate))
  plot_recruit(yr, linrate)
  recrwgts<-c(0.5*i, recrwgts)
  recrwgts
}


weights(2.55, 400/3)
weights(3.5, 400/3)
weights(4.25, 400/3)