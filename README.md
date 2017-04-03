
Experimenting with ESP8266 and node-mcu for lower power usage than a full Omega2 system.

# Requirements

## Firmware

First get an ESP8266. The easiest is to get one of the actual nodemcu devices with a built-in USB interface. Flash the ESP8266 with a nodemcu firmware using e.g. [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher). For convenience a compiled firmware that works with this repository's code is included in the `firmware/` directory.

The firmware needs the following modules:

* file
* net
* node
* WiFi
* UART
* websocket
* CJSON

## Dependencies

Install nodemcu-uploader:

```
sudo pip install nodemcu-uploader
```

Install the latest stable version of node. If you don't already have it, first install nvm:

```
# do _not_ use sudo here!
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash
```

Then use nvm to install latest node.js:

```
# do _not_ use sudo here!
nvm install 6.10
```

Then install the node dependencies:

```
npm install
```

# Packaging

The first time you upload, and every time after changing any of the files in the `js/` directory, run:

```
npm run build
```

# Uploading

Connect a nodemcu device to USB (or serial) and run:

```
./upload.sh [serial_device] [baud]
```

`serial_device` defaults to /dev/ttyUSB0
`baud` defaults to 115200

# Debugging

All `print()` calls in the .lua scripts will send their output to the serial console, which also functions as a lua command line. Use e.g. minicom to connect:

```
minicom -o -D /dev/ttyUSB0
```

# DHCP DNS option

The latest version of the nodemcu firmware sends the DNS server DHCP option correctly as the board's own IP. If this ever changes, then we can re-enable it by adding "#define USE_DNS 1" in "app/include/lwip/app/dhcpserver.h".

# ToDo

* Add communication with RN2903 via UART nodemcu module
* Add CSS and JS inlining so initial load is only one file
* DNS server seems slow to respond to first request?
* Make DNS server only respond to requests for a specified hostname

# License and copyright

License and copyright information for files in the `firmware/` directory can be found at 

For all other files in this repository:

License: GPLv2 (hoping to switch to GPLv3 in the future).

Copyright 2017 Marc Juul

