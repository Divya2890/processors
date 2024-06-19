# ----------------------------------------------------------------------------
# Preparing regional shares and parameters for creating SIMPLE database
# ----------------------------------------------------------------------------
# Coded by UBaldos 2022-10
#
# This code creates har files data from the txt file which users can edit.
# The har file will be used to create SIMPLE parameters and database
# via a GEMPACK program.
# 
# This requires txt2har programn from GEMPACK 
# (https://www.copsmodels.com/gp-runprog.htm).
#
#    ADDITIONAL NOTES ON TXT2HAR format:
#    a. All lines starting with  !  are ignored.
#    b. Comments after  !  are also ignored.
#    c. Empty lines are ignored.
#    d. Header lines are used by the GEMPACK programs to 
#       read the data i.e.
#       XXX STRINGS LENGTH 12 header "XX" longname "XXX";
#
# =============================== #
# General processing for all data #
# =============================== #
#
# ----- clear R memorylist
rm(list=ls())

#          Define base year
args <-  commandArgs(trailingOnly=TRUE)
year_str = args[1]
input_dir = toString(args[4])
output_dir='/job/result/outputs'
temp_dir = paste(input_dir,"temp",sep="/")
dir.create(temp_dir)

year <- as.numeric(year_str)
dir.create(paste(output_dir,"/",year_str, sep=""), recursive = TRUE)

#          Read data

files <- list.files('/job/data')
if(length(files) == 0){

regions = read.csv("/usr/local/data/region.csv")
rawdata = read.csv("/usr/local/data/parameters.csv")
}else{
regions = read.csv("/job/data/region.csv")
rawdata = read.csv("/job/data/parameters.csv")
}

faodata = read.csv(paste0(input_dir,"/",year,"/QCROP.csv"))

# ==================================================== #
# Checks for set definition and mapping to new regions #
#   if check fails the code will not run               #
# ==================================================== #

