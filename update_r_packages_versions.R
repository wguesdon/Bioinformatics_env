#!/usr/bin/env Rscript

# Script to update r-packages.txt with actual installed versions

# Read the original packages file to maintain order and comments
packages_file <- "r-packages.txt"
output_file <- "r-packages-updated.txt"

if (!file.exists(packages_file)) {
  stop("r-packages.txt not found!")
}

# Read all lines including comments
all_lines <- readLines(packages_file)

# Get list of expected packages
package_lines <- all_lines[!grepl("^#", all_lines) & nzchar(trimws(all_lines))]
expected_packages <- sapply(package_lines, function(line) {
  strsplit(trimws(line), "@")[[1]][1]
})

# Get installed versions
get_installed_version <- function(pkg_name) {
  if (pkg_name %in% rownames(installed.packages())) {
    return(as.character(packageVersion(pkg_name)))
  } else {
    return(NULL)
  }
}

# Process each line
updated_lines <- character()
for (line in all_lines) {
  if (grepl("^#", line) || !nzchar(trimws(line))) {
    # Keep comments and empty lines as-is
    updated_lines <- c(updated_lines, line)
  } else {
    # Extract package name
    pkg_name <- strsplit(trimws(line), "@")[[1]][1]
    installed_version <- get_installed_version(pkg_name)
    
    if (!is.null(installed_version)) {
      # Update with installed version
      updated_line <- sprintf("%s@%s", pkg_name, installed_version)
      updated_lines <- c(updated_lines, updated_line)
      
      # Check if version changed
      original_version <- if (grepl("@", line)) {
        strsplit(trimws(line), "@")[[1]][2]
      } else {
        "no version specified"
      }
      
      if (original_version != installed_version) {
        cat(sprintf("Updated %s: %s -> %s\n", pkg_name, original_version, installed_version))
      }
    } else {
      # Package not installed, comment it out
      updated_lines <- c(updated_lines, sprintf("# %s - NOT INSTALLED", line))
      cat(sprintf("WARNING: %s not installed, commenting out\n", pkg_name))
    }
  }
}

# Write updated file
writeLines(updated_lines, output_file)
cat(sprintf("\nUpdated package list written to: %s\n", output_file))

# Show summary
total_packages <- length(expected_packages)
installed_packages <- sum(sapply(expected_packages, function(pkg) {
  !is.null(get_installed_version(pkg))
}))

cat(sprintf("\nSummary: %d/%d packages installed\n", installed_packages, total_packages))

# Also create a simple comparison report
cat("\n=== Version Comparison ===\n")
for (pkg_name in expected_packages) {
  original_line <- package_lines[sapply(package_lines, function(line) {
    strsplit(trimws(line), "@")[[1]][1] == pkg_name
  })]
  
  original_version <- if (grepl("@", original_line)) {
    strsplit(trimws(original_line), "@")[[1]][2]
  } else {
    "not specified"
  }
  
  installed_version <- get_installed_version(pkg_name)
  
  if (is.null(installed_version)) {
    cat(sprintf("%-25s: %s -> NOT INSTALLED\n", pkg_name, original_version))
  } else if (original_version != installed_version) {
    cat(sprintf("%-25s: %s -> %s\n", pkg_name, original_version, installed_version))
  }
}