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

# Upgrade pip and setuptools without touching wheel
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

# Create rsession.conf to prevent crashes
RUN echo "session-timeout-minutes=0" > /etc/rstudio/rsession.conf \
    && echo "session-disconnected-timeout-minutes=0" >> /etc/rstudio/rsession.conf \
    && echo "session-quit-child-processes-on-exit=0" >> /etc/rstudio/rsession.conf

# Set up RStudio user (already exists in rocker/verse)
RUN usermod -s /bin/bash rstudio \
    && echo "rstudio:rstudio" | chpasswd

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
