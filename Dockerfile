FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

## Install essential
RUN apt-get update && apt-get install -y --no-install-recommends build-essential python3 python3-pip python3-setuptools python3-dev wget bedtools bcftools less ghostscript gawk nano vcftools

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN pip install pandas

USER root

WORKDIR /