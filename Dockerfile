## nsenter
##
## modified image to build nsenter
##
#

FROM gdm85/wheezy

ENV VERSION 2.24
ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /home/builder

RUN apt-get update -q && apt-get install -qy curl build-essential file

RUN useradd -m builder

USER builder

RUN cd $HOME && mkdir src bin

WORKDIR /home/builder/src

## download matching version of util-linux
RUN curl https://www.kernel.org/pub/linux/utils/util-linux/v$VERSION/util-linux-$VERSION.tar.gz | tar -zxf- && \
	ln -s util-linux-$VERSION util-linux

WORKDIR /home/builder/src/util-linux
RUN ./configure --without-ncurses && \
	make LDFLAGS=-all-static -j2 nsenter && \
	cp nsenter $HOME/bin

COPY docker-enter /home/builder/bin/

USER root

COPY nsenter-installer /usr/local/bin/

CMD nsenter-installer
