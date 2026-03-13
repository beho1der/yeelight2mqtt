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
OPKG_DIR="opkg"

TARGETS=(
    "arm:7:arm_cortex-a7_neon-vfpv4"      # Cortex-A7, Raspberry Pi 2/3
    "arm64::aarch64_generic"              # Generic AArch64 (Cortex-A53/72/etc)
    "mips:softfloat:0:mips_24kc"          # mips
    "mipsle:softfloat:0:mipsel_24kc"      # mipsle
)

# Очистка и создание структуры
rm -rf ${BUILD_DIR}

if [ ! -d "$OPKG_DIR" ]; then
  mkdir "$OPKG_DIR"
  echo "Папка создана $OPKG_DIR"
else
  echo "Папка уже $OPKG_DIR существует"
fi

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
Architecture:
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

for target in "${TARGETS[@]}"; do
    # Разделяем строку на переменные
    IFS=":" read -r ARCH ARM SOFTFLOAT CGO PKG_ARCH <<< "$target"
    echo "--- Building for $ARCH $PKG_ARCH ---"
    # Создание исполняемого файла с tinygo и upx архитектура arm_cortex-a7
    env env GOOS=linux GOARCH=$ARCH GOARM=$ARM GOMIPS=$SOFTFLOAT CGO_ENABLED=$CGO tinygo build -no-debug -o ${PKG_DIR}/data/usr/bin/${PKG_NAME}
    # Проверка, создался ли файл перед сжатием
    if [ -f "${PKG_DIR}/data/usr/bin/${PKG_NAME}" ]; then
        upx --best --lzma ${PKG_DIR}/data/usr/bin/${PKG_NAME}
        chmod +x ${PKG_DIR}/data/usr/bin/${PKG_NAME}
    else
        echo "Error: Build failed for $PKG_ARCH"
        continue
    fi

    # Заменяем архитектуру
    sed -i "s/Architecture:/Architecture: $PKG_ARCH/g" ${PKG_DIR}/control/control
    # Сборка пакета
    tar -czvf ${BUILD_DIR}/control.tar.gz  -C ${PKG_DIR}/control .
    tar -czvf ${BUILD_DIR}/data.tar.gz  -C ${PKG_DIR}/data .
  
    cd ${BUILD_DIR}
    tar -czf ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk ./*
    cd ..
    # Копируем готовый пакет
    cp ${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk /$OPKG_DIR/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk
    # Удаляем архивы
    rm ${BUILD_DIR}/control.tar.gz && rm ${BUILD_DIR}/data.tar.gz && rm ${BUILD_DIR}/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk
    echo "Пакет ${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.ipk создан в папке ${BUILD_DIR}"
done

rm -r ${PKG_DIR}