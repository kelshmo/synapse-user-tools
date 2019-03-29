# BrainGVEX
library(synapser)
library(tibble)
library(dplyr)
synLogin()

#get data
SYNID_OF_VIEW <- c("syn12214142")
synapse_fv <- synTableQuery(paste0("SELECT * FROM ", SYNID_OF_VIEW))
fv <- readr::read_csv(synapse_fv$filepath) %>% 
  mutate(parseSpecimenID = purrr::map(`name`, function(x) unlist(strsplit(x, "_"))[7])) %>% 
  mutate(parseSpecimenID = gsub("\\..*", "", parseSpecimenID))
md <- readr::read_csv(synGet("syn18071898", version = 2)$path) %>% 
  mutate(parseSpecimenID = gsub(".*_","", `file name`))

# identify individualID - specimenID pairings in metadata that do not match fileview
misMatch_table <- function(stringToSplit){
  tibble(individualID = sapply(strsplit(stringToSplit, "_"), "[", 1),
         ID = sapply(strsplit(stringToSplit, "_"), "[", 2))
}

# check fileSpecimenId - IId -specimenId pairing
fv_map <- paste0(fv$parseSpecimenID,"_", fv$individualID, "_", fv$specimenID)
md_map <- paste0(md$parseSpecimenID, "_", md$trueIndividualID, "_", md$specimenID)
mm <- setdiff(md_map, fv_map)
maps <- misMatch_table(mm)

# write changes to View
fv_emend <- fv %>% 
  rowwise() %>% 
  mutate(individualID = ifelse(specimenID %in% maps$ID, 
                               maps$individualID[maps$ID == specimenID], individualID))
# store changes to View 
synStore(Table(synapse_fv$tableId, fv_emend))

# write new metadata file, trueIndividualID replaces the individualID
md <- md %>% 
  select(-one_of("individualID", "parseSpecimenID", "renamed")) %>% 
  rename(individualID = trueIndividualID) %>% 
  select(assay, `file name`, consortium, grant, study, PI, individualID, specimenID, everything()) %>% 
  rename(`Exclude?` = exclude) %>% 
  mutate(`Exclude?` = ifelse(`Exclude?` == "yes", 1, NA))

write.csv(md, "./files/UIC-UChicago-U01MH103340_BrainGVEX_ATACseqMetadata.csv", row.names = FALSE)
file <- File(parentId = "syn3270014", path = "./files/UIC-UChicago-U01MH103340_BrainGVEX_ATACseqMetadata.csv", versionComment = "new version from syn18071898" )

# Provenance
require(devtools)
library(githubr)
repoHead <- getRepo("kelshmo/synapse-user-tools")

# upload file to Synapse with provenance
# to learn more about provenance in Synapse, go to http://docs.synapse.org/articles/provenance.html
#use githubr https://github.com/brian-bot/githubr

## Get commits from github 
thisFileName <- "PEC_BrainGVEX_QC2_metadata.R" # name of file in github
thisRepo <- getRepo(repository = "kelshmo/synapse-user-tools", 
                    ref = "branch", 
                    refName = "PEC")
thisFile <- getPermlink(repository = thisRepo, repositoryPath = thisFileName)

# name and describe this activity
activityName = "new version from syn18071898"
activityDescription = "new version from syn18071898"

synStore(file, 
         activityName = activityName,
         activityDescription = activityDescription,
         used = c("syn18071898", "syn12214142"),
         executed = thisFile, 
         forceVersion = FALSE)

