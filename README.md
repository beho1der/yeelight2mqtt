
Сервис для проброса устройств  yeelight в mqtt

**Сборка:**

Для ARM устройств обычным компилятором GO:
```sh
 # env GOOS=linux GOARCH=arm GOARM=7 go build -ldflags="-s -w" -trimpath
```
Для ARM устройств через компилятор tinygo:
```sh
 # env GOOS=linux GOARCH=arm GOARM=7 tinygo build -no-debug
```
Сжатие upx: 
```sh
 # upx --best --lzma
```

**Аргументы запуска:**
```sh
1. /yeelight2mqtt -create-config /etc/yeelight2mqtt/config.yaml - создаёт папку с шаблонами конфигов по пути переданному пути, если их не существует.
2./yeelight2mqtt /etc/yeelight2mqtt/config.yaml - запускаем с нужным конфигурационном файлом.
```

