rm(list = ls())
library(readxl)
library(data.table)

# Administrative
folder = paste0('/Users/', Sys.info()['user'],'/Dropbox/Unison/data/')
today_date = format(Sys.Date(), format="%m%d%y")
date = paste0('_', today_date)

# Set time out option
options(timeout=200000)

# Browser user agent to bypass bot blocking
user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Helper function to download with curl and browser headers
download_with_headers = function(url, dest_path, is_csv = TRUE) {
    temp_file = tempfile()
    cmd = sprintf('curl -s -H "User-Agent: %s" -o "%s" "%s"',
                  user_agent, temp_file, url)
    system(cmd)

    if (file.exists(temp_file) && file.info(temp_file)$size > 1000) {
        if (is_csv) {
            file = fread(temp_file)
            write.csv(file, file=dest_path, row.names = FALSE)
            cat(paste0("Saved: ", dest_path, " (", nrow(file), " rows)\n"))
        } else {
            file.copy(temp_file, dest_path, overwrite = TRUE)
            cat(paste0("Saved: ", dest_path, "\n"))
        }
        unlink(temp_file)
        return(TRUE)
    } else {
        cat(paste0("ERROR: Failed to download ", url, "\n"))
        return(FALSE)
    }
}

# Unemployment Rate -------------------------------------------------------

cat("\n=== Downloading BLS LAU Data ===\n")

# US Unemployment Rate (UNRATE) : LNS14000000
cat("Downloading US unemployment (LN series)...\n")
download_with_headers('https://download.bls.gov/pub/time.series/ln/ln.data.1.AllData',
                      paste0(folder, 'lau/', 'us_ur', date, '.csv'))

# State Unemployment Rate (seasonally adjusted)
cat("Downloading State unemployment (seasonally adjusted)...\n")
download_with_headers('https://download.bls.gov/pub/time.series/la/la.data.3.AllStatesS',
                      paste0(folder, 'lau/', 'state_ur', date, '.csv'))

# County Unemployment Rate (Not Seasonally Adjusted)
cat("Downloading County unemployment...\n")
download_with_headers('https://download.bls.gov/pub/time.series/la/la.data.64.County',
                      paste0(folder, 'lau/', 'county_ur', date, '.csv'))

# MSA Seasonally Adjusted - now downloaded via Python/curl in run_monthly_update.py
# from https://www.bls.gov/web/metro/ssamatab1.txt


# Population Estimates ----------------------------------------------------

cat("\n=== Downloading Census Population Data ===\n")

# Population 2000-2010 estimates
cat("Downloading Population 2000-2010...\n")
download_with_headers('https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/county/co-est00int-tot.csv',
                      paste0(folder, 'population/', 'popest_0010', date, '.csv'))

# Population 2010-2020 estimates
cat("Downloading Population 2010-2020...\n")
download_with_headers('https://www2.census.gov/programs-surveys/popest/datasets/2010-2020/counties/totals/co-est2020.csv',
                      paste0(folder, 'population/', 'popest_1020', date, '.csv'))

# Population 2020-2024 estimates (2024 vintage)
cat("Downloading Population 2020-2024...\n")
download_with_headers('https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/totals/co-est2024-alldata.csv',
                      paste0(folder, 'population/', 'popest_2024', date, '.csv'))


# Industry Employment -----------------------------------------------------

cat("\n=== Downloading BLS CES Data ===\n")

# National Industry Employment
cat("Downloading National CES...\n")
download_with_headers('https://download.bls.gov/pub/time.series/ce/ce.data.0.AllCESSeries',
                      paste0(folder, 'ces/', 'ce_all', date, '.csv'))

# State and Metro Area Employment, Hours, & Earnings
cat("Downloading State/Metro CES...\n")
download_with_headers('https://download.bls.gov/pub/time.series/sm/sm.data.1.AllData',
                      paste0(folder, 'ces/', 'sm_all', date, '.csv'))


# Geography ---------------------------------------------------------------

cat("\n=== Downloading Geographic Reference Files ===\n")

# Metro geographic reference file (2013 Delineation File)
cat("Downloading Metro delineation file...\n")
temp_xls = tempfile(fileext = '.xls')
cmd = sprintf('curl -s -H "User-Agent: %s" -o "%s" "%s"',
              user_agent, temp_xls,
              'https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2013/delineation-files/list1.xls')
system(cmd)
if (file.exists(temp_xls) && file.info(temp_xls)$size > 1000) {
    file = read_excel(temp_xls, skip=2)
    colnames(file) = sapply(colnames(file), function(x) gsub('\\s+|/','_',x))
    dest_path = paste0(folder, 'xwalks/census_county_cbsa', date, '.csv')
    write.csv(file, file=dest_path, row.names = FALSE)
    cat(paste0("Saved: ", dest_path, "\n"))
}
unlink(temp_xls)

# 2020 CBSA gazetteer (contains CBSA FIPS and latitude and longitude)
cat("Downloading CBSA gazetteer...\n")
temp_zip = tempfile(fileext = '.zip')
cmd = sprintf('curl -s -H "User-Agent: %s" -o "%s" "%s"',
              user_agent, temp_zip,
              'https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_cbsa_national.zip')
system(cmd)
if (file.exists(temp_zip) && file.info(temp_zip)$size > 1000) {
    file = read.csv(unz(temp_zip, '2020_Gaz_cbsa_national.txt'), sep='\t')
    dest_path = paste0(folder, 'xwalks/census_cbsa_gaz2020', date, '.csv')
    write.csv(file, file=dest_path, row.names = FALSE)
    cat(paste0("Saved: ", dest_path, "\n"))
}
unlink(temp_zip)

# QCEW county to MSA Link
cat("Downloading QCEW crosswalk...\n")
download_with_headers('https://www.bls.gov/cew/classifications/areas/qcew-county-msa-csa-crosswalk-csv.csv',
                      paste0(folder, 'xwalks/qcew_county_cbsa', date, '.csv'))

cat("\n=== Download Complete ===\n")
