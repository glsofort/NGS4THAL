FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

## Install essential
RUN apt-get update && apt-get install -y --no-install-recommends build-essential python3 python3-pip python3-setuptools python3-dev wget bedtools bcftools less ghostscript gawk nano vcftools git tabix

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN pip install pandas

WORKDIR /apps

RUN git clone https://github.com/counsyl/hgvs.git && \
    cd hgvs && \
    python3 setup.py install

RUN pip install cdot pyfaidx

USER root

WORKDIR /workspace