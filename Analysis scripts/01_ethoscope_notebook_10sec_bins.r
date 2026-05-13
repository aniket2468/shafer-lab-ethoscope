rm(list=ls())

df <- read.delim("/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/all_ethoscopes_merged_04MAY.txt", header = T)

datSortBin <- function (input, n.days, cat.names = c("Control", "Experimental"), ethoscope.id, mins.trim) {
  library(stringr)
  
  dat <- list()
  
  for.df <- list()
  
  for (i in 1:length(ethoscope.id)) {
  txt <- paste(ethoscope.id[i], sep = "")
  for.df[[i]] <- input[str_detect(string = input$id, pattern = txt, negate = FALSE),]
}
  
  for (i in 1:length(for.df)) {
    df <- for.df[[i]]
    
    t = as.data.frame(table(df$id))
    tt = subset(t, Freq != 0)
    etho.names <- as.vector(tt[,1])
    
    n.time = n.days*((24*60*60)/10)
    # output.bin = 10/60
    
    ethoscope <- list()
    
    for (j in 1:length(etho.names)) {
      ethoscope[[j]] <- subset(df, id == etho.names[j], select = c("t","max_velocity"))
    }
    
    
    dat.etho <- matrix(NA, nrow = 1440*6*(n.days+10), ncol = length(ethoscope))
        
    for (ii in 1:length(ethoscope)) {
        rows_to_trim <- mins.trim[i] * 6   # i = current ethoscope index (outer loop)
        if (rows_to_trim >= nrow(ethoscope[[ii]])) {
            warning(paste("Skipping individual", ii, "- not enough data after trimming"))
            next
        }
        trimmed.dat <- ethoscope[[ii]][-c(1:rows_to_trim),]
        dat.etho[1:nrow(trimmed.dat), ii] <- trimmed.dat[,"max_velocity"]
    }
    
    eth.names <- strsplit(etho.names, split = "|", fixed = T)
  
  col.names.etho <- c()
  for (kk in 1:length(dat.etho[1,])) {
    col.names.etho[kk] <- paste("Ind", eth.names[[kk]][2], sep = "")
  }
  
  colnames(dat.etho) <- col.names.etho
  
  out.time <- as.matrix(seq(10, (length(dat.etho[,1])*10), by = 10))
  colnames(out.time) <- c("Time since start (sec)")
    
  dat[[i]] <- cbind(out.time, dat.etho)
    
  }
  names(dat) <- cat.names
  return(dat)
  
  
}

df.sorted <- datSortBin(input = df, n.days = 6, cat.names = c("Eth007", "Eth008", "Eth009", "Eth010", "Eth011", "Eth012", "Eth013", "Eth014", "Eth015"), ethoscope.id = c("007cf6", "008be7", "009c62", "010793", "011a1c", "012bbb", "013191", "014a2d", "0159c9"), mins.trim = c(1255, 1255, 1255, 1250, 1255, 1250, 1250, 1250, 1250))

saveRDS(df.sorted, "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/Analysis scripts/analysis_output/all_ethoscopes_merged_04MAY_10sec.rds")
