require(devtools)
library(githubr)
library(dplyr)
library(readr)
library(synapser)
#Get existing RNASeq assay metadata
md <- readr::read_csv(synapser::synGet("syn16816488")$path, col_types = readr::cols(.default = "c"))
#Get re-processed feature counts
counts <- readr::read_tsv(synapser::synGet("syn21071622")$path)
#Get sample Ids
samples <- colnames(counts)[7:2119]
table(samples %in% md$Sample_RNA_ID)

#Samples in count data that are missing from metadata
missing <- setdiff(samples, md$Sample_RNA_ID)
#renamed HBCC samples 
maps <- readr::read_csv(synGet("syn17115622")$path)
table(missing %in% maps$ID)
#remove 80 known mismatches due to using individual HBCC ID as sample name
missing <- missing[!(missing %in% maps$ID)]
missing
file <- File(path = "../CMC_missingMetadata.csv", parent = "syn21077798", versionComment = "In syn21071622, missing from syn16816488")

#Samples in metadata missing from counts
mismatched <- setdiff(md$Sample_RNA_ID, samples)
#remove 80 known mismatches due to using individual HBCC ID as sample name
mismatched <- mismatched[!(mismatched %in% maps$RNA_ID)]
#13 excluded due to QC
not_in_counts <- md[md$Sample_RNA_ID %in% mismatched & is.na(md$`rnaSeq_report:Exclude?`),] %>% 
  select(Individual_ID, Sample_RNA_ID,`rnaSeq_report:Exclude_Reason`, `rnaSeq_report:Exclude?`, `rnaSeq_isolation:Exclude_Reason`)
#11 samples were not present in the counts table that are not marked exclude in the metadata
file2 <- File(path = "../CMC_missingCountData.csv", parent = "syn21077798", versionComment = "In syn16816488, missing from syn21071622")

#For posterity, I will also check individual metadata files - MSSM sample in b37 data freeze
acc <- readr::read_csv(synapser::synGet("syn2929053")$path, col_types = readr::cols(.default = "c"))
c("MSSM_RNA_ACC_BP_19") %in% acc$`Sample RNA ID`
b37 <- readr::read_csv(synapser::synGet("syn16816488", version = 6)$path, col_types = readr::cols(.default = "c"))
c("MSSM_RNA_ACC_BP_19") %in% b37$Sample_RNA_ID

####################
### Provenance ####
repoHead <- getRepo()

thisFileName <- "CMC_freeze4_mapping.R" # name of file in github
thisRepo <- getRepo(repository = "kelshmo/synapse-user-tools", 
                    ref = "branch", 
                    refName =" master")
thisFile <- getPermlink(repository = thisRepo, repositoryPath=thisFileName)

synStore(file,
         used = c("syn16816488", "syn21071622", "syn17115622"),
         executed = thisFile)

synStore(file2,
         used = c("syn16816488", "syn21071622", "syn17115622"),
         executed = thisFile)