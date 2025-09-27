setwd("~/R/GitHub Projects/wearitreadr/Codebook_RMD")
rm(list = ls())
#devtools::document()
devtools::load_all()

generateCodebook()
