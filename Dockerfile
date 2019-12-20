FROM ubuntu:latest

# Identify the maintainer of an image
LABEL maintainer="Juan Carlos Vázquez <juancgvazquez@gmail.com>"

# copy files from local to container
USER root
COPY . /opt/setup_files
WORKDIR /opt

## mention version numbers
ARG POLYNOTE_VERSION="0.2.12"
ARG SCALA_VERSION="2.11"
ARG DIST_TAR="polynote-dist.tar.gz"

# install packages
RUN apt-get clean
RUN apt-get update && apt-get install -y \
  wget \
  openjdk-8-jdk \
  python3 \
  python3-dev \
  python3-pip \
  python-setuptools \
  build-essential \
  git \
  vim \
  nano \
  scala \
  cmake \
  gfortran \
  curl \
  graphicsmagick \
  libgraphicsmagick1-dev \
  libatlas-base-dev \
  libavcodec-dev \
  libavformat-dev \
  libgtk2.0-dev \
  libjpeg-dev \
  liblapack-dev \
  libswscale-dev \
  pkg-config \
  software-properties-common \
  zip \
  freetds-dev \
  freetds-bin \
  unixodbc-dev \
  tdsodbc \
  && apt-get clean && rm -rf /tmp/* /var/tmp/*


## download polynote
RUN if test "${SCALA_VERSION}" = "2.12"; then export DIST_TAR="polynote-dist-2.12.tar.gz"; fi && \
  wget -q https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/$DIST_TAR && \
  tar xfzp $DIST_TAR && \
  echo "DIST_TAR=$DIST_TAR" && \
  rm $DIST_TAR

# download spark
RUN wget -q https://www-us.apache.org/dist/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz && \
  tar xfz spark-2.4.4-bin-hadoop2.7.tgz && \
  rm spark-2.4.4-bin-hadoop2.7.tgz

# set environmental variables
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV SPARK_HOME=/opt/spark-2.4.4-bin-hadoop2.7
ENV PATH="$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin"

RUN python3 -m pip install --upgrade pip
RUN pip install -r /opt/setup_files/requirements.txt

RUN cd ~ && \
    mkdir -p dlib && \
    git clone -b 'v19.9' --single-branch https://github.com/davisking/dlib.git dlib/ && \
    cd  dlib/ && \
    python3 setup.py install --yes USE_AVX_INSTRUCTIONS

# copy config.yml file to polynote directory
RUN cp /opt/setup_files/config/config.yml /opt/polynote/

# create jupyter config files it will be created in home(~/) folder
RUN jupyter notebook --generate-config
RUN mkdir /etc/jupyter
RUN mkdir /.local
RUN cp /opt/setup_files/config/jupyter_notebook_config.py /etc/jupyter/
# Install NB extensions
RUN pip3 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master && \
    jupyter contrib nbextension install --system
RUN pip3 install jupyter_nbextensions_configurator
RUN jupyter nbextensions_configurator enable
RUN mkdir /WorkSpace
RUN mkdir /home/jupyteruser
RUN useradd --uid 1001 --gid 0 -m --home-dir /home/jupyteruser jupyteruser

RUN chown -R 1001 /opt/setup_files && \
    chgrp -R 0 /opt/setup_files && \
    chmod -R g+w /opt/setup_files && \
    chown -R 1001 /home/jupyteruser && \
    chgrp -R 0 /home/jupyteruser && \
    chmod -R g+w /home/jupyteruser && \
    chown -R 1001 /WorkSpace && \
    chgrp -R 0 /WorkSpace && \
    chmod -R g+w /WorkSpace && \
    chown -R 1001 /usr && \
    chgrp -R 0 /usr && \
    chmod -R g+w /usr      

USER 1001

WORKDIR /WorkSpace
EXPOSE 1820
EXPOSE 2638
EXPOSE 8899
EXPOSE 8888
CMD /bin/sh /opt/setup_files/command.sh

