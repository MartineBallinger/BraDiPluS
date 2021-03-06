#
#  This file is part of the `BraDiPluS` R package
#
#  Copyright (c) 2016 EMBL-EBI
#
#  File author(s): Federica Eduati (federica.eduati@gmail.com)
#
#  Distributed under the GPLv3 License.
#  See accompanying file LICENSE.txt or copy at
#      http://www.gnu.org/licenses/gpl-3.0.html
#
#  Website: https://github.com/saezlab/BraDiPluS
# --------------------------------------------------------
#
#' Remove outlier peaks.
#' 
#' \code{qualityAssessment} removes low quality peaks (i.e. replicates).
#' 
#' This function allows to remove the peaks that are outliers based on the orange channel. Orange dye is added to the cells suspention
#' in order to monitor mixing of reagents in each plug. This function looks at the distribution of the 
#' values of all orange peaks and marks the possible outliers: corresponding peaks are removed from further
#' analysis. It can be done at once for different runs (where we call run a complete cycle of all the samples corresponding
#' to different experimental conditions).
#' 
#' @param runs List with one element for each run. For each run the list elements correspond to the peaks selected for the different
#' samples using \code{\link{selectSamplesPeaks}} (after defining samples with \code{\link{samplesSelection}})
#' @return This function returns a list with the same structure of the one used as input but without the outlier peaks.
#' @seealso \code{\link{samplesSelection}} to define samples, \code{\link{selectSamplesPeaks}} to select peaks for each sample
#' @examples 
#' data(BxPC3_data,package="BraDiPluS")
#' res <- samplesSelection(data=MyData, BCchannel="blue",
#' BCthr=0.01, distThr=300, plotMyData=TRUE)
#' samples <-res$samples
#' 
#' # select the peaks for each sample
#' samplesPeaks <- selectSamplesPeaks(samples, channel="green", metric="median", baseThr=0.01, minLength=350, discartPeaks="first", discartPeaksPerc=5)
#' 
#' # remove outliers based on orange channel
#' runs<-list(run1=samplesPeaks)
#' runs.qa<-qualityAssessment(runs=runs) 
#' @export

qualityAssessment <- function(runs){
  par(mfrow=c(1,length(runs)))
  
  res<-list()
  for (i in 1:length(runs)){
    res[[i]]<-removeOutliers(runs[[i]], i)
  }
  
  return(res)

}


# remove ouliers for each run
removeOutliers <- function(x, index){
  samples.names<-names(x)
  
  allData<-unlist(sapply(x, get, x="orange"))

  bxp<-boxplot(allData, ylab="orange (all replicates, all samples)")
  main<-paste("run", index, ": median=", round(median(allData), 2), ", IQR=", round(IQR(allData), 3))
#   title(main=main, sub=paste("total =", length(allData), "   outliers =", round(length(bxp$out),3)))
  
  lower_outlier<-quantile(allData)[2]-1.5*IQR(allData)
  upper_outlier<-quantile(allData)[4]+1.5*IQR(allData)
  
  # remove outliers from each sample
  x_new<-lapply(x, function(y){
    subset(y, (orange > lower_outlier & orange < upper_outlier))
  })

  # find samples with less then 2 replicates after removing outliers
  nRepl<-sapply(x_new, nrow)
  ixRemove<-which(nRepl<2)
  
  cat("\nrun", index, ":\n")
  cat("Sample(s): ", paste(names(x_new)[ixRemove], sep=","), "have less then 2 replicates and will therefore be removed")

  if (length(ixRemove)>0){
    sub1<-paste("samples removed:", paste(names(x_new)[ixRemove], collapse=","))
  }else{
    sub1<-"samples removed: none"
  }
  
  sub2<-paste("total =", length(allData), "   outliers =", round(length(bxp$out),3))
  title(main=main, sub=paste(sub1, sub2, sep="\n"))
  
  
#   if (length(ixRemove)>0){
#     x_new<-x_new[-ixRemove]
#   }
  
  # instead of removing it, I substitute it with an empty data frame
  for (i in ixRemove){
    x_new[[i]]<-setNames(data.frame(matrix(ncol = ncol(x_new[[i]]), nrow = 0)), colnames(x_new[[i]]))
  }

  return(x_new)
}


