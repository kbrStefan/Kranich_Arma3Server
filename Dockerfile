FROM debian:bookworm-slim as build_stage

LABEL maintainer="walentinlamonos@gmail.com"
ARG PUID=1000

ENV USER steam
ENV HOMEDIR "/home/${USER}"
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"

RUN set -x \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		lib32stdc++6=12.2.0-14+deb12u1 \
		lib32gcc-s1=12.2.0-14+deb12u1 \
		ca-certificates=20230311 \
		nano=7.2-1+deb12u1 \
		curl=7.88.1-10+deb12u12 \
		locales=2.36-9+deb12u10 \
        python3 \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	# Create unprivileged user
	&& useradd -u "${PUID}" -m "${USER}" \
	# Download SteamCMD, execute as user
	&& su "${USER}" -c \
		"mkdir -p \"${STEAMCMDDIR}\" \
                && curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
                && \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
                && ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${STEAMCMDDIR}/steamservice.so\" \
                && mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
                && ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
                && ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
                && mkdir -p \"${HOMEDIR}/.steam/sdk64\" \
                && ln -s \"${STEAMCMDDIR}/linux64/steamclient.so\" \"${HOMEDIR}/.steam/sdk64/steamclient.so\" \
                && ln -s \"${STEAMCMDDIR}/linux64/steamcmd\" \"${STEAMCMDDIR}/linux64/steam\" \
                && ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
	# Symlink steamclient.so; So misconfigured dedicated servers can find it
 	&& ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" \
	&& rm -rf /var/lib/apt/lists/*

FROM build_stage AS bookworm-root
WORKDIR ${STEAMCMDDIR}

FROM bookworm-root AS bookworm
# Switch to user
USER ${USER}

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
ENV SKIP_WORKSHOP_UPDATES=false

EXPOSE 2302/udp
EXPOSE 2303/udp
EXPOSE 2304/udp
EXPOSE 2305/udp
EXPOSE 2306/udp

WORKDIR /arma3
RUN mkdir -p /arma3/steamapps/workshop/content/107410

#VOLUME /arma3/addons
#VOLUME /arma3/enoch
#VOLUME /arma3/expansion
#VOLUME /arma3/jets
#VOLUME /arma3/heli
#VOLUME /arma3/orange
#VOLUME /arma3/argo

STOPSIGNAL SIGINT

COPY --chown=${USER}:${USER} *.py /

CMD ["python3", "-u", "/launch.py"]
