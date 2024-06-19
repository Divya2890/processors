# ----------------------------------------------------------------------------
# Preparing FAOSTAT data for creating SIMPLE database
# ----------------------------------------------------------------------------
# This code creates country level data which will be aggregated later 
# via a GEMPACK program
#
# =============================== #
# General processing for all data #
# =============================== #
#
# ----- clear R memorylist
rm(list=ls())


# fetch command line arguments specifying:
# 1. Start year
# 2. End year
# 3. output directory
args <-  commandArgs(trailingOnly=TRUE)
start_year_str = args[1]
end_year_str = args[2]
output_dir = toString(args[3])

temp_dir = paste(output_dir,"temp",sep="/")
dir.create(temp_dir)


# ----- define folders for processing data if needed
#setwd("C:/Users/ubaldos/Desktop/SIMPLE Base Data/01_data_clean/")

download.file("http://fenixservices.fao.org/faostat/static/bulkdownloads/Inputs_LandUse_E_All_Data_(Normalized).zip",paste(temp_dir,"Inputs_LandUse_E_All_Data_(Normalized).zip",sep="/"))
download.file("http://fenixservices.fao.org/faostat/static/bulkdownloads/Macro-Statistics_Key_Indicators_E_All_Data_(Normalized).zip",paste(temp_dir,"Macro-Statistics_Key_Indicators_E_All_Data_(Normalized).zip",sep="/"))
download.file("http://fenixservices.fao.org/faostat/static/bulkdownloads/Population_E_All_Data_(Normalized).zip",paste(temp_dir,"Population_E_All_Data_(Normalized).zip",sep="/"))
download.file("http://fenixservices.fao.org/faostat/static/bulkdownloads/Prices_E_All_Data_(Normalized).zip",paste(temp_dir,"Prices_E_All_Data_(Normalized).zip",sep="/"))
download.file("http://fenixservices.fao.org/faostat/static/bulkdownloads/Production_Crops_Livestock_E_All_Data_(Normalized).zip",paste(temp_dir,"Production_Crops_Livestock_E_All_Data_(Normalized).zip",sep="/"))

# ----- read in all zip files and unzip in 'temp' folder
zipfile <- list.files(path = temp_dir,pattern = "\\.zip$",  recursive = TRUE)
cat("ZIPFILES",zipfile)
for(j in zipfile){
file1=paste0(temp_dir,'/',j)
unzip(zipfile =  file1, exdir =temp_dir)
}

# ----- define relevant sets for base data
# determine years of processing
start_year <- as.numeric(start_year_str)
end_year <- as.numeric(end_year_str)
years     <- seq(start_year,end_year,1) # start year and end year

country   <- read.csv("/usr/local/data/reg_sets.csv")
country   <- country[,1]
crop      <- read.csv("/usr/local/data/crop_sets.csv")
crop      <- crop[,1]
livestock <- read.csv("/usr/local/data/livestock_sets.csv")
livestock <- livestock[,1]


# ----- re-read all csv files with filtered data and process one by one
csvfile <- list.files(path = temp_dir, pattern = "\\.csv$", full.names = TRUE)

# ======================== #
# Data specific processing #
# ======================== #
# These codes do the following: 
#   Read data, get subset data depending on year and variable of interest as well as 
#   SIMPLE country and crop coverage. Then drop observations with NA values for each 
#   and finally write filtered data

