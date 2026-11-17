# ------------------------------------------------
# Sample Size Estimates for AD-SMART
# - Estimate Recruitment Weight
# - Proportion of Participants at each Stage
# ------------------------------------------------


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
  cat("Max visit timepoint:", 0.5*i, "years", "\n") 
  cat("Total Recruited:", recruit(yr,linrate), "\n")
  plot_recruit(yr, linrate)
  
  cat("Proportion at Each Post-Baseline Timepoint:", recrwgts, "\n")
  cat("Proportion at Baseline:", (1-sum(recrwgts)))
}

# Stages are estimated to occur at:
# Stage 1 = 2.55 years since start
# Stage 2 = 3.5 years since start
# Stage 3 = 4.25 years since start

# For slopepoweri command need recruitment proportions
# So for each Stage Estimate the Proportion of Participants at each TImepoint 

# Stage 1 
weights(2.55, 400/3)

# Stage 2
weights(3.5, 400/3)

# Stage 3
weights(4.25, 400/3)
