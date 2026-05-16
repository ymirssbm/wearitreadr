#' Get package resource path
#'
#' Helper to locate files in installed package or development
#' @noRd
get_resource_path <- function(...) {
  pkg_dir <- Sys.getenv("WEARIT_PKG_DIR", "")
  if (pkg_dir == "") {
    # Not set - try to find installed package
    pkg_dir <- system.file(package = "WearItReadR")
  }
  if (pkg_dir == "") {
    # Still not found - assume development mode in codebookApp
    return(file.path("codebookApp", ...))
  }
  file.path(pkg_dir, ...)
}