# 	Arable land and Permanent crops
# ----- Filter data 
datatable  <- read.csv(paste(temp_dir,"Inputs_LandUse_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Item.Code==6620) 
datatable2 <- subset(datatable2,  Element.Code==5110) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- subset(datatable2, select=c("Area.Code", "Year.Code", "Value"))  
datatable2 <- datatable2[complete.cases(datatable2),]
write.csv(datatable2, paste(temp_dir,"00_cropland.csv",sep="/"), row.names=FALSE )
names(datatable2) <- c("CNTRY","YEAR","QLAND")
write.csv(datatable2, paste(temp_dir,"QLAND.csv",sep="/"), row.names=FALSE )

# GDP in 2015 USD
# ----- Filter data 
datatable  <- read.csv(paste(temp_dir,"Macro-Statistics_Key_Indicators_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Item.Code==22008) 
datatable2 <- subset(datatable2,  Element.Code==6184) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- subset(datatable2, select=c("Area.Code", "Year.Code", "Value"))
datatable2 <- datatable2[complete.cases(datatable2),]
write.csv(datatable2,paste(temp_dir,"00_realgdp.csv",sep="/"), row.names=FALSE )
names(datatable2) <- c("CNTRY","YEAR","INC")
write.csv(datatable2,paste(temp_dir,"INC.csv",sep="/"), row.names=FALSE )

# Population
# ----- Filter data 
datatable  <- read.csv(paste(temp_dir,"Population_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Item.Code==3010) 
datatable2 <- subset(datatable2,  Element.Code==511) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- subset(datatable2, select=c("Area.Code", "Year.Code", "Value"))
datatable2 <- datatable2[complete.cases(datatable2),]
colnames(datatable2) <- c("Area.Code", "Year.Code", "Value")          
write.csv(datatable2,paste(temp_dir,"00_population.csv",sep="/"), row.names=FALSE )
names(datatable2) <- c("CNTRY","YEAR","POP")
write.csv(datatable2,paste(temp_dir,"POP.csv",sep="/"), row.names=FALSE )

# Crop Prices (USD currency only)
datatable  <- read.csv(paste(temp_dir,"Prices_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Element.Code==5532) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$ Item.Code %in% crop,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- subset(datatable2, select=c("Area.Code", "Item.Code", "Year.Code", "Value")) 
datatable2 <- datatable2[complete.cases(datatable2),]
write.csv(datatable2,paste(temp_dir,"00_cropprices.csv",sep="/"), row.names=FALSE )

# Livestock Prices (USD currency only)
datatable  <- read.csv(paste(temp_dir,"Prices_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Element.Code==5532) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$ Item.Code %in% livestock,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- datatable2[complete.cases(datatable2),]
datatable2 <- subset(datatable2, select=c("Area.Code", "Item.Code", "Year.Code", "Value"))
write.csv(datatable2,paste(temp_dir,"00_liveprices.csv",sep="/"), row.names=FALSE )

# Crop Production 
datatable  <- read.csv(paste(temp_dir,"Production_Crops_Livestock_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Element.Code==5510) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$ Item.Code %in% crop,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- datatable2[complete.cases(datatable2),]
datatable2 <- subset(datatable2, select=c("Area.Code", "Item.Code", "Year.Code", "Value"))
write.csv(datatable2,paste(temp_dir,"00_cropprod.csv",sep="/"), row.names=FALSE )

# Crop Harvested Area 
datatable  <- read.csv(paste(temp_dir,"Production_Crops_Livestock_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Element.Code==5312) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$ Item.Code %in% crop,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- datatable2[complete.cases(datatable2),]
datatable2 <- subset(datatable2, select=c("Area.Code", "Item.Code", "Year.Code", "Value"))
write.csv(datatable2,paste(temp_dir,"00_cropharea.csv",sep="/"), row.names=FALSE )

# Livestock Production 
datatable  <- read.csv(paste(temp_dir,"Production_Crops_Livestock_E_All_Data_(Normalized).csv",sep="/"))
datatable2 <- subset(datatable, select=c("Area.Code", "Item.Code", "Element.Code", "Year.Code", "Value"))
datatable2 <- subset(datatable2,  Element.Code==5510) 
datatable2 <- datatable2[datatable2$ Area.Code %in% country,] 
datatable2 <- datatable2[datatable2$ Item.Code %in% livestock,] 
datatable2 <- datatable2[datatable2$Year %in% years,]
datatable2 <- datatable2[complete.cases(datatable2),]
datatable2 <- subset(datatable2, select=c("Area.Code", "Item.Code", "Year.Code", "Value"))
write.csv(datatable2,paste(temp_dir,"00_liveprod.csv",sep="/"), row.names=FALSE )

# =========================================== #
# Corn-equivalent weights for crop production #
# =========================================== #
# ----- Read in crop production and prices
cropprice  <- read.csv(paste(temp_dir,"00_cropprices.csv",sep="/"))
cropprod   <- read.csv(paste(temp_dir,"00_cropprod.csv",sep="/"))
# ----- Merge production and price data then calculate value  
cropvalue <- merge(cropprice, cropprod, by=c("Area.Code","Item.Code","Year.Code"), all = FALSE)
names(cropvalue) <- c("Area.Code","Item.Code","Year.Code","Price","Prod")
cropvalue$Value <- cropvalue$Price*cropvalue$Prod
cropvalue <- subset(cropvalue, select=c("Area.Code","Item.Code","Year.Code","Prod","Value"))
# ----- Remove obs with zero value and prod values then aggregate prod and value by item and year
cropvalue[cropvalue == 0] <- NA
cropvalue <- cropvalue[complete.cases(cropvalue),]
write.csv(cropvalue,paste(temp_dir,"00_cropvalue.csv",sep="/"), row.names=FALSE )
wldcrop <- aggregate(cropvalue, list(cropvalue$Item.Code, cropvalue$Year.Code), sum)
wldcrop <- subset(wldcrop, select=c( "Group.1","Group.2","Prod","Value"))
names(wldcrop) <- c("Item.Code","Year.Code","Prod","Value")
# ----- Calculate global prices, corn equivalent price for each crop and write data
wldcrop$PriceW <- wldcrop$Value / wldcrop$Prod
write.csv(subset(wldcrop, select=c("Item.Code","Year.Code","PriceW")),paste(temp_dir,"00_wldcropprice.csv",sep="/"), row.names=FALSE ) 
wldcornprice <- subset(wldcrop, Item.Code==56, select=c("Year.Code","PriceW")) 
write.csv(wldcornprice,paste(temp_dir,"00_wldcornprice.csv",sep="/"), row.names=FALSE )
names(wldcornprice) <- c("Year.Code","CornPriceW")
wldcrop <- merge(wldcrop, wldcornprice, by=c("Year.Code"))
wldcrop$CornEqPriceW <- wldcrop$PriceW / wldcrop$CornPriceW
WldCornEqPrice <- subset(wldcrop, select=c("Year.Code","Item.Code","CornEqPriceW"))
write.csv(WldCornEqPrice, paste(temp_dir,"00_WldCornEqPrice.csv",sep="/"), row.names=FALSE )

# ----- Recalculate new value data and corn equivalent data
wldcorneqprice  <- read.csv(paste(temp_dir,"00_WldCornEqPrice.csv",sep="/"))
wldcropprices   <- read.csv(paste(temp_dir,"00_wldcropprice.csv",sep="/"))
cropprod        <- read.csv(paste(temp_dir,"00_cropprod.csv",sep="/"))
wldcornprice    <- read.csv(paste(temp_dir,"00_wldcornprice.csv",sep="/"))

fincropprod  <- merge(cropprod, wldcorneqprice, by=c("Item.Code","Year.Code"), all = FALSE)
fincropprod$QCROP <- fincropprod$Value * fincropprod$CornEqPriceW
fincropprod  <- subset(fincropprod, select=c("Item.Code","Year.Code","Area.Code","QCROP"))
fincropprod  <- merge(fincropprod, wldcornprice, by=c("Year.Code"), all = FALSE)
fincropprod$VCROP <- fincropprod$QCROP * fincropprod$PriceW
fincropprod  <- subset(fincropprod, select=c("Area.Code","Year.Code","QCROP","VCROP"))
fincropprod  <- aggregate(fincropprod, list(fincropprod$Area.Code, fincropprod$Year.Code), sum)
names(fincropprod) <- c("CNTRY","YEAR"," Area.Code"," Year.Code","QCROP","VCROP")
write.csv(subset(fincropprod, select= c("CNTRY","YEAR","QCROP")), paste(temp_dir,"QCROP.csv",sep="/"), row.names=FALSE)
write.csv(subset(fincropprod, select= c("CNTRY","YEAR","VCROP")), paste(temp_dir,"VCROP.csv",sep="/"), row.names=FALSE)

# =================================================== #
# Chicked-equivalent weights for livestock production #
# =================================================== #
# ----- Skip this one for now ------#


# ===================================================== #
# Merge all data together and create har file from data #
# ===================================================== #
REG    <- read.csv("/usr/local/data/reg_map.csv")
INC    <- read.csv(paste(temp_dir,"INC.csv",sep="/"))
POP    <- read.csv(paste(temp_dir,"POP.csv",sep="/"))
QCROP  <- read.csv(paste(temp_dir,"QCROP.csv",sep="/"))
VCROP  <- read.csv(paste(temp_dir,"VCROP.csv",sep="/"))
QLAND  <- read.csv(paste(temp_dir,"QLAND.csv",sep="/"))

data_names <- c("INC","POP","QCROP","VCROP","QLAND")

for(i in years){
dir.create(paste(output_dir,"/",i, sep=""), recursive = TRUE)} 


for(i in data_names){
for(j in years){
data_table     <- merge(get(i), REG, by="CNTRY", all=FALSE)
data_table     <- data_table[data_table$YEAR == j,]
data_table2    <- aggregate(data_table[,3], list(data_table$REG), sum)
names(data_table2) <- c("REG",i)
write.csv(data_table2, paste(output_dir,"/",j,"/",i,".csv", sep=""), row.names=FALSE)}}



          
# ======== #
# Clean-up #
# ======== #          
#          Delete batch file

#          Delete 'temp' folder
unlink(temp_dir, recursive = TRUE)
          
