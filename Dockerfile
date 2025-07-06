# Bioinformatics Docker Environment
# R/Bioconductor + Python + RStudio + Jupyter + VSCode + Quarto

FROM rocker/verse:4.4.2

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl wget git vim \
    python3 python3-pip python3-dev python3-venv \
    build-essential \
    libssl-dev libffi-dev \
    libxml2-dev libxslt-dev \
    libcurl4-openssl-dev \
    nodejs npm \
    gdebi-core \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
# Using the standalone installer method
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

# Copy Python dependencies file
COPY pyproject.toml /tmp/pyproject.toml

# Check Python version and install packages using uv with the system Python
RUN python3 --version && \
    uv pip install --system --break-system-packages --python /usr/bin/python3 -r /tmp/pyproject.toml

# Install Quarto
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb \
    && dpkg -i quarto-linux-amd64.deb \
    && rm quarto-linux-amd64.deb

# Install VSCode Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Copy R packages list
COPY r-packages.txt /tmp/r-packages.txt

# Install specific version of BiocManager first
RUN R -e "install.packages('BiocManager', version='1.30.22', repos='https://cran.r-project.org')"

# Set Bioconductor version to 3.20 (compatible with R 4.4.2)
RUN R -e "BiocManager::install(version='3.20', ask=FALSE, update=FALSE)"

# Install base R packages with specific versions
RUN R -e "install.packages(c( \
    'IRkernel', 'reticulate', \
    'tidyverse', 'ggpubr', 'rstatix', 'FactoMineR', \
    'factoextra', 'corrplot', 'GGally', \
    'viridis', 'RColorBrewer', 'scales', \
    'gridExtra', 'patchwork', 'cowplot', \
    'data.table', 'janitor', 'skimr', \
    'survival', 'survminer', 'broom', \
    'knitr', 'rmarkdown', 'DT', 'plotly', \
    'pheatmap', 'VennDiagram', 'UpSetR' \
), repos='https://cran.r-project.org')"

# Install Bioconductor core packages
RUN R -e "BiocManager::install(c( \
    'GenomicRanges', 'GenomicFeatures', 'Biostrings', \
    'DESeq2', 'edgeR', 'limma', 'ComplexHeatmap', \
    'clusterProfiler', 'org.Hs.eg.db', 'org.Mm.eg.db', \
    'AnnotationDbi', 'biomaRt', 'GenomicAlignments', \
    'Rsamtools', 'rtracklayer', 'VariantAnnotation' \
), ask=FALSE, update=FALSE)"

# Install additional Bioconductor packages for various analyses
RUN R -e "BiocManager::install(c( \
    'enrichplot', 'pathview', 'ReactomePA', \
    'fgsea', 'GSEABase', 'DOSE', \
    'SingleCellExperiment', 'scater', 'scran', \
    'Seurat', 'monocle3', 'destiny', \
    'methylKit', 'ChIPseeker', 'DiffBind', \
    'MAST', 'zinbwave', 'slingshot' \
), ask=FALSE, update=FALSE)"

# Install additional useful packages for bioinformatics
RUN R -e "install.packages(c( \
    'ggsci', 'ggrepel', 'ggfortify', 'ggbeeswarm', \
    'ggridges', 'ggdendro', 'ggalluvial', \
    'performance', 'see', 'ggstatsplot', \
    'tidymodels', 'caret', 'glmnet', \
    'randomForest', 'xgboost', 'ranger', \
    'network', 'igraph', 'tidygraph', 'ggraph', \
    'lme4', 'nlme', 'emmeans', \
    'vegan', 'ade4', 'phyloseq' \
), repos='https://cran.r-project.org')"

# Install IRkernel for Jupyter
RUN R -e "IRkernel::installspec(user = FALSE)"

# Configure Jupyter
RUN mkdir -p /root/.jupyter \
    && echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

# Fix RStudio Server configuration
RUN mkdir -p /etc/rstudio \
    && echo "server-daemonize=0" > /etc/rstudio/rserver.conf \
    && echo "www-port=8787" >> /etc/rstudio/rserver.conf \
    && echo "www-frame-origin=any" >> /etc/rstudio/rserver.conf \
    && echo "server-app-armor-enabled=0" >> /etc/rstudio/rserver.conf

# Create rsession.conf to prevent crashes and set default directory
RUN echo "session-timeout-minutes=0" > /etc/rstudio/rsession.conf \
    && echo "session-disconnected-timeout-minutes=0" >> /etc/rstudio/rsession.conf \
    && echo "session-quit-child-processes-on-exit=0" >> /etc/rstudio/rsession.conf \
    && echo "session-default-working-dir=/workspace" >> /etc/rstudio/rsession.conf \
    && echo "session-default-new-project-dir=/workspace" >> /etc/rstudio/rsession.conf

# Set up RStudio user (already exists in rocker/verse)
RUN usermod -s /bin/bash rstudio

# Create necessary directories with proper permissions
RUN mkdir -p /home/rstudio/.rstudio \
    && chown -R rstudio:rstudio /home/rstudio

WORKDIR /workspace
EXPOSE 8787 8888 8080

# Create a startup script for better service management
RUN echo '#!/bin/bash\n\
echo "Starting services..."\n\
echo "Starting RStudio Server on port 8787..."\n\
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-app-armor-enabled=0 &\n\
echo "Starting Jupyter Lab on port 8888..."\n\
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/workspace &\n\
echo "Starting VSCode on port 8080..."\n\
code-server --bind-addr 0.0.0.0:8080 --auth none /workspace &\n\
echo "All services started!"\n\
wait' > /startup.sh && chmod +x /startup.sh

COPY startup_proper.sh /startup_proper.sh
RUN chmod +x /startup_proper.sh
CMD ["/startup_proper.sh"]
