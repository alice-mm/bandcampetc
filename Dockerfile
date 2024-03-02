FROM debian:11

RUN apt-get update && apt-get -y install \
    bash locales file mawk \
    eyed3 flac ffmpeg \
    rsync unzip \
    imagemagick \
    jq

RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY bin /bc/bin
COPY lib /bc/lib
COPY config /bc/config
COPY run_tests.sh /bc/run_tests.sh
COPY test_scripts /bc/test_scripts
COPY it /bc/it
