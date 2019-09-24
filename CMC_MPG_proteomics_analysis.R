##############################
## Merge Across Batch ########
##############################

md <- readr::read_csv(synGet("syn17009505")$path, col_types = readr::cols(.default = "c"))

# Get all files in this folder
folder <- synGetChildren(parent = c("syn20502386"), includeTypes = list("file"))$asList()
synFiles <- tibble(id = unlist(lapply(folder, function(x) x$id)))

# Download each sheet as nested in a list object
get_files_xlsx <- function(synFile = tibble()){
  files <- synFile %>% 
    mutate(thefile = purrr::map(id,synGet)) %>% 
    mutate(filename = purrr::map_chr(thefile, function(x) x$get('name'))) %>% #map_chr to force character values
    mutate(filecontents = purrr::map(thefile, function(x) readxl::excel_sheets(x$path) %>% 
                                       set_names() %>% 
                                       map(readxl::read_excel, path = x$path))) 
  files
}

# Each excel file has the L-H ratio as the first sheet
# AUC-light chain as the second sheet
# AUC-heavy chain as the third sheet
files <- get_files_xlsx(synFiles)

# WTE and PSD
#1. get all WTE and PSD
psd <- files[grepl("PSD", files$filename),]

# batch will be tracked in the metadata file so no need to add it to the data
# merge <- purrr::map2(wte$filecontents, wte$batch, ~ dplyr::mutate(.x, batch = .y))

ratio <- lapply(psd$filecontents, `[[`, 3)
# took manual steps to add sample names to header 
# colnames(ratio[[1]]) <-ratio[[1]][1,]
# ratio[[1]] <- ratio[[1]][-c(1),]

ratio_merged <- ratio %>% 
  purrr::map(., function(x) group_by(x, `Peptide Sequence`) %>% 
                         mutate(Index = 1:n()) %>% 
               select(`Accession number`, `Gene name`, `Protein Name`, `Peptide Sequence`, Index, everything()))

merged <- reduce(ratio_merged, full_join, by = c("Accession number", "Gene name", "Protein Name", "Peptide Sequence", "Index"))
