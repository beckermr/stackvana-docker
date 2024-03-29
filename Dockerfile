FROM ubuntu:bionic

COPY CONDA_FORGE_LICENSE /opt/CONDA_FORGE_LICENSE

ARG MINIFORGE_VERSION=4.10.3-7
ARG TINI_VERSION=v0.18.0

ARG CONDA_DIR=/opt/conda
ARG LANG=C.UTF-8
ARG LC_ALL=C.UTF-8
ARG PATH=${CONDA_DIR}/bin:${PATH}
ARG MAMBA_NO_BANNER=1

SHELL ["/bin/bash", "-c"]

COPY activate /usr/local/share/stackvana-activate.sh

# Activate base by default when running as any *non-root* user as well
# Good security practice requires running most workloads as non-root
# This makes sure any non-root users created also have base activated
# for their interactive shells.
RUN echo ". /usr/local/share/stackvana-activate.sh" >> /etc/skel/.bashrc && \
    cat /etc/skel/.bashrc

# Activate base by default when running as root as well
# The root user is already created, so won't pick up changes to /etc/skel
RUN echo ". /usr/local/share/stackvana-activate.sh" >> ~/.bashrc && \
    cat ~/.bashrc


# make sure the install below is not cached by docker
ADD https://loripsum.net/api /opt/docker/etc/gibberish

# Install just enough for conda to work
RUN apt-get update > /dev/null && \
    apt-get install --no-install-recommends --yes \
        wget bzip2 ca-certificates \
        git > /dev/null && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Keep $HOME clean (no .wget-hsts file), since HSTS isn't useful in this context
RUN wget --no-hsts --quiet https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -O /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# 1. Install miniforge from GitHub releases
# 2. Apply some cleanup tips from https://jcrist.github.io/conda-docker-tips.html
#    Particularly, we remove pyc and a files. The default install has no js, we can skip that
RUN wget --no-hsts --quiet https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Mambaforge-${MINIFORGE_VERSION}-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh && \
    source ${CONDA_DIR}/etc/profile.d/conda.sh && \
    conda activate base && \
    conda config --set show_channel_urls True  && \
    conda config --add channels defaults  && \
    conda config --add channels conda-forge  && \
    conda config --show-sources  && \
    conda config --set always_yes yes && \
    conda info && \
    mamba install --quiet --yes  python=3.8 && \
    mamba install --yes \
      lsstdesc-weaklensingdeblending \
      flake8 \
      pytest \
      fitsio \
      ngmix \
      treecorr \
      tini \
      scikit-learn \
      galsim \
      meds \
      numba \
      esutil \
      stackvana=0 \
      && \
    conda clean --all --yes && \
    find ${CONDA_DIR} -follow -type f -name '*.a' -delete && \
    find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete && \
    conda clean -afy

CMD [ "/bin/bash" ]
