###################################################################
# Should be able to run the notebooks without configs utilising this Dockerfile
FROM rocker/tidyverse:latest

# Set environment variables for Miniconda
ENV MINICONDA_VERSION=py310_23.5.2-0 \
    MINICONDA_PATH=/opt/miniconda \
    PATH=/opt/miniconda/bin:$PATH

# Install dependencies, download Miniconda, and set up
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget ca-certificates curl bzip2 libglib2.0-0 libxext6 libsm6 libxrender1 \
        libarchive-dev libstdc++6 sudo libssl-dev \
    && wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p ${MINICONDA_PATH} \
    && rm /tmp/miniconda.sh \
    && conda update -n base -c defaults conda -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create the r-reticulate Conda environment with Python 3.10
RUN conda create --name r-reticulate python=3.10 -y \
    && conda install --name r-reticulate -y tensorflow keras numpy pandas matplotlib \
    && conda clean -a

# Activate the r-reticulate environment by default
ENV CONDA_DEFAULT_ENV=r-reticulate
RUN echo "source activate r-reticulate" > ~/.bashrc

# Install the keras3 R package
RUN R -e "install.packages('keras3', repos='https://cloud.r-project.org')"

# Run keras3::install_keras(backend = 'tensorflow') to set up the backend
RUN R -e "keras3::install_keras(backend = 'tensorflow')"

# Install additional dependencies
RUN R -e "install.packages('tfdatasets', repos='https://cloud.r-project.org')"

# Install reticulate R package and use the conda environment
RUN R -e "install.packages('reticulate', repos='https://cloud.r-project.org')"

# Use the conda environment 'r-reticulate' and install Keras and TensorFlow via reticulate
RUN R -e "library(reticulate); use_condaenv('r-reticulate'); py_install('keras'); py_install('tensorflow')"

# Set the default password for rstudio (the user should be 'rstudio' by default in this image)
ENV PASSWORD=password
RUN echo "rstudio:${PASSWORD}" | chpasswd

# Expose a port for RStudio if using rocker/tidyverse
EXPOSE 8787
