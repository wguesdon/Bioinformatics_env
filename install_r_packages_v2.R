#!/usr/bin/env Rscript

# Improved script to install R packages with specific versions from r-packages.txt

# Read the packages file
packages_file <- "/tmp/r-packages.txt"
lines <- readLines(packages_file)

# Filter out comments and empty lines
package_lines <- lines[!grepl("^#", lines) & nzchar(trimws(lines))]

# Parse package names and versions
packages_info <- lapply(package_lines, function(line) {
  parts <- strsplit(trimws(line), "@")[[1]]
  list(name = parts[1], version = if(length(parts) > 1) parts[2] else NULL)
})

# Install BiocManager first
bioc_idx <- which(sapply(packages_info, function(x) x$name == "BiocManager"))
if(length(bioc_idx) > 0) {
  cat("Installing BiocManager...\n")
  install.packages("BiocManager", repos = "https://cran.r-project.org")
  packages_info <- packages_info[-bioc_idx]
}

# Set Bioconductor version
cat("Setting Bioconductor version to 3.20...\n")
BiocManager::install(version = "3.20", ask = FALSE, update = FALSE)

# Pre-install critical packages to avoid dependency cascade issues.
# scales 1.4.0 is needed by newer packages but ggplot2 must stay at 3.5.x
# for Bioconductor 3.20 compatibility (ggtree, enrichplot, etc.)
cat("Pre-installing scales and pinning ggplot2 to prevent upgrade...\n")
remotes_installed <- "remotes" %in% installed.packages()[,"Package"]
if(!remotes_installed) install.packages("remotes", repos = "https://cran.r-project.org")
remotes::install_version("scales", version = "1.4.0",
                         repos = "https://cran.r-project.org", upgrade = "never")
remotes::install_version("ggplot2", version = "3.5.1",
                         repos = "https://cran.r-project.org", upgrade = "never")

# List of known Bioconductor packages
bioc_packages <- c("GenomicRanges", "GenomicFeatures", "Biostrings", "DESeq2", "edgeR", 
                   "limma", "ComplexHeatmap", "clusterProfiler", "org.Hs.eg.db", 
                   "org.Mm.eg.db", "AnnotationDbi", "biomaRt", "GenomicAlignments",
                   "Rsamtools", "rtracklayer", "VariantAnnotation", "enrichplot",
                   "pathview", "ReactomePA", "fgsea", "GSEABase", "DOSE",
                   "SingleCellExperiment", "scater", "scran", "methylKit",
                   "ChIPseeker", "DiffBind", "MAST", "zinbwave", "slingshot",
                   "destiny", "monocle3", "phyloseq")

# Separate packages
cran_packages <- list()
bioc_packages_list <- list()

for(pkg_info in packages_info) {
  if(pkg_info$name %in% bioc_packages) {
    bioc_packages_list <- append(bioc_packages_list, list(pkg_info))
  } else {
    cran_packages <- append(cran_packages, list(pkg_info))
  }
}

# Install remotes for version control
if(!"remotes" %in% installed.packages()[,"Package"]) {
  install.packages("remotes", repos = "https://cran.r-project.org")
}

# Track version mismatches
version_warnings <- character(0)

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

# Install CRAN packages
cat("\n=== Installing CRAN packages ===\n")
for(pkg_info in cran_packages) {
  pkg_name <- pkg_info$name
  pkg_version <- pkg_info$version
  
  cat(sprintf("Installing %s", pkg_name))
  if(!is.null(pkg_version)) {
    cat(sprintf(" version %s", pkg_version))
  }
  cat("...\n")
  
  tryCatch({
    if(is.null(pkg_version)) {
      # Install latest version
      install.packages(pkg_name, repos = "https://cran.r-project.org")
    } else {
      # Check if correct version is already installed
      if(pkg_name %in% installed.packages()[,"Package"]) {
        current_version <- as.character(packageVersion(pkg_name))
        if(check_version(current_version, pkg_version)) {
          cat(sprintf("  %s version %s already installed\n", pkg_name, current_version))
          next
        }
      }
      
      tryCatch({
        remotes::install_version(pkg_name, version = pkg_version,
                                repos = "https://cran.r-project.org",
                                upgrade = "never")
      }, error = function(e) {
        cat(sprintf("  WARNING: Exact version %s not available for %s, installing latest\n", pkg_version, pkg_name))
        install.packages(pkg_name, repos = "https://cran.r-project.org")
        installed_ver <- tryCatch(as.character(packageVersion(pkg_name)), error = function(e2) "unknown")
        msg <- sprintf("%s: requested %s, installed %s", pkg_name, pkg_version, installed_ver)
        version_warnings <<- c(version_warnings, msg)
      })
    }
    cat(sprintf("  Successfully installed %s\n", pkg_name))
  }, error = function(e) {
    cat(sprintf("  ERROR installing %s: %s\n", pkg_name, e$message))
  })
}

