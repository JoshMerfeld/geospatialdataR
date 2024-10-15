# cleaning data for assignment 1

library(tidyterra)
library(tidyverse)
library(terra)

# load previous shapefile for projection
temp <- vect("/Users/Josh/Dropbox/KDIS/Classes/geospatialdataR/week4files/kgrid.shp")


# load geojson of provinces
do <- vect("/Users/Josh/Downloads/skorea-provinces-2018-geo.json")
do <- do |> filter(name_eng=="Seoul")
do <- do |> dplyr::select(province = name_eng)
do <- project(do, crs(temp))

# gu
gu <- vect("/Users/Josh/Downloads/skorea-municipalities-2018-geo.json")
gu <- gu |> select("name_eng")
gu <- project(gu, crs(temp))
gu <- intersect(gu, do)
gu <- aggregate(gu, "name_eng")
writeVector(gu, "data/seoulgu.shp", overwrite = TRUE)

# create grid
grid <- rast(do, res=100)
grid <- as.polygons(grid)
grid$id <- 1:nrow(grid)
grid <- intersect(grid, do)
grid <- aggregate(grid, "id")
# pop raster
pop <- rast("/Users/Josh/Downloads/kor_ppp_2020_constrained.tif")
pop <- project(pop, crs(temp))
# extract
grid$pop <- round(extract(pop["kor_ppp_2020_constrained"], grid, fun = "mean", na.rm = TRUE, method = "bilinear", ID = FALSE), 0)
writeVector(grid, "data/seoulgrid.shp", overwrite = TRUE)



# Load rail stations
transport <- vect("/Users/Josh/Downloads/south-korea-latest-free.shp/gis_osm_transport_free_1.shp")
transport <- transport |> filter(fclass=="railway_station")
transport <- project(transport, crs(temp))
transport <- intersect(transport, do)
transport <- project(transport, "EPSG:4326")
writeVector(transport, "data/seoulrail.shp", overwrite = TRUE)



# points of interest
points <- vect("/Users/Josh/Downloads/south-korea-latest-free.shp/gis_osm_pois_a_free_1.shp")
points <- points |> filter(fclass %in% c("hospital", "supermarket", "school"))
points$fclass[grep("초등학교", points$name)] <- "elementaryschool"
points$fclass[grep("중학교", points$name)] <- "middleschool"
points$fclass[grep("고등학교", points$name)] <- "highschool"
points <- points |> select(-c("osm_id", "name"))
points <- project(points, crs(temp))
points <- intersect(points, do)
points <- project(points, "EPSG:4326")
# get lon/lat
points$lon <- geom(points)[,"x"]
points$lat <- geom(points)[,"y"]
# remove geometry
points <- as_tibble(points)
write_csv(points, "data/seoulpoints.csv")



# water
water <- vect("/Users/Josh/Downloads/south-korea-latest-free.shp/gis_osm_water_a_free_1.shp")
water <- project(water, crs(temp))
water <- intersect(water, do)
water <- aggregate(water, "osm_id")
writeVector(water, "data/seoulwater.shp", overwrite = TRUE)

ggplot() + 
  geom_spatvector(data = water, fill = "blue") +
  geom_spatvector(data = gu, fill = NA)





