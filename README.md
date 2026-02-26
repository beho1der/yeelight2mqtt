
Сервис для проброса устройств от yeelight в mqtt

**Сборка:**

Для ARM устройств обычным компилятором GO:

 - env GOOS=linux GOARCH=arm GOARM=7 go build -ldflags="-s -w" -trimpath

Для ARM устройств через компилятор tinygo:

 - env GOOS=linux GOARCH=arm GOARM=7 tinygo build -no-debug

Сжатие upx: - upx --best --lzma


