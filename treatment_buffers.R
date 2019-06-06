
box_dir <- "C:/Users/cbaehr/Box Sync"
temp_dir <- "C:/Users/cbaehr/Downloads/tif_files"

library(rgdal); library(rgeos); library(sf); library(sp)

## read in 3km buffered village data and format
villages <- st_read(paste0(box_dir, "/cambodia_ndvi_eval/inputData/village_shapefiles/buffered_villages/buffered_villages.shp"),
                    stringsAsFactors=F)
villages$VILL_CODE <- as.integer(villages$VILL_CODE)
villages <- villages[, c("VILL_CODE", "geometry")]

## read in PID treatment data
pid <- read.csv(paste0(box_dir, "/cambodia_ndvi_eval/inputData/pid.csv"), stringsAsFactors = F)
## collapse PID so there are no rows with duplicate village IDs
## in cases of multiple treatments per village, separate end years by "|"
temp <- tapply(pid$actual.end.yr, INDEX=list(pid$village.code), 
               FUN = function(x) {paste0(x, collapse = "|")})
## create trimmed PID dataset with only village code and end years
temp <- as.data.frame(cbind(names(temp), unname(temp)), stringsAsFactors=F)

## merge PID data with village polygons (buffers)
treatment <- merge(temp, villages, by.x = "V1", by.y = "VILL_CODE")
names(treatment) <- c("vill_code", "end_years", "geometry")

## convert geometry to "sp" class
polys <- as_Spatial(treatment$geometry, IDs = as.character(1:nrow(treatment)))

## convert treatment shape data to "SpatialPointsDataFrame"
treatment <- SpatialPolygonsDataFrame(Sr=polys, data = treatment)

## write treatment shape data to a shapefile
# writeOGR(treatment[, names(treatment)!="geometry"], paste0(box_dir, "/cambodia_ndvi_eval/inputData/village_shapefiles/buf_trt_villages/buf_trt_villages.shp"),
#          layer = "vill_code", driver = "ESRI Shapefile")

## create a secondary shapefile with dissolved buffers for generating the grid
treatment$country <- "Cambodia"
polys <- gUnaryUnion(treatment, id = treatment@data$country)
dissolved_buffers <- SpatialPolygonsDataFrame(polys, data = as.data.frame(treatment[1,]), match.ID = F)

# writeOGR(dissolved_buffers[, names(dissolved_buffers)!="geometry"], paste0(box_dir, "/cambodia_ndvi_eval/inputData/village_shapefiles/dissolve_buf_villages/dissolve_buf_villages.shp"),
#          layer = "vill_code", driver = "ESRI Shapefile", overwrite_layer = T)




