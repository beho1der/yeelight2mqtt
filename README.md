
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

**Управление через mqtt:**

### Основное управление

| Топик | Тип данных | Диапазон / Формат | Settable? | Описание |
| :--- | :--- | :--- | :---: | :--- |
| `main/on` | boolean | true / false | да | Включена / выключена |
| `main/bright` | integer | 1–100 | да | Яркость (%) |
| `main/ct` | integer | 1700–6500 | да | Цветовая температура (К) |
| `main/rgb` | integer | 0–16777215 | да | Цвет в формате RGB (decimal) |
| `main/hue` | integer | 0–359 | да | Оттенок (HSV) |
| `main/sat` | integer | 0–100 | да | Насыщенность (HSV) |
| `main/color_mode` | string | RGB, CT, HSV, Flow | да | Текущий режим цвета |
| `main/flowing` | boolean | true / false | да* | Включён ли режим течения (flow) |
| `main/delayoff` | integer | 0–60 | да* | Таймер выключения (минуты) |
| `main/flow_params` | string | --- | да* | Параметры текущего flow (строка) |
| `main/music_on` | boolean | true / false | нет | Включён ли music mode |
| `main/name` | string | --- | нет | Имя лампы (из Yeelight) |
| `main/nl_br` | integer | 1–100 | да* | Яркость ночного режима (moonlight) |
| `main/moonlight_on` | boolean | true / false | да | Включён ли moonlight режим |

### Фоновая подсветка (Background Control)


| Топик | Тип данных | Диапазон / Формат | Settable? | Описание |
| :--- | :--- | :--- | :---: | :--- |
| `bg/on` | boolean | true / false | да | Включена фоновая подсветка |
| `bg/bright` | integer | 1–100 | да | Яркость фона (%) |
| `bg/ct` | integer | 1700–6500 | да | Цветовая температура фона (К) |
| `bg/rgb` | integer | 0–16777215 | да | Цвет фона (decimal RGB) |
| `bg/hue` | integer | 0–359 | да | Оттенок фона |
| `bg/sat` | integer | 0–100 | да | Насыщенность фона |
| `bg/color_mode` | string | RGB, CT, HSV, Flow | да | Режим цвета фона |
| `bg/flowing` | boolean | true / false | да* | Включён flow-режим фона |
| `bg/flow_params` | string | --- | да* | Параметры текущего flow фона |
  **Примеры комманд через mosquitto cli:**

*Включить основную лампу*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/on/set" -m "true"
```
*Выключить фоновую подсветку*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/bg/on/set" -m "false"
```
*Установить яркость 80%*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/bright/set" -m "80"
```
*Установить цветовую температуру 4000K*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/ct/set" -m "4000"
```
*Установить красный цвет (RGB = 16711680 = #FF0000)*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/rgb/set" -m "16711680"
```
*Переключить в режим HSV и задать hue 120 (зелёный)*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/color_mode/set" -m "HSV"
mosquitto_pub -t "y2m/bedroom-ceiling/main/hue/set"      -m "120"
```
*Включить moonlight-режим*
```sh
mosquitto_pub -t "y2m/bedroom-ceiling/main/moonlight_on/set" -m "true"
```

**Пример конфигурационного файла (config.toml) в комментариях возможность работы через переменные окружения**   
```sh
lights:
- host: 192.168.50.2    # IP адрес устройства     
  name: light-1-example # имя светильника будет в mqtt 
  oldfirmware: false    # первые версии устройства(прошивка V1) имели ограничение на длину запроса,для них надо выставить true
- host: 192.168.50.3
  name: light-2-example
  oldfirmware: false
lightpollingrate:
  seconds: 10          # временной интервал полного опроса статуса устройства
mqttsettings:
  host: localhost      # адрес mqtt сервера, можно с указанием протокола (WS протокол НЕ РАБОТАЕТ)
  port: 1883           # порт mqtt сервера
  tls: false           # использование шифрования
  user: ""             # логин
  password: ""         # пароль
  basetopic: y2m       # топик в который будут писать данные
  qos: 2
debug: false
```  