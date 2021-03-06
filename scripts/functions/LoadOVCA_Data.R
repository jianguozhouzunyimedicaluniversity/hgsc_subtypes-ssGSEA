###############################################
# ssGSEA testing for ovarian cancer
#
# Chang, T
# ~~~~~~~~~~~~
# This scipt loads required HGSC data.
#
# References:
# Way, G.P., Rudd, J., Wang, C., Hamidi, H., Fridley, L.B, Konecny, G., Goode, E., C.S., Doherty, J.A. (2016).
# Unpublished: Cross-population analysis of high-grade serious ovarian cancer does not support four subtypes.
###############################################

############################################
# Load Libraries
############################################
library(curatedOvarianData)
library(plyr)

############################################
# Load Data Function
############################################
LoadOVCA_Data <- function(datasets, goodsample_subset_dir = "data/GoodSamples/", 
                          commongenes_dir = "data/Genes/CommonGenes_genelist.csv",
                          madgenes_dir = "data/Genes/GlobalMAD_genelist.csv",
                          mayo_exprs_file = "data/Mayo/MayoEset.Rda",
                          genelist_subset = "commongenes",
                          shuffle = F) {
  # ~~~~~~~~~~~~~~
  # Loads ovarian cancer data from curatedOvarianData
  #
  # Args: 
  # datasets: a list of datasets to download
  # goodsample_subset_dir: the directory holds .txt files of samples that passed inclusion
  #                        if no sample subsetting is desired, set this argument to "None"
  # commongenes_dir: the file location of the common genes .txt file
  # madgenes_dir: the file location of the mad (median absolute deviation) genes .txt file
  # mayo_exprs_file: the file location of the rdata file from the Mayo Clinic
  # genelist_subset: the genelist to subset each dataset
  # shuffle: determines if the genelists should be shuffled in the final expression matrix
  #
  # Returns:
  # A list object holding the gene expression data for the
  # input datasets
  # ~~~~~~~~~~~~~~
  
  # Get data from the curatedOvarianData package  
  detailedData <- data(package="curatedOvarianData")[3]
  # Get the eset IDs
  detailedData.names <- detailedData$results[ ,3]
  
  # Initialize a list object
  ExpData <- list()
  for (eset_exprs in datasets) {
    if (goodsample_subset_dir != "None") {
      # Get the list of samples to remove
      fileName <- paste(eset_exprs, "_samplesRemoved.csv",sep="")
      goodSamples <- read.csv(file = paste(goodsample_subset_dir, fileName, sep = ""))
      
      # The samples to use in the subset
      goodSamples <- c(paste(goodSamples$x))
    }
    
    # Load the expression data
    dta <- c()
    if (eset_exprs %in% detailedData.names) {
      # Load the data
      cat("Loading", eset_exprs, "...\n")
      data(list = eset_exprs, package = "curatedOvarianData")
      ExpressionData <- get(eset_exprs)
      dta <- exprs(ExpressionData)
      # Mayo data is not in curatedOvarianData
    } else if (grepl("Mayo", eset_exprs)) {
      cat("Loading", eset_exprs, "from file...\n")
      dta <- get(load(mayo_exprs_file))
      dta <- exprs(dta)
    } else {
      stop("Dataset does not exist in curatedOvarianData")
    }
    
    # Determine user defined method of subseting genes
    if (genelist_subset == "commongenes") {
      subset <- read.csv(commongenes_dir, header = T, stringsAsFactors = F)
    } else if (genelist_subset == "madgenes") {
      subset <- read.csv(madgenes_dir, header = T, stringsAsFactors = F)
    } else if (genelist_subset != "None") {
      # Raise an error
      stop("Set genelist_subset to 'commongenes', 'madgenes', or 'None'")
    }
    
    # Assign the list elements according to the subset of choice
    if (goodsample_subset_dir != "None" & genelist_subset != "None") {
      ExpData[[eset_exprs]] <- dta[subset[ ,1], goodSamples]
    } else if (goodsample_subset_dir == "None" & genelist_subset != "None") {
      ExpData[[eset_exprs]] <- dta[subset[ ,1], ]
    } else {
      ExpData[[eset_exprs]] <- dta[ ,goodSamples]
    }
    
    if (shuffle) {
      for (gene in 1:nrow(ExpData[[eset_exprs]])) {
        random_vec <- sample(ExpData[[eset_exprs]][gene, ], ncol(ExpData[[eset_exprs]]))
        ExpData[[eset_exprs]][gene, ] <- random_vec
      }
    }
    
  }
  #Return a list of subsetted gene expression data.frames for all input datasets
  return(ExpData)
}
