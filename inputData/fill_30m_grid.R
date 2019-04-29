
# temp_dir <- "C:/Users/cbaehr/Downloads"
temp_dir <- "/Users/christianbaehr/Downloads"
# setwd("C:/Users/cbaehr/Box Sync")
setwd("/Users/christianbaehr/Box Sync")

if(Sys.info()[1]=="Windows") {
  memory.limit(50000)
}

library(sf)

###

grid <- read.csv("cambodia_ndvi_eval/inputData/empty_grid.csv", stringsAsFactors = F)
# grid <- grid[sample(rownames(grid), 10000),]

grid_list <- split(grid, sort(rep(1:10, length.out = nrow(grid))))

grid_list <- lapply(grid_list, FUN = function(x) {st_as_sf(x, coords = c("longitude", "latitude"), crs="+proj=longlat +datum=WGS84 +no_defs")})

save(grid_list, file = paste0(temp_dir, "/temp_grid.RData"))

###

rm(list = setdiff(ls(), "temp_dir"))

plantations <- st_read("cambodia_ndvi_eval/inputData/gfw_plantations/Tree_plantations.shp", stringsAsFactors=F)[, "geometry"]
concessions <- st_read("cambodia_ndvi_eval/inputData/odc_landConcessions/ELC.shp", stringsAsFactors=F)[, "geometry"]
protected_areas <- st_read("cambodia_ndvi_eval/inputData/wdpa_protectedAreas/WDPA_Apr2019_KHM-shapefile-polygons.shp", stringsAsFactors=F)[, "geometry"]


for(i in 1:10) {
  
  load(paste0(temp_dir, "/temp_grid.RData"))
  grid_list <- grid_list[[i]]
  
  plantations_list <- st_intersects(grid_list, plantations)
  plantations_list <- ifelse(!sapply(plantations_list, length), 0, 1)
  
  concessions_list <- st_intersects(grid_list, concessions)
  concessions_list <- ifelse(!sapply(concessions_list, length), 0, 1)
  
  protectedAreas_list <- st_intersects(grid_list, protected_areas)
  protectedAreas_list <- ifelse(!sapply(protectedAreas_list, length), 0, 1)
  
  covariate_grid <- do.call(cbind, list(grid_list, plantations_list, concessions_list, protectedAreas_list))
  covariate_grid <- as.data.frame(covariate_grid)
  covariate_grid <- covariate_grid[, c(1:4)]
  names(covariate_grid) <- c("cell_id", "plantation_dummy", "concession_dummy", "protectedArea_dummy")
  
  write.csv(covariate_grid, paste0(temp_dir, "/covariates", i, ".csv"), row.names = F)
  
}

rm(list = setdiff(ls(), "temp_dir"))

covariate_grid <- matrix(nrow = 0, ncol = 4)

for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/covariates", i, ".csv"), stringsAsFactors = F)
  
  covariate_grid <- rbind(covariate_grid, temp)
  
}

write.csv(covariate_grid, "cambodia_ndvi_eval/inputData/covariates.csv", row.names = F)


###################

rm(list = setdiff(ls(), "temp_dir"))

treatment <- st_read("cambodia_ndvi_eval/inputData/village_shapefiles/buf_trt_villages/buf_trt_villages.shp", stringsAsFactors = F)


for(i in 1:10) {
  
  load(paste0(temp_dir, "/temp_grid.RData"))
  grid_list <- grid_list[[i]]
  
  treatment_list <- st_intersects(grid_list, treatment)
  treatment_list <- ifelse(!sapply(treatment_list, length), NA, treatment_list)
  
  end_years <- lapply(treatment_list, FUN = function(x) {paste0(treatment$end_years[x], collapse = "|")})
  end_years <- sapply(end_years, strsplit, split = "\\|")
  end_years <- sapply(end_years, as.integer)
  
  end_years <- sapply(end_years, function(x) {cumsum(table(factor(unlist(x), levels = c(2003:2018))))})
  end_years <- t(end_years)
  
  treatment_list <- cbind.data.frame(as.data.frame(grid_list)[, 1], end_years)
  names(treatment_list) <- c("cell_id", paste0("trt_", 2003:2018))
  
  write.csv(treatment_list, paste0(temp_dir, "/treatment", i, ".csv"), row.names = F)
  
}

rm(list = setdiff(ls(), "temp_dir"))

treatment_grid <- matrix(nrow = 0, ncol = 16)

for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/treatment", i, ".csv"), stringsAsFactors = F)
  
  treatment_grid <- rbind(treatment_grid, temp)
  
  
}

treatment_grid[paste0("trt", 1999:2003)] <- 0

write.csv(treatment_grid, "cambodia_ndvi_eval/inputData/treatment.csv", row.names = F)

###################


provinces <- st_read("cambodia_ndvi_eval/inputData/KHM_ADM1/KHM_ADM1.shp", stringsAsFactors = F)
communes <- st_read("cambodia_ndvi_eval/inputData/KHM_ADM3/KHM_ADM3.shp", stringsAsFactors = F)
urban_extents <- st_read("cambodia_ndvi_eval/inputData/urban_extents/urban_extents.shp", stringsAsFactors = F)

for(i in 1:10) {
  
  load(paste0(temp_dir, "/temp_grid.RData"))
  grid_list <- grid_list[[i]]
  
  province_list <- st_intersects(grid_list, provinces)
  province_list <- ifelse(!sapply(province_list, length), NA, province_list)
  province_list <- lapply(province_list, function(x) {x[1]})
  province_list <- unlist(province_list)

  commune_list <- st_intersects(grid_list, communes)
  commune_list <- ifelse(!sapply(commune_list, length), NA, commune_list)
  commune_list <- lapply(commune_list, function(x) {x[1]})
  commune_list <- unlist(commune_list)
  
  urban_list <- st_intersects(grid_list, urban_extents)
  urban_list <- ifelse(!sapply(urban_list, length), 0, 1)
  # urban_list <- lapply(urban_list, function(x) {x[1]})
  # urban_list <- unlist(urban_list)
  
  adm_list <- cbind.data.frame(grid_list, province_list, commune_list, urban_list)
  adm_list <- adm_list[, c(1, 3:5)]
  names(adm_list) <- c("cell_id", "prov_id", "comm_id", "urban_area")
  
  write.csv(adm_list, paste0(temp_dir, "/adm", i, ".csv"), row.names = F)
  
  
}


rm(list = setdiff(ls(), "temp_dir"))

adm_grid <- matrix(nrow = 0, ncol = 4)

for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/adm", i, ".csv"), stringsAsFactors = F)
  
  adm_grid <- rbind(adm_grid, temp)
  
}

write.csv(adm_grid, "cambodia_ndvi_eval/inputData/adm.csv", row.names = F)




