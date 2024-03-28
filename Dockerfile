# Ubuntu has a more recent, less buggy MPD. You still can use Debian if you want to. This dockerfile is(was?) compatible with both.
FROM ubuntu
#FROM debian:jessie

MAINTAINER Natenom <natenom@mailbox.org>
EXPOSE 7701

LABEL version="0.10.x"

ENV MUMBLE_HOST="m.natenom.com"
ENV MUMBLE_PORT="64738"
ENV MUMBLE_USERNAME="MRPB_Dockerized"
ENV MUMBLE_PASSWORD="supersecretpassword"
ENV MUMBLE_CHANNEL="Bottest"
ENV MUMBLE_BITRATE="72000"

# We need extra repositories for lib-av
#RUN echo "deb http://httpredir.debian.org/debian jessie main contrib non-free" >> /etc/apt/sources.list.d/nonfree.list && \

RUN DEBIAN_FRONTEND=noninteractive apt-get update;\
    apt-get --allow-unauthenticated --no-install-recommends -qy install curl libyaml-dev git libopus-dev \
    build-essential zlib1g zlib1g-dev libssl-dev mpd mpc tmux \
    automake autoconf libtool libogg-dev psmisc util-linux libgmp3-dev \
    dialog unzip ca-certificates aria2 imagemagick ffmpeg python2 gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    adduser --quiet --disabled-password --uid 1000 --home /home/botmaster --shell /bin/bash botmaster

## Fix for ubuntu...
##RUN test -f /usr/bin/ffmpeg || ln -s /usr/bin/avconv /usr/bin/ffmpeg

USER botmaster
RUN cd /home/botmaster/ && mkdir ~/certs && mkdir ~/src && mkdir ~/logs && mkdir ~/temp && mkdir -p ~/mpd1/playlists && \
    curl -sSL https://rvm.io/mpapis.asc | /usr/bin/gpg --import - ; sleep 3; curl -sSL https://rvm.io/pkuczynski.asc | /usr/bin/gpg --import - ; sleep 3; \
    curl -L https://get.rvm.io | bash -s stable && /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm autolibs disable && rvm install ruby --latest && rvm --create use @bots" && \
    cd /home/botmaster/src && git clone --depth 1 https://github.com/dafoxia/mumble-ruby.git mumble-ruby && \
    cd /home/botmaster/src/mumble-ruby && \
    /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build mumble-ruby.gemspec && \
    rvm @bots do gem install mumble-ruby-*.gem && \
    rvm @bots do gem install ruby-mpd && \
    rvm @bots do gem install crack" && \
    cd /home/botmaster/src && \
    git clone --depth 1 https://github.com/dafoxia/celt-ruby.git && \
    cd /home/botmaster/src/celt-ruby && \
    /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build celt-ruby.gemspec && \
    rvm @bots do gem install celt-ruby" && \
    cd /home/botmaster/src && \
    git clone --depth 1 https://github.com/mumble-voip/celt-0.7.0.git && \
    cd /home/botmaster/src/celt-0.7.0 && \
    ./autogen.sh && \
    ./configure --prefix=/home/botmaster/src/celt && \
    make && \
    make install && \
    cd /home/botmaster/src && \
    git clone --depth 1 https://github.com/dafoxia/opus-ruby.git && \
    cd /home/botmaster/src/opus-ruby && \
    /bin/bash -c "source ~/.rvm/scripts/rvm && \
    rvm use @bots && \
    gem build opus-ruby.gemspec && \
    rvm @bots do gem install opus-ruby" && \
    cd /home/botmaster/src/ && \
    git clone --depth 1 https://github.com/MusicGenerator/mumble-ruby-pluginbot.git && \
    cd /home/botmaster/src/mumble-ruby-pluginbot && \
    rm -rf /home/botmaster/.rvm/src && \
    rm -rf /home/botmaster/src/celt-0.7.0

# Uncomment the next file if you want to use a bot from the current development branch
#RUN git checkout -b devel origin/devel



# Section for unsupported third party plugins from https://github.com/Shadowsith/mumble-ruby-pluginbot-plugins
# Those plugins are not supported by the authors of Mumble-Ruby-Pluginbot in any way. Use them on your own risk.
# Uncomment the next lines if you want to try them out; all of them.

#USER botmaster
#RUN cd /home/botmaster/src/ && \
#    git clone https://github.com/Shadowsith/mumble-ruby-pluginbot-plugins.git && \
#    cd mumble-ruby-pluginbot-plugins && \
#    cp -f ./helpers/* /home/botmaster/src/mumble-ruby-pluginbot/helpers/ && \
#    cp -f ./plugins/* /home/botmaster/src/mumble-ruby-pluginbot/plugins/
#
#USER root
#RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get --allow-unauthenticated --no-install-recommends -qy install mplayer \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# End of third party plugins section.



USER root
#RUN DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get remove -qy libyaml-dev git libopus-dev build-essential zlib1g-dev libssl-dev automake autoconf libogg-dev libgmp3-dev && \
#    /usr/bin/apt-get autoremove -qy

ADD scripts/startasdocker.sh /home/botmaster/startasdocker.sh
RUN chown botmaster: /home/botmaster/startasdocker.sh && chmod a+x /home/botmaster/startasdocker.sh

USER botmaster
ADD conf/override_config.yml /home/botmaster/src/bot1_conf.yml

#10 Set up MPD (Music Player Daemon)
ADD conf/mpd.conf /home/botmaster/mpd1/mpd.conf

USER root
RUN chown botmaster: /home/botmaster/mpd1/mpd.conf
#RUN cp ~/src/mumble-ruby-pluginbot/templates/mpd.conf ~/mpd1/mpd.conf

USER botmaster
RUN curl -L https://yt-dl.org/downloads/latest/youtube-dl -o ~/src/youtube-dl && chmod u+x ~/src/youtube-dl

ENTRYPOINT [ "/home/botmaster/startasdocker.sh" ]
VOLUME /home/botmaster/music/
VOLUME /home/botmaster/temp/
VOLUME /home/botmaster/certs/
VOLUME /home/botmaster/mpd1/playlists/
