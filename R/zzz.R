
# PACKAGE IMPORTS ----

#' @import modeltime
#' @importFrom reticulate py

# PACKAGE ENVIRONMENT SETUP ----

detect_conda_env <- function() {

    ret <- NULL
    tryCatch({
        ret <- reticulate::conda_list() %>%
            dplyr::filter(stringr::str_detect(python, pkg.env$env_name))
    }, error = function(e) {
        ret <- NULL
    })

    return(ret)

}

pkg.env            <- new.env()
pkg.env$env_name   <- "r-gluonts"
pkg.env$activated  <- FALSE
pkg.env$conda_envs <- detect_conda_env()



# ONLOAD ----

gluonts <- NULL
pathlib <- NULL
pd      <- NULL
np      <- NULL

.onLoad <- function(libname, pkgname) {

    # install_on_travis()

    activate_gluonts()

    # PYTHON IMPORTS ----
    if (pkg.env$activated && check_python_dependencies()) {

        gluonts <<- reticulate::import("gluonts", delay_load = TRUE, convert = FALSE)
        pathlib <<- reticulate::import("pathlib", delay_load = TRUE, convert = FALSE)
        np      <<- reticulate::import("numpy", delay_load = TRUE, convert = FALSE)
        pd      <<- reticulate::import("pandas", delay_load = TRUE, convert = FALSE)

        # Python source files (inst/ folder)
        system.file("python", "prepare_data.py", package = "modeltime.gluonts") %>%
            reticulate::source_python()
    }

    # LOAD MODELS ----

    make_deep_ar()
    make_nbeats()

}

# UTILITIES ----

activate_gluonts <- function() {

    conda_envs_found <- nrow(pkg.env$conda_envs)

    if (is.null(conda_envs_found)) {
        # No conda???
        message("Error detecting Conda Python Environments with `reticulate::conda_list()`. Conda is required for 'modeltime.gluonts'. Try using `reticulate::conda_install()`.")
        pkg.env$activated <- FALSE

    }else if (conda_envs_found == 0) {
        message("Please use 'install_gluonts()' to set up the a conda environment named 'r-gluonts' before using modeltime.gluonts. You only need to do this once.")
        pkg.env$activated <- FALSE
    } else if (conda_envs_found > 1) {
        message("Multiple 'r-gluonts' python environments found.")
        print(pkg.env$conda_envs)

        message("\nUsing: ")
        pkg.env$conda_envs <- pkg.env$conda_envs %>% dplyr::slice(1)
        print(pkg.env$conda_envs)

        reticulate::use_condaenv(pkg.env$conda_envs$name, required = TRUE)
        pkg.env$activated <- TRUE
    } else {
        # message("here")
        # print(pkg.env$conda_envs$name)
        reticulate::use_condaenv(pkg.env$conda_envs$name, required = TRUE)
        pkg.env$activated <- TRUE
    }

}

check_python_dependencies <- function() {
    all(
        reticulate::py_module_available("numpy"),
        reticulate::py_module_available("pandas"),
        reticulate::py_module_available("gluonts"),
        reticulate::py_module_available("mxnet"),
        reticulate::py_module_available("pathlib")
    )
}

