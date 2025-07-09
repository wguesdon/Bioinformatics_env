#!/usr/bin/env Rscript

# Script to install R packages with specific versions from r-packages.txt

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

# Install BiocManager first if it's in the list
bioc_idx <- which(sapply(packages_info, function(x) x$name == "BiocManager"))
if(length(bioc_idx) > 0) {
  bioc_info <- packages_info[[bioc_idx]]
  if(!is.null(bioc_info$version)) {
    install.packages("BiocManager", repos = "https://cran.r-project.org")
    if(packageVersion("BiocManager") != bioc_info$version) {
      install.packages("devtools", repos = "https://cran.r-project.org")
      devtools::install_version("BiocManager", version = bioc_info$version, repos = "https://cran.r-project.org")
    }
  }
  # Set Bioconductor version
  BiocManager::install(version = "3.20", ask = FALSE, update = FALSE)
  packages_info <- packages_info[-bioc_idx]
}

# Separate CRAN and Bioconductor packages
bioc_packages <- c("GenomicRanges", "GenomicFeatures", "Biostrings", "DESeq2", "edgeR", 
                   "limma", "ComplexHeatmap", "clusterProfiler", "org.Hs.eg.db", 
                   "org.Mm.eg.db", "AnnotationDbi", "biomaRt", "GenomicAlignments",
                   "Rsamtools", "rtracklayer", "VariantAnnotation", "enrichplot",
                   "pathview", "ReactomePA", "fgsea", "GSEABase", "DOSE",
                   "SingleCellExperiment", "scater", "scran", "methylKit",
                   "ChIPseeker", "DiffBind", "MAST", "zinbwave", "slingshot",
                   "destiny", "monocle3", "phyloseq")

cran_packages <- list()
bioc_packages_list <- list()

for(pkg_info in packages_info) {
  if(pkg_info$name %in% bioc_packages) {
    bioc_packages_list <- append(bioc_packages_list, list(pkg_info))
  } else {
    cran_packages <- append(cran_packages, list(pkg_info))
  }
}

# Install devtools for version-specific installations
if(!"devtools" %in% installed.packages()[,"Package"]) {
  install.packages("devtools", repos = "https://cran.r-project.org")
}

# Function to install package with specific version
install_versioned_package <- function(pkg_info, bioc = FALSE) {
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
      if(bioc) {
        BiocManager::install(pkg_name, ask = FALSE, update = FALSE)
      } else {
        install.packages(pkg_name, repos = "https://cran.r-project.org")
      }
    } else {
      # Check if correct version is already installed
      if(pkg_name %in% installed.packages()[,"Package"]) {
        current_version <- as.character(packageVersion(pkg_name))
        if(current_version == pkg_version) {
          cat(sprintf("  %s version %s already installed\n", pkg_name, pkg_version))
          return(TRUE)
        }
      }
      
      # Install specific version
      if(bioc) {
        BiocManager::install(pkg_name, version = pkg_version, ask = FALSE, update = FALSE)
      } else {
        devtools::install_version(pkg_name, version = pkg_version, repos = "https://cran.r-project.org")
      }
    }
    cat(sprintf("  Successfully installed %s\n", pkg_name))
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("  ERROR installing %s: %s\n", pkg_name, e$message))
    return(FALSE)
  })
}

# Install CRAN packages
cat("\n=== Installing CRAN packages ===\n")
for(pkg_info in cran_packages) {
  install_versioned_package(pkg_info, bioc = FALSE)
}

# Install Bioconductor packages
cat("\n=== Installing Bioconductor packages ===\n")
for(pkg_info in bioc_packages_list) {
  install_versioned_package(pkg_info, bioc = TRUE)
}

# Special handling for Seurat (often requires specific installation)
seurat_idx <- which(sapply(packages_info, function(x) x$name == "Seurat"))
if(length(seurat_idx) > 0) {
  cat("\n=== Installing Seurat ===\n")
  if(!"Seurat" %in% installed.packages()[,"Package"]) {
    install.packages("Seurat", repos = "https://cran.r-project.org")
  }
}

cat("\n=== Package installation complete ===\n")

# Verify installations
cat("\n=== Verifying installed packages ===\n")
installed_pkgs <- installed.packages()[,"Package"]
all_packages <- c(sapply(cran_packages, function(x) x$name), 
                  sapply(bioc_packages_list, function(x) x$name))

missing_pkgs <- setdiff(all_packages, installed_pkgs)
if(length(missing_pkgs) > 0) {
  cat("WARNING: The following packages could not be installed:\n")
  cat(paste("  -", missing_pkgs), sep = "\n")
} else {
  cat("All packages successfully installed!\n")
}