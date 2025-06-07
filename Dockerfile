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
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools without touching wheel
# Use --ignore-installed to bypass system package conflicts
RUN pip3 install --upgrade --ignore-installed pip setuptools --break-system-packages

# Install Python packages in stages to avoid conflicts
RUN pip3 install --no-cache-dir --break-system-packages \
    jupyter jupyterlab

RUN pip3 install --no-cache-dir --break-system-packages \
    numpy pandas matplotlib seaborn scipy

RUN pip3 install --no-cache-dir --break-system-packages \
    scikit-learn plotly bokeh altair ipywidgets

RUN pip3 install --no-cache-dir --break-system-packages \
    rpy2

# Install Quarto
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb \
    && dpkg -i quarto-linux-amd64.deb \
    && rm quarto-linux-amd64.deb

# Install VSCode Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install R/Bioconductor packages
RUN R -e "install.packages(c('BiocManager', 'IRkernel', 'reticulate'))" \
    && R -e "BiocManager::install(c( \
        'GenomicRanges', 'GenomicFeatures', 'Biostrings', \
        'DESeq2', 'edgeR', 'limma', 'ComplexHeatmap', \
        'clusterProfiler', 'org.Hs.eg.db', \
        'ggplot2', 'dplyr', 'tidyr', 'readr', \
        'plotly', 'DT', 'pheatmap' \
    ))" \
    && R -e "IRkernel::installspec(user = FALSE)"

# Configure services
RUN mkdir -p /root/.jupyter \
    && echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

RUN echo "server-daemonize=0" >> /etc/rstudio/rserver.conf \
    && echo "www-port=8787" >> /etc/rstudio/rserver.conf \
    && echo "auth-none=1" >> /etc/rstudio/rserver.conf

# Set password for existing rstudio user
RUN echo "rstudio:rstudio" | chpasswd

WORKDIR /workspace
EXPOSE 8787 8888 8080

# Start all services
CMD /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 & \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/workspace & \
    code-server --bind-addr 0.0.0.0:8080 --auth none /workspace & \
    wait
