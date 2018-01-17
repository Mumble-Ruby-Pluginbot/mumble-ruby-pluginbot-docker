FROM ubuntu

MAINTAINER Natenom <natenom@mailbox.org>
EXPOSE 7701

LABEL version="0.10.5"

ENV MUMBLE_HOST="m.natenom.com"
ENV MUMBLE_PORT="64738"
ENV MUMBLE_USERNAME="MRPB_Dockerized"
ENV MUMBLE_PASSWORD="supersecretpassword"
ENV MUMBLE_CHANNEL="Bottest"
ENV MUMBLE_BITRATE="72000"

RUN DEBIAN_FRONTEND=noninteractive apt-get update;\
    apt-get --allow-unauthenticated --no-install-recommends -qy install curl libyaml-dev git libopus-dev \
    build-essential zlib1g zlib1g-dev libssl-dev mpd mpc tmux \
    automake autoconf libtool libogg-dev psmisc util-linux libgmp3-dev \
    dialog unzip ca-certificates aria2 imagemagick libav-tools python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --quiet --disabled-password --uid 1000 --home /home/botmaster --shell /bin/bash botmaster

USER botmaster
WORKDIR /home/botmaster/

RUN mkdir ~/src
RUN mkdir ~/logs
RUN mkdir ~/temp
RUN mkdir -p ~/mpd1/playlists
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -L https://get.rvm.io | bash -s stable && /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm autolibs disable && rvm install ruby --latest && rvm --create use @bots"

WORKDIR /home/botmaster/src
RUN git clone https://github.com/dafoxia/mumble-ruby.git mumble-ruby
WORKDIR /home/botmaster/src/mumble-ruby
RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build mumble-ruby.gemspec && \
    rvm @bots do gem install mumble-ruby-*.gem && \
    rvm @bots do gem install ruby-mpd && \
    rvm @bots do gem install crack"

#7 Download and set up celt-ruby and libcelt
WORKDIR /home/botmaster/src
RUN git clone https://github.com/dafoxia/celt-ruby.git
WORKDIR /home/botmaster/src/celt-ruby
RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build celt-ruby.gemspec && \
    rvm @bots do gem install celt-ruby"

WORKDIR /home/botmaster/src
RUN git clone https://github.com/mumble-voip/celt-0.7.0.git
WORKDIR /home/botmaster/src/celt-0.7.0
RUN ./autogen.sh && \
    ./configure --prefix=/home/botmaster/src/celt && \
    make && \
    make install

#8 Download and set up opus-ruby
WORKDIR /home/botmaster/src
RUN git clone https://github.com/dafoxia/opus-ruby.git
WORKDIR /home/botmaster/src/opus-ruby
RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build opus-ruby.gemspec && \
    rvm @bots do gem install opus-ruby"

#9 Download and set up mumble-ruby-pluginbot
WORKDIR /home/botmaster/src/
RUN git clone https://github.com/MusicGenerator/mumble-ruby-pluginbot.git
WORKDIR /home/botmaster/src/mumble-ruby-pluginbot

# Uncomment the next file if you want to use a bot from the current development branch
#RUN git checkout -b devel origin/devel

USER root
ADD scripts/startasdocker.sh /home/botmaster/startasdocker.sh
RUN chown botmaster: /home/botmaster/startasdocker.sh
RUN chmod a+x /home/botmaster/startasdocker.sh

USER botmaster
ADD conf/override_config.yml /home/botmaster/src/bot1_conf.yml

#10 Set up MPD (Music Player Daemon)
ADD conf/mpd.conf /home/botmaster/mpd1/mpd.conf

USER root
RUN chown botmaster: /home/botmaster/mpd1/mpd.conf
#RUN cp ~/src/mumble-ruby-pluginbot/templates/mpd.conf ~/mpd1/mpd.conf

USER botmaster
RUN curl -L https://yt-dl.org/downloads/latest/youtube-dl -o ~/src/youtube-dl
RUN chmod u+x ~/src/youtube-dl

ENTRYPOINT [ "/home/botmaster/startasdocker.sh" ]
VOLUME /home/botmaster/music/
VOLUME /home/botmaster/temp/
VOLUME /home/botmaster/certs/
VOLUME /home/botmaster/mpd1/playlists/
