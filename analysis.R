



setwd("C:/Users/JamesMartin/Desktop/a_problem_with_presidents")


######### Load Data ###############

df <- read.csv("U.S. Presidents Birth and Death Information - Sheet1.csv")
df <- apply(df, MARGIN = 2, function(x) ifelse(x=="",NA,x)) # add NA values
df <- data.frame(df) # convert back to data frame
df <- df[-which(grepl("Reference", df$PRESIDENT)),] # remove reference row

#rename columns to be consistent with columns we'll generate later
names(df) <- c("president", "birth_date", "birth_place", 
               "death_date", "death_place")
 

######## Reformat Dates ###########


dt_reformat <- function(x){ # new function to reformat date from df
  
  if(!is.na(x) ){ # if not NA
    
    dt_split <- strsplit(x, " ")[[1]] # split D M and Y
    
    dt_split[1] <- which( grepl(  dt_split[1], month.name)) #get month number
    dt_split[2] <- gsub(",", "", dt_split[2]) # remove comma from day
    
    dt_clean    <- paste(dt_split, collapse = "-") # bring together again
    dt_formated <- as.Date(dt_clean, tryFormats = "%m-%d-%Y") #reformat
    dt_formated <-  as.character(dt_formated) # convert to character
    
    return(dt_formated)
  }else{
    return(NA)
  }
  
}

# apply the function to the date columns
df$birth_date <- sapply(df$birth_date, dt_reformat)
df$death_date <- sapply(df$death_date, dt_reformat)

################## calculate lifespan #####

#extract year from date
df$year_of_birth <- as.numeric(substr(df$birth_date,1,4))
df$year_of_death <- as.numeric(substr(df$death_date,1,4))

# new columns
df$lived_years  <- NA
df$lived_months <- NA
df$lived_days   <- NA

# function to calculate the number defined time spans from days
# requires start date, end date, and float defining the time span
calc_period <- function(dt_start, dt_end, period){
  # get difference in days between start and end 
  days_lived <-  as.numeric(as.Date(dt_end) -  as.Date(dt_start))   
  full_spans_lived <-  floor(days_lived/period) # divide days by period of span
  return(full_spans_lived)
}
# get years, months, and days
df$lived_years  <-  calc_period(df$birth_date, df$death_date, 365.25)
df$lived_months <-  calc_period(df$birth_date, df$death_date, 30.4375)
df$lived_days   <-  calc_period(df$birth_date, df$death_date, 1)

# get rows of currently living presidents
alive_ind <- which(is.na(df$year_of_death))

# remove from the analysis
df <- df[-alive_ind,]

# alternatively, calculate the spans they've been alive based on current date
#df$lived_years[alive_ind]  <- calc_period(df$birth_date[alive_ind], Sys.Date(), 365.25)
#df$lived_months[alive_ind] <- calc_period(df$birth_date[alive_ind], Sys.Date(), 30.4375)
#df$lived_days[alive_ind]   <- calc_period(df$birth_date[alive_ind], Sys.Date(), 1)

  
################ top ten tables ###########

# note the columns we want to show in the output tables
keep_colnames <- c( "president","birth_date","birth_place",
                    "death_date","death_place", "lived_years")

#get the ten longest living presidents by sorting
ten_longest <-  df[order(df$lived_days, decreasing = TRUE)[1:10],]
ten_longest <- ten_longest[keep_colnames] # drop other columns

write.csv(ten_longest, "ten_longest.csv") # write out

#get the ten short living presidents by sorting
ten_shortest <-  df[order(df$lived_days, decreasing = FALSE)[1:10],]
ten_shortest <- ten_shortest[keep_colnames] # drop other columns

write.csv(ten_shortest, "ten_shortest.csv") # write out

################ stats tables ###########
  

results <- rep(NA, 6) # create vector to store summary stats
names(results) <- c("mean", "median", "mode","max", "min", "std_dev") # name

# the number of unique values is the same as the length of the vector
#   therefore there is no mode
length(unique(df$lived_days))== length(df$lived_days)

# fill in values, rounding
results["mean"]    <- round(mean(df$lived_days), digits = 2)
results["median"]  <- round(median(df$lived_days), digits = 2)
results["max"]     <- round(max(df$lived_days), digits = 2)
results["min"]     <- round(min(df$lived_days), digits = 2)
results["std_dev"] <- round(sd(df$lived_days), digits = 2)
 
# # convert vector to data frame
results_tb <- data.frame(metric = names(results), value = unlist(results))
rownames(results_tb) <- 1:nrow(results_tb) # fill in redundant row names

write.csv(results_tb, "summary.csv") # write out
       
############## histogram #############

# open graphics device
png("histogram.png", width = 500, height = 500)

# plot histogram of days
hist(df$lived_days, xlab = "days", ylab = "presidents", breaks = 10,
     main = "Distribution of Longevity")

# close the device and save the plot  
dev.off()
