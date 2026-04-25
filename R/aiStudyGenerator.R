


aiStudyGenerator <- function(endpoint, api_key, query) {


  # Create virtual env
  use_virtualenv("ai-env", required = TRUE)

  # Install packages if missing
  py_install(c("pandas", "numpy", "langchain_openai", "json", "jsonschema", "langchain_core"), pip = TRUE)

  reticulate::py_run_file("../python/aiStudyGenerator.py")
}
