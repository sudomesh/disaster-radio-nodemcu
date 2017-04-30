
Experimenting with ESP8266 and node-mcu for lower power usage than a full Omega2 system.

# Requirements

## Firmware

First get an ESP8266. The easiest is to get one of the actual NodeMCU devices with a built-in USB interface. Flash the ESP8266 with a NodeMCU firmware using e.g. [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher). For convenience a compiled firmware that works with this repository's code is included in the `firmware/` directory.

The firmware needs the following modules:

* file
* net
* node
* WiFi
* UART
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

Connect a NodeMCU device to USB (or serial) and run:

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

The latest version of the NodeMCU firmware sends the DNS server DHCP option correctly as the board's own IP. If this ever changes, then we can re-enable it by adding "#define USE_DNS 1" in "app/include/lwip/app/dhcpserver.h".

# ToDo

* Add communication with RN2903 via UART NodeMCU module
* Add CSS and JS inlining so initial load is only one file
* DNS server seems slow to respond to first request?
* Make DNS server only respond to requests for a specified hostname
* Figure out how to set TxPower to 19.5 dBm (apparently NodeMCU per default maxes out at 17 dBm)

# ESP32

The ESP32 is [getting NodeMCU support](https://github.com/nodemcu/nodemcu-firmware/projects/1) but it's not quite there yet. That means we could likely migrate with minimal porting effort.

The ESP32 is more expensive (~$7 instead of ~$2). This is comparing the ESP8266-07 with a u.fl plug and 4 MB flash to an ESP-32S with 4 MB flash but no u.fl plug since no ESP32 with u.fl plug is available yet.

The ESP32 has the same maximum transmit power as the ESP8266 (19.5 dBm, 802.11b only) but it claims a better receive sensitivity at -98 dBm vs -91 dBm for the ESP8266 which is five times better! If this translates to a real world 5x improvement then we could get away with a 7 dBi antenna instead of a 14 dBi antenna or simply have much better performance when the roof is more than one floor above the access point.

Conclusion: When an ESP32 with u.fl plug becomes available _and_ NodeMCU is ready we should compare wifi performance to the ESP8266 and consider swithing if it's significantly better.

# RN2903 serial

Since we're already using serial to upload to the ESP8266 we are switching the serial port to use GPIO13 for RX and GPIO15 for TX five seconds after boot. This gives a window for talking to the device after reset and then switches it from communicating with your computer for development, over to communicating with the RN2903.

nodemcu dev board GPIO mapping:

```
GPIO13: D7
GPIO15: D8
```

# ToDo

* Have a little HTTP POST endpoint that switches serial betwen RN2903 and normal
* Fix dev console whitespace issues
* Catch XML parsing error on XMLHTTPRequest (firefox)
* Security for dev console

function to switch serial:

```
uart.alt(1) -- switch to alternate serial pins (where RN2903 is connected)
uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
-- redirect serial input to this callback
uart.on("data", "\n", function(data)
  -- handle incoming data from RN2903
end), 0)
uart.write(0, "HELLO!")
```


# License and copyright

License and copyright information for files in the `firmware/` directory can be found at 

For all other files in this repository:

License: GPLv2 (hoping to switch to GPLv3 in the future).

Copyright 2017 Marc Juul

