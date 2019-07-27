############################################
##clinical syn12118229 reformatted to long##
############################################
clinical <- readr::read_csv(synTableQuery("SELECT * FROM syn12118229")$filepath, col_types = readr::cols(.default = "c"))

tabs <- separate(clinical, study, c("study1", "study2"), sep = ",")

tabs1 <- select(tabs, -one_of("study1")) %>% 
  filter(!is.na(study2)) %>% 
  rename(study = study2)
tabs2 <- select(tabs, -one_of("study2")) %>% 
  filter(!is.na(study1)) %>% 
  rename(study = study1)
long <- bind_rows(tabs1, tabs2) %>% 
  unique()

#stored in personal private repository syn18675819

############################################
##join clinical, genotype and assay data ###
############################################

geno <- readr::read_csv(synTableQuery("SELECT * FROM syn10909366")$filepath, col_types = readr::cols(.default = "c"))
assay <- readr::read_csv(synTableQuery("SELECT * FROM syn18420925")$filepath, col_types = readr::cols(.default = "c")) %>% 
  rename(assayNotes = notes)
clinical <- readr::read_csv(synGet("syn18675819")$path, col_types = readr::cols(.default = "c"))

#Make unique key by adding missing clinical individualID
append <- tibble(individualID = setdiff(assay[assay$assay %in% c("ChIPSeq", "rnaSeq"),]$individualID, clinical$individualID))
clinical <- bind_rows(clinical, append)

#join - clinical not joined to snpArray entries 
j <- left_join(assay[assay$assay %in% c("ChIPSeq", "rnaSeq"),], clinical, by = c("study", "individualID"))
g <- left_join(j, geno, by = c("study", "individualID")) %>% 
  select(-one_of("ROW_ID.x", "ROW_VERSION.x", "ROW_ID", "ROW_VERSION", "ROW_ID.y", "ROW_VERSION.y", "Capstone_4.y")) %>% 
  rename(genotypingPlatform = `platform.y`,
         assayPlatform = `platform.x`,
         Capstone_4 = `Capstone_4.x`)
#bind
all <- bind_rows(g, rename(assay[assay$assay %in% c("snpArray"),], assayPlatform = platform)) %>% 
  select(-one_of("ROW_ID", "ROW_VERSION"))

synStore(synBuildTable("Capstone_Dec.2018.Freeze", "syn2787333", all))


  
  
  