
# temp_dir <- "C:/Users/cbaehr/Downloads"
# temp_dir <- "/Users/christianbaehr/Downloads"

# setwd("C:/Users/cbaehr/Box Sync")
# setwd("/Users/christianbaehr/Box Sync")

if(Sys.info()[1]=="Windows") {
  memory.limit(50000)
}

library(ncdf4); library(raster); library(rgdal); library(sf); library(sp)

###

grid <- read.csv("cambodia_ndvi_eval/inputData/empty_grid.csv", stringsAsFactors = F)
# grid <- grid[sample(rownames(grid), 10000),]

grid_list <- split(grid, sort(rep(1:10, length.out = nrow(grid))))

grid_list <- lapply(grid_list, FUN = function(x) {st_as_sf(x, coords = c("longitude", "latitude"), crs="+proj=longlat +datum=WGS84 +no_defs")})

save(grid_list, file = paste0(temp_dir, "/temp_grid.RData"))

###


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
  covariate_grid <- covariate_grid[, !grepl("geometry", names(covariate_grid))]
  names(covariate_grid) <- c("cell_id", "plantation_dummy", "concession_dummy", "protectedArea_dummy")
  
  write.csv(covariate_grid, paste0(temp_dir, "/covariates", i, ".csv"), row.names = F)
  
}

rm(list = setdiff(ls(), "temp_dir"))


for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/covariates", i, ".csv"), stringsAsFactors = F)
  
  if(i == 1) {covariate_grid <- matrix(nrow = 0, ncol = ncol(temp))}
  
  covariate_grid <- rbind(covariate_grid, temp)
  
}

write.csv(covariate_grid, "cambodia_ndvi_eval/inputData/covariates.csv", row.names = F)

rm(list = setdiff(ls(), "temp_dir"))


###################

## build temp and precip covariate grids. Done separately because of high memory demands


## convert CRU raster to data frame of yearly mean precip
for(i in 1999:2017) {
  for(j in 1:12) {
    temp <- raster(paste0("cambodia_ndvi_eval/inputData/covariates/cru_precip/cru_precip_", i, ".nc"), band = j)
    temp <- rasterToPolygons(temp)
    if(i == 1999 & j == 1) {
      polys <- SpatialPolygons(unlist(temp@polygons), proj4string = CRS("+proj=longlat +datum=WGS84"))
      ras <- temp@data
    } else if(i != 1999 & j == 1) {
      ras <- temp@data
    } else {
      ras <- cbind(ras, temp@data)
    }
  }
  if(i == 1999) {
    precip <- apply(ras, 1, mean)
  } else if(i != 1999 & i != 2017) {
    precip <- cbind(precip, apply(ras, 1, mean))
  } else {
    precip <- cbind(precip, apply(ras, 1, mean))
    precip <- SpatialPolygonsDataFrame(Sr = polys, data = as.data.frame(precip), match.ID = F)
    precip <- st_as_sf(precip)
    
  }
}
names(precip) <- c(paste0("precip_", 1999:2017), "geometry")


for(i in 1:10) {
  
  load(paste0(temp_dir, "/temp_grid.RData"))
  grid_list <- grid_list[[i]]
  
  precip_list <- st_intersects(grid_list, precip)
  precip_list <- ifelse(!sapply(precip_list, length), NA, precip_list)
  precip_list <- lapply(precip_list, function(x) {x[1]})
  precip_list <- unlist(precip_list)
  precip_list <- precip[precip_list,]
  
  precip_grid <- do.call(cbind, list(grid_list, precip_list))
  precip_grid <- as.data.frame(precip_grid)
  precip_grid <- precip_grid[, !grepl("geometry", names(precip_grid))]
  names(precip_grid) <- c("cell_id", paste0("precip_", 1999:2017))
  
  write.csv(precip_grid, paste0(temp_dir, "/precip", i, ".csv"), row.names = F)
  print(i)
}

for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/precip", i, ".csv"), stringsAsFactors = F)
  
  if(i == 1) {precip_grid <- matrix(nrow = 0, ncol = ncol(temp))}
  
  precip_grid <- rbind(precip_grid, temp)
  
}
write.csv(precip_grid, paste0(temp_dir, "/precip.csv"), row.names = F)

rm(list = setdiff(ls(), "temp_dir"))


###

## convert MODIS raster to data frame of yearly mean temperature
for(i in 2001:2017) {
  temp <- raster(paste0("cambodia_ndvi_eval/inputData/covariates/modis_temp/", i, "_modis.tif"))
  temp <- rasterToPolygons(temp)
  if(i == 2001) {
    polys <- SpatialPolygons(unlist(temp@polygons), proj4string = CRS("+proj=longlat +datum=WGS84"))
    ras <- temp@data
  } else if(i != 2001 & i != 2017) {
    ras <- cbind(ras, temp@data)
  } else {
    ras <- cbind(ras, temp@data)
    temperature <- SpatialPolygonsDataFrame(Sr = polys, data = as.data.frame(ras), match.ID = F)
    temperature <- st_as_sf(temperature)
  }
}
names(temperature) <- c(paste0("temp_", 2001:2017), "geometry")



for(i in 1:10) {
  
  load(paste0(temp_dir, "/temp_grid.RData"))
  grid_list <- grid_list[[i]]
  
  temp_list <- st_intersects(grid_list, temperature)
  temp_list <- ifelse(!sapply(temp_list, length), NA, temp_list)
  temp_list <- lapply(temp_list, function(x) {x[1]})
  temp_list <- unlist(temp_list)
  temp_list <- temperature[temp_list,]

  temp_grid <- do.call(cbind, list(grid_list, temp_list))
  temp_grid <- as.data.frame(temp_grid)
  temp_grid <- temp_grid[, !grepl("geometry", names(temp_grid))]
  names(temp_grid) <- c("cell_id", paste0("temp_", 2001:2017))
  
  write.csv(temp_grid, paste0(temp_dir, "/temperature", i, ".csv"), row.names = F)
  
}

rm(list = setdiff(ls(), "temp_dir"))


for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/temperature", i, ".csv"), stringsAsFactors = F)
  
  if(i == 1) {temp_grid <- matrix(nrow = 0, ncol = ncol(temp))}
  
  temp_grid <- rbind(temp_grid, temp)
  
}

write.csv(temp_grid, paste0(temp_dir, "/temperature.csv"), row.names = F)




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
  adm_list <- adm_list[, names(adm_list) != "geometry"]
  names(adm_list) <- c("cell_id", "prov_id", "comm_id", "urban_area")
  
  write.csv(adm_list, paste0(temp_dir, "/adm", i, ".csv"), row.names = F)
  
}

rm(list = setdiff(ls(), "temp_dir"))

for(i in 1:10) {
  
  temp <- read.csv(paste0(temp_dir, "/adm", i, ".csv"), stringsAsFactors = F)
  
  if(i == 1) {adm_grid <- matrix(nrow = 0, ncol = ncol(temp))}
  
  adm_grid <- rbind(adm_grid, temp)
  
}

write.csv(adm_grid, "cambodia_ndvi_eval/inputData/adm.csv", row.names = F)




