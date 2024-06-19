#!/usr/bin/env python3

import os
import subprocess
import glob
from subprocess import CalledProcessError
import numpy as np
import csv
from harpy import *


from geoedfframework.GeoEDFPlugin import GeoEDFPlugin
from geoedfframework.utils.GeoEDFError import GeoEDFError

"""Module for running the 01_data_clean and 01_data_proc R script that helps process the 
   FAOSTAT data for preparing the SIMPLE database.
"""

class SimpleDataProc(GeoEDFPlugin):

    # required inputs are:
    # (1) input directory where the CSV files from FAO have been stored
    # (2) start year
    # (3) end year
    
    __optional_params = ['regsets_csv','cropsets_csv','livestocksets_csv','region_csv','parameters_csv']
    __required_params = ['start_year','end_year']

    # we use just kwargs since this makes it easier to instantiate the object from the 
    # GeoEDFProcessor class
    def __init__(self, **kwargs):

        #list to hold all parameter names
        self.provided_params = self.__required_params 

        # check that all required params have been provided
        for param in self.__required_params:
            if param not in kwargs:
               raise GeoEDFError('Required parameter %s for SimpleDataClean not provided' % param)
           
        # set all required parameters
        for key in self.__required_params:
            setattr(self,key,kwargs.get(key))
        # set optional parameters
        for key in self.__optional_params:
            #if key not provided in optional arguments, defaults value to None
            setattr(self,key,kwargs.get(key,None))
         
        # fetch static reg, crop, and livestock set CSVs that are packaged with processor
        # if no overrides have been provided
        # look in setup.py data_files for location where these have been placed
        if self.regsets_csv is None:
            self.regsets_csv = '/usr/local/data/reg_sets.csv'
        if self.cropsets_csv is None:
            self.cropsets_csv = '/usr/local/data/crop_sets.csv'
        if self.livestocksets_csv is None:
            self.livestocksets_csv = '/usr/local/data/livestock_sets.csv'
        if self.region_csv is None:
            self.region_csv = '/usr/local/data/region.csv'
        if self.parameters_csv is None:
            self.parameters_csv = "/usr/local/data/parameters.csv"
        # also fetch the static region maps csv; this file is always packaged with the processor
        self.regmaps_csv = '/usr/local/data/reg_map.csv'

        self.data_clean_script = '/job/executable/01_data_clean.r'    
        self.data_proc_script = '/job/executable/02_data_proc.r'
        
        # validate start and end years
        try:
            if int(self.start_year) > int(self.end_year):
                raise GeoEDFError('start_year must be smaller than end_year in SimpleDataClean')
        except:
            raise GeoEDFError('Error occurred when validating start_year and end_year for SimpleDataClean; make sure they are integers')        
        # super class init
        super().__init__()
    def csv2har(self,csvfile,year):

        regions = []
        vals = []
        # name of the data field
        data_key = None
        with open(csvfile,'r') as csvFileObj:
            reader = csv.DictReader(csvFileObj)
            for row in reader:
                # pre-process step only required once
                # determine the name of the data field
                if data_key is None:
                    if len(list(row.keys())) != 2:
                        raise GeoEDFError("Error in CSV2HAR when processing %s. Exactly two fields are required" % self.csvfile)
                    else:
                        # REG is one, what is the other?
                        for key in row.keys():
                            if key != 'REG':
                                data_key = key
                                break
                regions.append(row['REG'])
                vals.append(row[data_key])

        # now build the HAR file header
        # first create the HAR file object
        (ignore, csvFilename) = os.path.split(csvfile)
        basename = os.path.splitext(csvFilename)[0]
        harFilename = '%s/%s/%s.har' % (self.target_path,year,basename)
        harFile = HarFileObj(harFilename)

        # create the two header array objects and set them to the file

        # first the region header
        # in this header, region names are always padded to 12 characters long
        reg_arr = np.array([reg.ljust(12) for reg in regions],dtype='<U12')
        reg_setNames = ['REG']
        reg_setElements = [[reg.ljust(12) for reg in regions]]
        reg_coeff_name = ''.ljust(12)
        reg_long_name = 'Set REG inferred from CSV file'.ljust(70)
        reg_header = HeaderArrayObj.HeaderArrayFromData(reg_arr,reg_coeff_name,reg_long_name,reg_setNames,dict(zip(reg_setNames,reg_setElements)))
        # add header to HAR file
        harFile["SET1"] = reg_header

        # then the csv data header
        csv_arr = np.array(vals,dtype='float32')
        csv_setNames = ['REG']
        csv_setElements = [regions]
        csv_coeff_name = 'CSVData'.ljust(12)
        csv_long_name = 'Array extracted from CSV'.ljust(70)
        csv_header = HeaderArrayObj.HeaderArrayFromData(csv_arr,csv_coeff_name,csv_long_name,csv_setNames,dict(zip(csv_setNames,csv_setElements)))
        harFile["CSV"] = csv_header
        print("har files are succesfullt created ")
        # write out the HAR file
        harFile.writeToDisk()
        return harFile




    # the process method that calls the 01_data_clean.r script 
    def process(self):
        # the simple data clean R script is invoked with the following command line arguments:
        # 1. start year
        # 2. end year
        # 3. output directory
        # 4. region map csv path
        # 5. region sets csv path
        # 6. crop sets csv path
        # 7. livestock sets csv path

        # dummy init to catch error in stdout
        stdout = ''
        try:
            command = "Rscript"
            args = [str(self.start_year),str(self.end_year),self.target_path,self.regmaps_csv,self.regsets_csv,self.cropsets_csv,self.livestocksets_csv]

            cmd = [command, self.data_clean_script] + args
            stdout = subprocess.check_output(cmd,universal_newlines=True)
            years = [year for year in range(int(self.start_year), int(self.end_year) + 1)]
            for i in years:
                try:
                    csv_files = glob.glob(f"{self.target_path}/{i}/*.csv")
                    for j in csv_files:
                        har = self.csv2har(j,i)
                except:
                    GeoEDFError('Error occurred while converting csv to har files for the year %s' % i)
            

        except CalledProcessError:
            raise GeoEDFError('Error occurred when running SimpleDataClean processor: %s' % stdout)

        # the simple data proc R script is invoked with the following command line arguments:
        # 1. start year
        # 2. end year
	# 3 regions csv
        # 4 parameters csv

        try:
            for i in range(int(self.start_year),int(self.end_year)+1):
                command = "Rscript"
                args = [str(i),self.region_csv,self.parameters_csv,self.target_path]
                
                cmd = [command, self.data_proc_script] + args

                stdout = subprocess.check_output(cmd,universal_newlines=True)

        except CalledProcessError:
            raise GeoEDFError('Error occurred when running data_proc processor: %s' % stdout)
            
            
        

    
