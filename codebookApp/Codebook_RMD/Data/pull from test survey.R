
creds <- wearIT_authorize(study_ID = "2037", base_URL = "https://wearables.vmhost.psu.edu/wearables-survey_sdb/api",
                          key_name="WearIT-API-key-sdb",
                          backup_key_file = "~/.auth/.wearit_sdb",
                          skip_keyring = FALSE)
requestResults <- makeAllRequests(creds)
studyData <- parseStudyJSON(requestResults)
survey_data <- studyData$surveyCombined |>
  filter(!str_detect(External.ID, coll("TEST", TRUE)),
         !str_detect(External.ID, coll("TEXT", TRUE))) |>
  mutate(Survey.Date.Completed = ymd_hms(Survey.Date.Completed),
         Survey.Date.Submitted = ymd_hms(Survey.Date.Submitted),
         Survey.Start = ymd_hms(Survey.Start),
         External.ID = toupper(External.ID))