#          Check if parameter file matches FAODATA
if(all(rawdata$REGCODE[-1] == toupper(faodata$REG))) 
{print("Sets in data and parameters match. Checking new region mapping...")  
} else {
  print("Error in code....
        Region sets in data and parameters do not match")
  print("Please edit region set in parameter file to exactly match region set in data")
  print("Make sure order of region set in parameter and data are the exactly the same")
  rm(list=ls())}

#          Check if there are duplicates in new regions
if(all(sort(unlist(regions$REG)) == sort(unique(unlist(regions$REG))))) 
{print("No duplicate in new region mapping")
  print("Checking new region mapping to region mapping in parameter file...")  
} else {
  print("Error in new regions mapping ... Please make sure there are no duplicate elements in new region set")
  rm(list=ls())}

#          Check if parameter file matches FAODATA
if(all(sort(unlist(regions$REG)) == sort(unique(unlist(rawdata$NREG[-1]))))) 
  {print("New regions are mapped correctly to all region elements in parameters file")
   print("Proceed with database creation...")  
  } else {
    print("Error in code... Incorrect mapping from new regions to region elements in the parameter file")
    print("Please make sure that all elements in new regions are mapped properly to each region element in parameter file ")
    rm(list=ls())}

#          Number of regions  
nreg <-length(rawdata[-1,1])

#          Number of regions  
ncolname <-names(rawdata)

#          New Regions  
newreg   <- regions$REG

# ============================================================= #
# Creating datafile file used by database script                #
# ============================================================= #
#
# ----- Define sets in the database
# 
sink(paste(temp_dir,"/database.txt",sep=""))
cat(paste(nreg, 'STRINGS LENGTH 12 header "H1" longname "Set REGIONS (',nreg,')";'))
cat("\n") 
writeLines(paste(rawdata[-1,2], "!  ", rawdata[-1,3], sep="")) 
cat("\n") 
cat(paste(length(newreg), 'STRINGS LENGTH 12 header "H2" longname "Set NEW REGIONS (',length(newreg),')";'))
cat("\n") 
writeLines(paste(newreg, sep=""))
cat("\n") 
cat(paste(nreg, 'STRINGS LENGTH 12 header "MP1" longname "Mapping from REGIONS to NEW REGIONS";'))
cat("\n") 
writeLines(paste(rawdata[-1,1], "!  ", rawdata[-1,3], sep=""))
cat("\n") 
cat("\n") 
cat(paste('4 STRINGS LENGTH 12 header "AGGC" longname "Set COMMODITIES";'))
cat("\n")
cat("Crops","\n")
cat("Livestock","\n")
cat("Proc_Food","\n")
cat("Non_Food","\n")
cat("\n") 
cat("\n") 
cat(paste('3 STRINGS LENGTH 12 header "AGGF" longname "Subset FOOD COMMODITIES";'))
cat("\n")
cat("Crops","\n")
cat("Livestock","\n")
cat("Proc_Food","\n")
cat("\n") 
cat("\n") 
cat(paste('2 STRINGS LENGTH 12 header "MKT" longname "Set CROP MARKETS";'))
cat("\n")
cat("local","\n")
cat("global","\n")
cat("\n") 
cat("\n") 
cat(paste('2 STRINGS LENGTH 12 header "COEF" longname "Set COEFFICIENTS";'))
cat("\n")
cat("INT","\n")
cat("SLP","\n")
cat("\n") 
#
# ----- Define shares and parameters used in the database
#
for(i in 4:length(ncolname)){
cat("\n") 
cat(paste(nreg, ' REAL header "',ncolname[i],'" longname "',rawdata[1,i],'";', sep=""))
cat("\n") 
writeLines(paste(as.numeric(rawdata[-1,i]), sep=""))
cat("\n") }
sink()
#
# ----- convert text file into har file
#
sink(paste(temp_dir,"/call_txt2har.bat",sep=""))
cat("/gp12/modhar.exe"," -at=",paste0(temp_dir,'/database.txt'),' -mkhar=',paste0(temp_dir,'/database.har'),sep="")
cat("\n")
cat("\n")
sink()
#
# ----- convert text file into har file
#
command <- paste0("sh ",temp_dir,"/call_txt2har.bat")
system(command, intern=TRUE, wait =TRUE)


# ============================================================= #
# Running script to create the database                         #
# ============================================================= #

# ----- create command file (cmf file)
sink(paste(temp_dir,"/database.CMF", sep=""))
cat( 'set elements read style =  flexible; \n')
cat( 'check-on-read elements = no; \n')
cat( 'auxiliary files = database; \n ')
cat( paste0('FILE INC_DAT   = ',input_dir,'/',year,'/INC.har;  \n '))
cat( paste0('FILE POP_DAT   = ',input_dir,'/',year,'/POP.har;  \n '))
cat( paste0('FILE QCROP_DAT   = ',input_dir,'/',year,'/QCROP.har;  \n '))
cat( paste0('FILE VCROP_DAT   = ',input_dir,'/',year,'/VCROP.har;  \n '))
cat( paste0('FILE QLAND_DAT   = ',input_dir,'/',year,'/QLAND.har;  \n '))
cat( paste0('XSet BASEYEAR # SIMPLE Database # (Y',year,') ; \n '))
cat( paste0('FILE database = ',temp_dir,'/database.har;  \n ') )
cat( paste0('FILE REGDATA = ',temp_dir,'/REGDATA.har;  \n '))
cat( paste0('FILE DATACHKS = ',temp_dir,'/DATACHKS.har;  \n '))
cat( 'XWrite (set) BASEYEAR to file REGDATA header  "YEAR"; \n ')
cat( 'log file = no ; \n ')
sink()

sink(paste(temp_dir,"/database.bat", sep=""))
cat("/gp12/data_proc/database.exe -cmf",paste0(temp_dir,'/database.CMF \n') )
sink()

system(paste0("sh ",temp_dir,'/database.bat'), intern=TRUE, wait =TRUE)

# ============================================================= #
# Running aggregation tab file                                  #
# ============================================================= #
# ----- create command file (cmf file)
sink(paste(temp_dir,"/aggregate.CMF", sep=""))
cat( 'auxiliary files = aggregate; \n ')
cat( 'set elements read style =  flexible; \n')
cat( paste0('FILE REGDATA    = ',temp_dir,'/REGDATA.har;  \n '))
cat( paste0('FILE database   = ',temp_dir,'/database.har;  \n '))

cat( paste0('FILE LANDDATA = ',output_dir,'/',year,'/LANDDATA.har;  \n '))
cat( paste0('FILE LANDPARM = ',output_dir,'/',year,'/LANDPARM.har;  \n '))
cat( paste0('FILE LANDSETS = ',output_dir,'/',year,'/LANDSETS.har;  \n '))
cat( paste0('XSet BASEYEAR # SIMPLE Database # (Y',year,') ; \n '))
cat( 'XWrite (set) BASEYEAR to file LANDDATA header  "YEAR"; \n ')
cat( 'XWrite (set) BASEYEAR to file LANDPARM header  "YEAR"; \n ')
cat( 'XWrite (set) BASEYEAR to file LANDSETS header  "YEAR"; \n ')

cat( 'log file = yes ; \n ')
sink()

sink(paste(temp_dir,"/aggregate.bat", sep=""))
cat("/gp12/data_proc/aggregate.exe -cmf",paste0(temp_dir,'/aggregate.CMF'),"\n" )
sink()

system(paste0("sh ",temp_dir,'/aggregate.bat'), intern=TRUE, wait =TRUE)

unlink(temp_dir, recursive = TRUE)   

 
