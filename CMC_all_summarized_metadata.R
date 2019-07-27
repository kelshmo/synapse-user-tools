## Identify CMC samples with 
# 1. Omics data AND SNP OR WGS
sm <- readr::read_csv(synTableQuery("SELECT * FROM syn20549458")$filepath, col_types = cols(.default = "c"))

summary <- sm %>% 
  group_by(Individual_ID, assayType) %>%
  summarize(n())

omics <- summary$Individual_ID[summary$assayType %in% c("ChIPSeq", "rnaSeq", "proteomics", "ATACSeq")]
genetics <- summary$Individual_ID[summary$assayType %in% c("WGS", "SNP")]

both <- intersect(omics, genetics)
