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

# Copy R packages list and installation script
COPY r-packages.txt /tmp/r-packages.txt
COPY install_r_packages_v2.R /tmp/install_r_packages_v2.R

# Install R packages with specific versions from r-packages.txt
RUN Rscript /tmp/install_r_packages_v2.R

# Copy test files to workspace
COPY test_python_packages.py /workspace/test_python_packages.py
COPY test_r_packages_flexible.R /workspace/test_r_packages_flexible.R
COPY package_test_config.R /workspace/package_test_config.R
COPY test_packages.sh /workspace/test_packages.sh
RUN chmod +x /workspace/test_packages.sh

# Also copy config files to workspace for tests after build
COPY pyproject.toml /workspace/pyproject.toml
COPY r-packages.txt /workspace/r-packages.txt

# Run package verification tests (using flexible R test)
RUN cd /workspace && sed -i 's/test_r_packages.R/test_r_packages_flexible.R/g' test_packages.sh && ./test_packages.sh

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
