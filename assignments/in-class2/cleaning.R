# cleaning data for assignment 2

library(tidyterra)
library(tidyverse)
library(terra)
library(tidyterra)
library(readxl)

# load shapefile
temp <- vect("/Users/Josh/Downloads/MB_2021_AUST_SHP_GDA2020/MB_2021_AUST_GDA2020.shp")
# just NSW
temp <- temp[temp$STE_NAME21=="New South Wales",]
ggplot() + 
  geom_spatvector(data = temp, fill = NA)

# create extent from 30 N to lower extent of temp and from 115 E to 120 E
ext <- ext(150.5, 151.5, -34.3, -33.2)
temp <- crop(temp, ext)

ggplot() + 
  geom_spatvector(data = temp, fill = NA)

writeVector(temp, "data/meshblocks.shp", overwrite = TRUE)

# pop raster
pop <- rast("/Users/Josh/Downloads/aus_ppp_2020_constrained.tif")
pop <- crop(pop, ext)

# save
writeRaster(pop, "data/pop.tif", overwrite = TRUE)




# pollution
pollution <- read_xlsx("/Users/Josh/Dropbox/Papers/auscoal/data/PM/original/NSW/daily/nsw-2010-2021.xlsx")
# Wide to long
pollution <- pollution %>%
  gather(key = "siteName", value = "value", -Date) %>%
  rename(date = Date)

# remove " 24h average [µg/m≥]"
pollution$siteName <- str_remove(pollution$siteName, " 24h average \\[µg/m≥\\]")
pollution$type <- NA
pollution$type[grepl("PM10", pollution$siteName)] <- "pm10"
pollution$type[grepl("PM2.5", pollution$siteName)] <- "pm25"
pollution$siteName <- str_remove(pollution$siteName, " PM10")
pollution$siteName <- str_remove(pollution$siteName, " PM2.5")

# now to wide with pm10 and pm25
pollution <- pollution %>%
  spread(key = type, value = value)
pollution$siteName <- str_to_lower(pollution$siteName)
# clean two names
pollution$siteName[pollution$siteName=="albion park sth"] <- "albion park south"
pollution$siteName[pollution$siteName=="wagga wagga nth"] <- "wagga wagga north"

# to day
pollution <- pollution %>%
  group_by(siteName, date) %>%
  summarize(pm10 = mean(pm10, na.rm = TRUE),
            pm25 = mean(pm25, na.rm = TRUE)) %>%
  ungroup()

# get locations
locations <- read_csv("/Users/Josh/Dropbox/Papers/auscoal/data/PM/original/NSW/stations_NSW.csv")
locations <- locations %>%
  dplyr::select(siteName, latitude = Latitude, longitude = Longitude)
locations$siteName <- str_to_lower(locations$siteName)
# there are some duplicates.
locations <- locations %>%
  group_by(siteName) %>%
  filter(row_number()==1) %>%
  ungroup()
# merge
pollution <- pollution %>%
  left_join(locations, by = "siteName")
# fix date
pollution$date <- as.Date(pollution$date, format = "%d/%m/%Y")

# for each day, calculate average for last 7 days
pollution <- pollution %>%
  filter(!is.na(date))



# seven days (october 1st through 7th, 2019)
pollution <- pollution |>
  filter(date >= as_date("2019-10-01") & date <= as_date("2019-10-07"))

pollution <- pollution |>
  dplyr::select(-pm25)


# save
write_csv(pollution, "data/pollution.csv")

# to shape
pollution <- vect(pollution, geom = c("longitude", "latitude"), "EPSG:4326")

mesh <- vect("data/meshblocks.shp")

ggplot() + geom_spatvector(data = mesh) + geom_spatvector(data = pollution, color = "red")





sa3 <- vect("/Users/Josh/Downloads/SA3_2021_AUST_SHP_GDA2020/SA3_2021_AUST_GDA2020.shp")
sa3 <- sa3[sa3$STE_NAME21=="New South Wales",]
writeVector(sa3, "data/NSW.shp", overwrite = TRUE)


