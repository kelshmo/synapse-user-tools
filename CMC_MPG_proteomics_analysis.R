
md <- readr::read_csv(synGet("syn17009505")$path, col_types = readr::cols(.default = "c"))

folder <- synGetChildren(parent = c("syn20502386"), includeTypes = list("file"))$asList()
synFiles <- tibble(id = unlist(lapply(folder, function(x) x$id)))

get_files_xlsx <- function(synFile = tibble()){
  files <- synFile %>% 
    mutate(thefile = purrr::map(id,synGet)) %>% 
    mutate(filename = purrr::map_chr(thefile, function(x) x$get('name'))) %>% #map_chr to force character values
    mutate(filecontents = purrr::map(thefile, function(x) readxl::read_excel(x$path, skip = 1))) 
  files
}
# skipped header with Pair notation 
files <- get_files_xlsx(synFiles)

#WTE 
wte <- files[grepl("WTE", files$filename),] %>% 
  mutate(batch = c(2,3,1))

foo <- purrr::map2(wte$filecontents, wte$batch, ~ dplyr::mutate(.x, batch = .y))
  
#PSD
psd <- files[grepl("PSD", files$filename),]


