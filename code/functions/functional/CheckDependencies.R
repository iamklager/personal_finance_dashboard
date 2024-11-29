#### CheckDependencies
# Checks all necessary dependencies and offers to install them.


CheckDependencies <- function(dependencies, install_dependencies = FALSE) {
  
  stop_function <- FALSE
  
  for (pkg in dependencies) {
    pkg_exists <- require(
      package = pkg, 
      warn.conflicts = FALSE, 
      character.only = TRUE, 
      quietly = TRUE
    )
    
    if (pkg_exists) {
      next
    }
    
    if (install_dependencies) {
      install.packages(pkgs = pkg, verbose = FALSE, quiet = TRUE)
    } else {
      warning(paste0("Package '", pkg, "' or some of its dependencies are not installed."))
      stop_function <- TRUE
    }
  }
  
  if (stop_function) {
    stop("Please install the necessary dependencies.")
  }
  
}
