# ds-central

To Build

sudo docker build -t ds-central .


To Run

sudo docker run -v '/DiscoDatos/Data Science/docker_polynote_jupyer_ds/WorkSpace':/WorkSpace -p 8899:8899 -p 8889:8888 -p 2638:2638 -p 1820:1820 ds-central
