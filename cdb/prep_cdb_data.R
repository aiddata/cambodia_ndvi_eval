
cdb <- read.csv("/Users/christianbaehr/Desktop/test/cdb_merged_final.csv", stringsAsFactors = F)

cdb$infant_mort <- cdb$Baby_die_Midw + cdb$Baby_die_TBA

cdb <- cdb[, c("VillGis", "Year", "infant_mort")]

cdb <- reshape(cdb, v.names = "infant_mort", timevar = "Year", idvar = "VillGis", direction = "wide")

library(sf)

village <- st_read("/Users/christianbaehr/Desktop/test/census_2008_villages/Village.shp",
                   stringsAsFactors=F)

village <- village[, c("VILL_CODE", "geometry")]

###

cdb$VillGis <- as.numeric(cdb$VillGis)
village$VILL_CODE <- as.numeric(village$VILL_CODE)

cdb <- merge(cdb, village, by.x="VillGis", by.y="VILL_CODE")

cdb$longitude <- sapply(cdb$geometry, function(x) unlist(strsplit(as.character(x), ","))[1])
cdb$latitude <- sapply(cdb$geometry, function(x) unlist(strsplit(as.character(x), ","))[2])

cdb <- cdb[, names(cdb)!="geometry"]

write.csv(cdb, "/Users/christianbaehr/Desktop/test/cdb_spatial.csv", row.names = F)












