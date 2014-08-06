#!/bin/sh
## @author gdm85
##
## first build the nsenter image by jpetazzo
## then automatically install nsenter and docker-enter on host
#

docker build --tag=gdm85/nsenter . && \
docker run --rm -v /usr/local/bin:/target gdm85/nsenter
