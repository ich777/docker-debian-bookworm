FROM ich777/kasmvnc-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-debian-bookworm"

RUN export TZ=Europe/Rome && \
	apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	DEBIAN_FRONTEND=noninteractive apt-get -y install xfce4 xfce4-terminal xfce4-taskmanager dbus-x11 iputils-ping xarchiver bzip2 xz-utils unzip unrar zip binutils bash-completion procps traceroute telnet gvfs-backends gvfs-common gvfs-fuse gvfs firefox-esr curl unzip gedit ffmpeg flameshot jq fonts-vlgothic ttf-wqy-zenhei fonts-wqy-microhei fonts-takao fonts-arphic-uming fonts-noto-cjk msttcorefonts remmina nano libxdo3 ssh peek && \
	apt-get -y remove vim zutty pavucontrol && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/rustdesk && \
	RUSTDESK_V="$(wget -qO- https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep tag_name | cut -d '"' -f4)" && \
	wget -O /tmp/rustdesk/rustdesk.tar.zst https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_V}/rustdesk-${RUSTDESK_V}-0-x86_64.pkg.tar.zst && \
	tar -C /tmp/rustdesk -xvf /tmp/rustdesk/rustdesk.tar.zst && \
	mv /tmp/rustdesk/usr/lib/rustdesk /opt/ && mv /tmp/rustdesk/usr/share/icons/hicolor/256x256/apps/rustdesk.png /opt/rustdesk && \
	mv /tmp/rustdesk/usr/share/rustdesk/files/rustdesk.desktop /usr/share/applications/ && \
	sed -i "/^Icon=/c\Icon=\/opt\/rustdesk\/rustdesk.png" /usr/share/applications/rustdesk.desktop && \
	sed -i "/^Exec=/c\Exec=env LD_PRELOAD=\/opt\/rustdesk\/lib \/opt\/rustdesk\/rustdesk" /usr/share/applications/rustdesk.desktop && \
	rm -rf /tmp/rustdesk

RUN cd /tmp && \
	wget -O /tmp/axiom.tar.gz https://github.com/ich777/docker-debian-bookworm/raw/master/90145-axiom.tar.gz && \
	tar -xvf /tmp/axiom.tar.gz && \
	mv /tmp/axiomd /usr/share/themes/ && \
	rm -R /tmp/axiom* && \
	cd /usr/share/locale && \
	wget -O /usr/share/locale/locale.7z https://github.com/ich777/docker-debian-bookworm/raw/master/locale.7z && \
	p7zip -d -f /usr/share/locale/locale.7z && \
	chmod -R 755 /usr/share/locale/

RUN wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | tee /etc/apt/sources.list.d/element-io.list && \
	apt-get update && \
	apt-get -y install element-desktop && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i "s/Exec=\/opt\/Element\/element-desktop.*/Exec=\/opt\/Element\/element-desktop --no-sandbox --disable-seccomp-filter-sandbox --dbus-stub %U/g" /usr/share/applications/element-desktop.desktop

RUN mkdir -p /tmp/pinta && cd /tmp/pinta && \
	wget -O /tmp/pinta/Pinta-x86-64.AppImage https://github.com/ich777/docker-debian-bookworm/raw/master/Pinta-x86-64.AppImage && \
	chmod +x /tmp/pinta/Pinta-x86-64.AppImage && /tmp/pinta/Pinta-x86-64.AppImage --appimage-extract && mkdir -p /opt/pinta && \
	cp -R /tmp/pinta/squashfs-root/usr/bin /tmp/pinta/squashfs-root/usr/share/dotnet /opt/pinta && \
	cp -R /tmp/pinta/squashfs-root/usr/share/locale /usr/share/ && \
	cp /tmp/pinta/squashfs-root/pinta.desktop /usr/share/applications/ && \
	sed -i "/^Icon=/c\Icon=\/opt\/pinta\/bin\/icons\/hicolor\/96x96\/apps\/pinta.png" /usr/share/applications/pinta.desktop && \
	sed -i "/^Exec=/c\Exec=env DOTNET_ROOT=\/opt\/pinta\/dotnet \/opt\/pinta\/bin\/pinta %F" /usr/share/applications/pinta.desktop && \
	sed -i '/^TryExec=/d' /usr/share/applications/pinta.desktop && \
	rm -rf /tmp/pinta

RUN systemctl set-default multi-user.target

ENV DATA_DIR=/debian
ENV FORCE_UPDATE=""
ENV DEPTH=16
ENV HW3D="true"
ENV DRINODE="/dev/dri/renderD128"
ENV FRAMERATE=30
ENV PORT=8080
ENV KASMVNC_PARAMS="-DisableBasicAuth -PreferBandwidth -FreeKeyMappings -DLP_ClipDelay=0"
ENV KASM_AMDIN_PASSWD="password"
ENV RECT_THREADS=1
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="Debian"
ENV ROOT_PWD="Docker!"
ENV DEV=""
ENV USER_LOCALES="en_US.UTF-8 UTF-8"

RUN mkdir $DATA_DIR	&& \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
COPY /config/ /tmp/config/
RUN chmod -R 770 /opt/scripts/

WORKDIR $DATA_DIR

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]