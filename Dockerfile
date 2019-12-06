FROM ubuntu:latest

# Identify the maintainer of an image
LABEL maintainer="Juan Carlos Vázquez <juancgvazquez@gmail.com>"

# copy files from local to container
COPY . /opt/setup_files
WORKDIR /opt

# mention version numbers
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


# download polynote
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

# install dlib
RUN cd ~ && \
    mkdir -p dlib && \
    git clone -b 'v19.9' --single-branch https://github.com/davisking/dlib.git dlib/ && \
    cd  dlib/ && \
    python3 setup.py install --yes USE_AVX_INSTRUCTIONS

# copy config.yml file to polynote directory
RUN cp /opt/setup_files/config/config.yml /opt/polynote/

# create jupyter config files it will be created in home(~/) folder
RUN jupyter notebook --generate-config
RUN cp /opt/setup_files/config/jupyter_notebook_config.py ~/.jupyter/
# Install NB extensions
RUN pip3 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master && \
    jupyter contrib nbextension install --system
RUN pip3 install jupyter_nbextensions_configurator
RUN jupyter nbextensions_configurator enable
WORKDIR /WorkSpace
EXPOSE 1820
EXPOSE 2638
EXPOSE 8899
EXPOSE 8888
CMD /bin/sh /opt/setup_files/command.sh

