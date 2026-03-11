#!/bin/bash

# Параметры пакета
PKG_NAME="yeelight2mqtt"
PKG_VERSION=$(sed -n '/Version = /s/.*"\([^"]*\)".*/\1/p' run.go)
PKG_MAINTAINER="captain <captain.perreiro@gmail.com>"
PKG_DESC="service add yeelight device to mqtt"
PKG_SECTION="misc"
PKG_PRIORITY="standard"
BUILD_DIR="build"
PKG_DIR="${BUILD_DIR}/${PKG_NAME}"
PKG_ARCH="arm_cortex-a7_neon-vfpv4"

# Очистка и создание структуры
rm -rf ${BUILD_DIR}
mkdir -p ${PKG_DIR}/control
mkdir -p ${PKG_DIR}/data
mkdir -p ${PKG_DIR}/data/etc
mkdir -p ${PKG_DIR}/data/etc/${PKG_NAME}
mkdir -p ${PKG_DIR}/data/etc/init.d
mkdir -p ${PKG_DIR}/data/usr/bin

# debian-binary
cat <<EOF > ${BUILD_DIR}/debian-binary
2.0
EOF

# control
cat <<EOF > ${PKG_DIR}/control/control
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: ${PKG_ARCH}
Maintainer: ${PKG_MAINTAINER}
Description: ${PKG_DESC}
Section: ${PKG_SECTION}
Priority: ${PKG_PRIORITY}
EOF

cat <<EOF > ${PKG_DIR}/control/postinst
#!/bin/sh

/etc/init.d/${PKG_NAME} enable
/etc/init.d/${PKG_NAME} start

exit 0
EOF

chmod +x ${PKG_DIR}/control/postinst 

cat <<EOF > ${PKG_DIR}/control/prerm
#!/bin/sh

/etc/init.d/${PKG_NAME} stop
/etc/init.d/${PKG_NAME} disable

exit 0
EOF

chmod +x ${PKG_DIR}/control/prerm 

cat <<EOF > ${PKG_DIR}/control/conffiles
/etc/${PKG_NAME}/config.yaml
EOF

# data
go build -ldflags="-s -w" -trimpath
./yeelight2mqtt -create-config ${PKG_DIR}/data/etc/${PKG_NAME}/config.yaml

cat <<EOF > ${PKG_DIR}/data/etc/init.d/${PKG_NAME}
#!/bin/sh /etc/rc.common

# Запуск после сетевых служб
START=88
USE_PROCD=1

NAME=${PKG_NAME}
PROG=/usr/bin/${PKG_NAME}

start_service() {
    procd_open_instance
    # Указываем путь к бинарнику
    procd_set_param command \$PROG
    # Respawn: порог 3600с, таймаут 5с, максимум 5 попыток
    procd_set_param respawn \${respawn_threshold:-3600} \${respawn_timeout:-5} \${respawn_retry:-5}
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

reload_service() {
    # Перезагружаем именно инстанс сервиса
    procd_send_signal \$PROG
}
EOF

chmod +x ${PKG_DIR}/data/etc/init.d/${PKG_NAME}

# Создание исполняемого файла с tinygo и upx архитектура arm_cortex-a7
env GOOS=linux GOARCH=arm GOARM=7 tinygo build -no-debug -o ${PKG_DIR}/data/usr/bin/${PKG_NAME}
upx --best --lzma ${PKG_DIR}/data/usr/bin/${PKG_NAME}
chmod +x ${PKG_DIR}/data/usr/bin/${PKG_NAME}

# Сборка пакета
tar -czvf ${BUILD_DIR}/control.tar.gz  -C ${PKG_DIR}/control .
tar -czvf ${BUILD_DIR}/data.tar.gz  -C ${PKG_DIR}/data .
rm -r ${PKG_DIR}
cd ${BUILD_DIR}
tar -czf ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk ./*
cd ..
#ar rv  ${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk ${BUILD_DIR}/debian-binary ${BUILD_DIR}/control.tar.gz ${BUILD_DIR}/data.tar.gz

echo "Пакет ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk создан в папке ${BUILD_DIR}"