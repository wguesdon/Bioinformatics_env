# Configuration for package testing
# Defines which packages are critical and which can have flexible versions

# Packages where exact version match is critical
critical_packages <- c(
  "tidyverse"   # Major framework
  # Note: Removed Seurat, DESeq2, edgeR, limma as they often have newer versions
  # due to Bioconductor release cycles
)

# Packages where minor version differences are acceptable
flexible_packages <- c(
  "BiocManager", "viridis", "patchwork", "data.table", "knitr", 
  "rmarkdown", "plotly", "ggrepel", "performance", "xgboost", 
  "igraph", "lme4", "scales", "cowplot", "nlme", "survival",
  "vegan", "ade4", "RColorBrewer"
)

# Packages that are optional (nice to have but not critical)
optional_packages <- c(
  "ggstatsplot",  # Can be heavy on dependencies
  "monocle3"      # Often has installation issues
)

# Add major bioinformatics packages to flexible list since versions vary with Bioconductor
flexible_packages <- c(flexible_packages, 
  "Seurat", "DESeq2", "edgeR", "limma"
)

# Function to check if version difference is acceptable
is_version_acceptable <- function(package_name, installed_version, expected_version) {
  # If no expected version specified, any version is OK
  if (is.na(expected_version)) {
    return(TRUE)
  }
  
  # Normalize versions
  installed_norm <- normalize_version(installed_version)
  expected_norm <- normalize_version(expected_version)
  
  # Exact match
  if (installed_norm == expected_norm) {
    return(TRUE)
  }
  
  # For flexible packages, check if installed version is newer
  if (package_name %in% flexible_packages) {
    # Compare versions
    installed_parts <- as.numeric(strsplit(installed_norm, "\\.")[[1]])
    expected_parts <- as.numeric(strsplit(expected_norm, "\\.")[[1]])
    
    # Pad with zeros if needed
    max_len <- max(length(installed_parts), length(expected_parts))
    installed_parts <- c(installed_parts, rep(0, max_len - length(installed_parts)))
    expected_parts <- c(expected_parts, rep(0, max_len - length(expected_parts)))
    
    # Check if installed version is newer or equal
    for (i in 1:max_len) {
      if (installed_parts[i] > expected_parts[i]) {
        return(TRUE)  # Newer version is OK
      } else if (installed_parts[i] < expected_parts[i]) {
        return(FALSE)  # Older version is not OK
      }
    }
    return(TRUE)  # Same version
  }
  
  return(FALSE)
}

# Function to get test severity
get_test_severity <- function(package_name) {
  if (package_name %in% optional_packages) {
    return("optional")
  } else if (package_name %in% critical_packages) {
    return("critical")
  } else if (package_name %in% flexible_packages) {
    return("flexible")
  } else {
    # Default based on package type
    bioc_packages <- c("GenomicRanges", "GenomicFeatures", "Biostrings", 
                       "ComplexHeatmap", "clusterProfiler", "org.Hs.eg.db", 
                       "org.Mm.eg.db", "AnnotationDbi", "biomaRt", "GenomicAlignments",
                       "Rsamtools", "rtracklayer", "VariantAnnotation", "enrichplot",
                       "pathview", "ReactomePA", "fgsea", "GSEABase", "DOSE",
                       "SingleCellExperiment", "scater", "scran", "methylKit",
                       "ChIPseeker", "DiffBind", "MAST", "zinbwave", "slingshot",
                       "destiny", "phyloseq")
    
    if (package_name %in% bioc_packages) {
      return("bioconductor")  # Version flexibility for Bioc packages
    }
    return("standard")
  }
}