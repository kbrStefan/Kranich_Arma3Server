FROM debian:trixie-slim

LABEL maintainer="Brett - github.com/brettmayson"
LABEL org.opencontainers.image.source=https://github.com/brettmayson/arma3server

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
    && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        python3 \
        lib32stdc++6 \
        lib32gcc-s1 \
        libcurl4 \
        wget \
        ca-certificates \
        curl \
        libstdc++6 \
        util-linux \
    && \
    apt-get remove --purge -y \
    && \
    apt-get clean autoclean \
    && \
    apt-get autoremove -y \
    && \
    rm -rf /var/lib/apt/lists/*

ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID arma \
    && useradd -m -u $UID -g $GID -d /home/arma -s /bin/bash arma

ENV ARMA_BINARY=./arma3server
ENV ARMA_CONFIG=main.cfg
ENV ARMA_PARAMS=
ENV ARMA_PROFILE=main
ENV ARMA_WORLD=empty
ENV ARMA_LIMITFPS=1000
ENV ARMA_CDLC=
ENV HEADLESS_CLIENTS=0
ENV HEADLESS_CLIENTS_PROFILE="\$profile-hc-\$i"
ENV PORT=2302
ENV STEAM_BRANCH=public
ENV STEAM_BRANCH_PASSWORD=
ENV STEAM_ADDITIONAL_DEPOT=
ENV MODS_LOCAL=true
ENV MODS_PRESET=
ENV SKIP_INSTALL=false

EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
EXPOSE 2306/udp

RUN mkdir -p /steamcmd \
    && wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar zxf - -C /steamcmd
#      curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
WORKDIR /arma3

RUN chown -R arma:arma /steamcmd \
    && mkdir -p /arma3/steamapps/workshop/content \
    && chown -R arma:arma /arma3

USER arma

VOLUME /steamcmd
VOLUME /arma3/addons
VOLUME /arma3/enoch
VOLUME /arma3/expansion
VOLUME /arma3/jets
VOLUME /arma3/heli
VOLUME /arma3/orange
VOLUME /arma3/argo
VOLUME /arma3/steamapps/workshop/content/107410

STOPSIGNAL SIGINT

COPY --chown=arma:arma *.py /

CMD ["python3","/launch.py"]
