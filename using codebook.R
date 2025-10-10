setwd("~/R/GitHub Projects/wearitreadr/Codebook_RMD")
rm(list = ls())
#devtools::document()
devtools::load_all()

generateCodebook(generate_item_description = FALSE)




# GLP-1 Codebook
generateCodebook(
  title = "UH3 GLP-1 Codebook",
  authors = "Ethan O. Kile, Timothy R. Brick",
  funding = "Sponsor: Milton S. Hershey Medical Center",
  abstract =
  "The goal of this clinical trial is to learn if semaglutide can reduce illicit opioid use in adults in outpatient treatment for opioid use disorder, and who are receiving either buprenorphine or methadone maintenance treatment. The main question it aims to answer is:

    • Does semaglutide increase the likelihood that participants will refrain from using illicit and nonprescribed opioids?

  The investigators will compare semaglutide to a placebo (a needle prick that contains no drug) to see if semaglutide works to reduce use of illicit and nonprescribed opioids.

  The participants will:
    Take semaglutide or a placebo every week for 12 weeks
    Visit the clinic every week for urine drug screening and pregnancy testing, vital signs, and to complete mental health and drug use questionnaires
    Complete smartphone surveys sent at set times during the study",
  summary = "This study is still in data collection and therefore has no findings to report at this time.",
  output_file = "UH3 GLP-1 EMA Codebook")


# RG codebook
generateCodebook(generate_item_description = FALSE,
                 title = "Recovery General Project Codebook",
                 authors = "Ethan O. Kile")