# Restore ggplot2 3.5.1 if it was upgraded during CRAN installs.
# ggplot2 4.x breaks Bioconductor 3.20 packages like ggtree and enrichplot.
current_ggplot2 <- tryCatch(as.character(packageVersion("ggplot2")), error = function(e) "unknown")
if(current_ggplot2 != "3.5.1") {
  cat(sprintf("Restoring ggplot2 3.5.1 (was upgraded to %s)...\n", current_ggplot2))
  remotes::install_version("ggplot2", version = "3.5.1",
                           repos = "https://cran.r-project.org",
                           upgrade = "never", force = TRUE)
}

# Install Bioconductor packages
cat("\n=== Installing Bioconductor packages ===\n")
# For Bioconductor packages, we typically can't specify exact versions easily
# So we'll install from the set Bioconductor version (3.20)
if(length(bioc_packages_list) > 0) {
  bioc_names <- sapply(bioc_packages_list, function(x) x$name)
  
  # Install in batches to avoid dependency issues
  batch_size <- 5
  for(i in seq(1, length(bioc_names), by = batch_size)) {
    batch <- bioc_names[i:min(i + batch_size - 1, length(bioc_names))]
    cat(sprintf("Installing Bioconductor batch: %s\n", paste(batch, collapse = ", ")))
    
    tryCatch({
      BiocManager::install(batch, ask = FALSE, update = FALSE, force = TRUE)
    }, error = function(e) {
      # Try installing one by one if batch fails
      for(pkg in batch) {
        cat(sprintf("  Trying individual install for %s...\n", pkg))
        tryCatch({
          BiocManager::install(pkg, ask = FALSE, update = FALSE, force = TRUE)
        }, error = function(e2) {
          cat(sprintf("  ERROR installing %s: %s\n", pkg, e2$message))
        })
      }
    })
  }
}

# Special packages that might need special handling
special_packages <- list(
  list(name = "Seurat", install_cmd = function() {
    install.packages("Seurat", repos = "https://cran.r-project.org")
  }),
  list(name = "monocle3", install_cmd = function() {
    BiocManager::install("cole-trapnell-lab/monocle3")
  }),
  list(name = "ggstatsplot", install_cmd = function() {
    install.packages("ggstatsplot", repos = "https://cran.r-project.org")
  }),
  list(name = "xgboost", install_cmd = function() {
    install.packages("xgboost", repos = "https://cran.r-project.org")
  }),
  list(name = "phyloseq", install_cmd = function() {
    BiocManager::install("phyloseq", ask = FALSE, update = FALSE)
  })
)

cat("\n=== Installing special packages ===\n")
for(special in special_packages) {
  if(special$name %in% sapply(packages_info, function(x) x$name)) {
    cat(sprintf("Installing %s...\n", special$name))
    tryCatch({
      special$install_cmd()
      cat(sprintf("  Successfully installed %s\n", special$name))
    }, error = function(e) {
      cat(sprintf("  ERROR installing %s: %s\n", special$name, e$message))
    })
  }
}

cat("\n=== Package installation complete ===\n")

# Verify installations
cat("\n=== Verifying installed packages ===\n")
installed_pkgs <- installed.packages()[,"Package"]
all_packages <- sapply(packages_info, function(x) x$name)

missing_pkgs <- setdiff(all_packages, installed_pkgs)
if(length(missing_pkgs) > 0) {
  cat("WARNING: The following packages could not be installed:\n")
  cat(paste("  -", missing_pkgs), sep = "\n")
  cat("\n")
}

if(length(version_warnings) > 0) {
  cat(sprintf("\nWARNING: %d package(s) installed with different versions than requested:\n", length(version_warnings)))
  cat(paste("  -", version_warnings), sep = "\n")
  cat("\nUpdate r-packages.txt to match the installed versions for reproducibility.\n")
}

if(length(missing_pkgs) == 0 && length(version_warnings) == 0) {
  cat("All packages successfully installed with correct versions!\n")
} else if(length(missing_pkgs) == 0) {
  cat("\nAll packages installed (some with version differences).\n")
}