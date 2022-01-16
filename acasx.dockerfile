FROM debian:stretch AS base

RUN apt-get update

FROM base as debian_tool_base

RUN apt-get install -y wget git python3 python3-pip

RUN pip3 install requests

FROM debian_tool_base as julia_base

ENV JULIA_BIN_URL https://julialang-s3.julialang.org/bin/linux/x64/0.3/julia-0.3.12-linux-x86_64.tar.gz
ENV JULIA_DIRNAME julia-80aa77986e

WORKDIR /julia

RUN wget $JULIA_BIN_URL
RUN tar -xvf julia-0.3.12-linux-x86_64.tar.gz

COPY docker-utils/pkg_install.jl pkg_install.jl

RUN $JULIA_DIRNAME/bin/julia pkg_install.jl

FROM julia_base as acasx_base

ENV JULIA_BIN_PATH /julia/$JULIA_DIRNAME/bin/julia

WORKDIR /acasx

COPY docker-utils/run_script.sh .
RUN chmod u+x run_script.sh

WORKDIR /julia/$JULIA_DIRNAME/bin/

ENTRYPOINT ["./julia", "/acasx/code/main_opt_refactor.jl"]

