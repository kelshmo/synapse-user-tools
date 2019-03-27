library(dplyr)
library(synapser)

synLogin()

rnaSeq <- readr::read_csv(synGet("syn16816488")$path, col_types = readr::cols (.default = "c")) %>% 
  filter(Institution == "Pitt") %>% 
  select(Individual_ID, `rnaSeq_dissection:Brain_Region`,Sample_RNA_ID, `rnaSeq_report:Exclude?`)

write.csv(rnaSeq, "./files/PITT_rnaSeq.csv", row.names = FALSE)

WGS <- readr::read_csv(synGet("syn16816491")$path, col_types = readr::cols (.default = "c"))

summarize_dlpfc <- rnaSeq %>%
  mutate(DLPFC = ifelse(`rnaSeq_dissection:Brain_Region` == "DLPFC", "TRUE", NA)) %>% 
  group_by(Individual_ID, DLPFC) %>% 
  summarize(n()) %>% 
  filter(DLPFC %in% c("TRUE")) %>% 
  select(Individual_ID, DLPFC)

summarize_acc <- rnaSeq %>% 
  mutate(ACC = ifelse(`rnaSeq_dissection:Brain_Region` == "ACC", "TRUE", NA)) %>% 
  group_by(Individual_ID, ACC) %>% 
  summarize(n()) %>% 
  filter(ACC %in% c("TRUE")) %>% 
  select(Individual_ID, ACC)

tissue_summary <- full_join(summarize_acc, summarize_dlpfc) %>% 
  mutate(WGS = ifelse(Individual_ID %in% WGS$Individual_ID, "TRUE", NA))

write.csv(tissue_summary, "./files/rnaSeqDLPFC-ACC_WGS.csv", row.names = FALSE)

###Provenance
require(devtools)
library(githubr)
repoHead <- getRepo()

# upload file to Synapse with provenance
# to learn more about provenance in Synapse, go to http://docs.synapse.org/articles/provenance.html
#use githubr https://github.com/brian-bot/githubr

## Get commits from github 
thisFileName <- "CMC_rnaSeq-WGS_Bernie.R" # name of file in github
thisRepo <- getRepo(repository = "kelshmo/synapse-user-tools", 
                    ref="branch", 
                    refName="CMC")
thisFile <- getPermlink(repository = thisRepo, repositoryPath=thisFileName)

# name and describe this activity
activityName = "Query existing CMC metadata"
activityDescription = "rnaSeq and WGS data available, per individual, per tissue"

file <- File(parent = "syn18477457", path = "./files/PITT_rnaSeq.csv")

synStore(file, 
         activityName = activityName,
         activityDescription = activityDescription,
         used = c("syn16816488"),
         executed = thisFile)

file <- File(parent = "syn18477457", path = "./files/rnaSeqDLPFC-ACC_WGS.csv")

synStore(file, 
         activityName = activityName,
         activityDescription = activityDescription,
         used = c("syn16816488","syn16816491"),
         executed = thisFile)
