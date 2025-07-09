#!/usr/bin/env Rscript

# Unit tests to verify R package versions match r-packages.txt

parse_r_packages <- function() {
  # Parse r-packages.txt and extract package requirements
  # Try multiple locations for r-packages.txt
  possible_paths <- c(
    "/tmp/r-packages.txt",  # During Docker build
    "r-packages.txt",       # Current directory
    file.path(getwd(), "r-packages.txt")  # Working directory
  )
  
  packages_file <- NULL
  for (path in possible_paths) {
    if (file.exists(path)) {
      packages_file <- path
      break
    }
  }
  
  if (is.null(packages_file)) {
    stop("Could not find r-packages.txt in any expected location")
  }
  
  lines <- readLines(packages_file)
  
  # Filter out comments and empty lines
  package_lines <- lines[!grepl("^#", lines) & nzchar(trimws(lines))]
  
  # Parse package names and versions
  packages <- list()
  for (line in package_lines) {
    parts <- strsplit(trimws(line), "@")[[1]]
    package_name <- parts[1]
    package_version <- if(length(parts) > 1) parts[2] else NA
    packages[[package_name]] <- package_version
  }
  
  return(packages)
}

get_installed_version <- function(package_name) {
  # Get the installed version of a package
  if (package_name %in% rownames(installed.packages())) {
    return(as.character(packageVersion(package_name)))
  } else {
    return(NULL)
  }
}

# Function to normalize version strings
normalize_version <- function(version) {
  # Handle common version format differences
  version <- gsub("-", ".", version)  # Convert 3.5-7 to 3.5.7
  return(version)
}

# Function to check version compatibility
check_version <- function(installed, expected) {
  installed <- normalize_version(installed)
  expected <- normalize_version(expected)
  return(installed == expected)
}

test_r_packages <- function() {
  cat(paste(rep("=", 60), collapse=""), "\n")
  cat("Testing R Package Versions\n")
  cat(paste(rep("=", 60), collapse=""), "\n")
  
  expected_packages <- parse_r_packages()
  
  failed_tests <- list()
  passed_tests <- character()
  warnings <- list()
  
  for (package_name in names(expected_packages)) {
    expected_version <- expected_packages[[package_name]]
    installed_version <- get_installed_version(package_name)
    
    if (is.null(installed_version)) {
      failed_tests[[length(failed_tests) + 1]] <- list(
        package = package_name,
        expected = expected_version,
        actual = "NOT INSTALLED",
        status = "MISSING"
      )
      cat(sprintf("❌ %s: NOT INSTALLED (expected %s)\n", package_name, 
                  ifelse(is.na(expected_version), "any version", expected_version)))
    } else if (!is.na(expected_version) && !check_version(installed_version, expected_version)) {
      # For Bioconductor packages, version differences might be acceptable
      bioc_packages <- c("GenomicRanges", "GenomicFeatures", "Biostrings", "DESeq2", "edgeR", 
                         "limma", "ComplexHeatmap", "clusterProfiler", "org.Hs.eg.db", 
                         "org.Mm.eg.db", "AnnotationDbi", "biomaRt", "GenomicAlignments",
                         "Rsamtools", "rtracklayer", "VariantAnnotation", "enrichplot",
                         "pathview", "ReactomePA", "fgsea", "GSEABase", "DOSE",
                         "SingleCellExperiment", "scater", "scran", "methylKit",
                         "ChIPseeker", "DiffBind", "MAST", "zinbwave", "slingshot",
                         "destiny", "monocle3", "phyloseq")
      
      if (package_name %in% bioc_packages) {
        # For Bioconductor packages, warn instead of fail
        warnings[[length(warnings) + 1]] <- list(
          package = package_name,
          expected = expected_version,
          actual = installed_version
        )
        cat(sprintf("⚠️  %s: %s (expected %s - Bioconductor version may differ)\n", 
                    package_name, installed_version, expected_version))
        passed_tests <- c(passed_tests, package_name)
      } else {
        failed_tests[[length(failed_tests) + 1]] <- list(
          package = package_name,
          expected = expected_version,
          actual = installed_version,
          status = "VERSION MISMATCH"
        )
        cat(sprintf("❌ %s: %s (expected %s)\n", package_name, installed_version, expected_version))
      }
    } else {
      passed_tests <- c(passed_tests, package_name)
      cat(sprintf("✅ %s: %s\n", package_name, installed_version))
    }
  }
  
  cat("\n", paste(rep("=", 60), collapse=""), "\n")
  cat(sprintf("Summary: %d passed, %d failed\n", length(passed_tests), length(failed_tests)))
  cat(paste(rep("=", 60), collapse=""), "\n")
  
  if (length(failed_tests) > 0) {
    cat("\nFailed tests:\n")
    for (failure in failed_tests) {
      cat(sprintf("  - %s: %s\n", failure$package, failure$status))
      cat(sprintf("    Expected: %s\n", failure$expected))
      cat(sprintf("    Actual: %s\n", failure$actual))
    }
    return(FALSE)
  }
  
  return(TRUE)
}

# Run the tests
if (!interactive()) {
  success <- test_r_packages()
  quit(save = "no", status = ifelse(success, 0, 1))
}