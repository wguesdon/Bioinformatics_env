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
      
      # For CRAN packages, we'll install the latest version if exact version fails
      # This is because many specified versions might not be available
      tryCatch({
        remotes::install_version(pkg_name, version = pkg_version, 
                                repos = "https://cran.r-project.org",
                                upgrade = "never")
      }, error = function(e) {
        cat(sprintf("  Exact version %s not available, installing latest...\n", pkg_version))
        install.packages(pkg_name, repos = "https://cran.r-project.org")
      })
    }
    cat(sprintf("  Successfully installed %s\n", pkg_name))
  }, error = function(e) {
    cat(sprintf("  ERROR installing %s: %s\n", pkg_name, e$message))
  })
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
} else {
  cat("All packages successfully installed!\n")
}