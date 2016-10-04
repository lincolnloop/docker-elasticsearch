FROM debian:jessie

ENV ES_VERSION 2.4.1
ENV SHA1_SUM 575a7ee8cb62f6b96fde9dc465b3c4fe0565fb07
ENV AWS_PLUGIN_VERSION 2.4.0

# via https://github.com/William-Yeh/docker-java7/blob/master/Dockerfile
RUN \
    echo "===> add webupd8 repository..."  && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886  && \
    apt-get update  && \
    \
    \
    echo "===> install Java"  && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
    DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default  && \
    \
    \
    echo "===> clean up..."  && \
    rm -rf /var/cache/oracle-jdk8-installer  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*

# Install Elasticsearch.
RUN \
  cd / && \
  wget --quiet https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/${ES_VERSION}/elasticsearch-${ES_VERSION}.deb && \
  echo "${SHA1_SUM}  elasticsearch-${ES_VERSION}.deb" > es.sha1 && sha1sum --check es.sha1 && \
  dpkg -i elasticsearch-${ES_VERSION}.deb && \
  rm elasticsearch-${ES_VERSION}.deb && \
  mkdir /data && chown elasticsearch /data

RUN /usr/share/elasticsearch/bin/plugin install --batch cloud-aws

# Define mountable directories.
VOLUME ["/data"]

# Mount elasticsearch.yml config
ADD config/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

# Define working directory.
WORKDIR /data
USER elasticsearch
# Define default command.
CMD ["/usr/share/elasticsearch/bin/elasticsearch", "--default.path.conf=/etc/elasticsearch"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300
