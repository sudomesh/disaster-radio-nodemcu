
THIS HAS BEEN REPLACED WITH ARDUINO-BASED FIRMWARE see https://github.com/sudomesh/disaster-radio

Experimenting with ESP8266 and node-mcu for lower power usage than a full Omega2 system.

# Requirements

## Firmware

First get an ESP8266. The easiest is to get one of the actual NodeMCU devices with a built-in USB interface. Flash the ESP8266 with a NodeMCU firmware using e.g. [nodemcu-pyflasher](https://github.com/marcelstoer/nodemcu-pyflasher). For convenience a compiled firmware that works with this repository's code is included in the `firmware/` directory.

See [wiki](../../wiki) for specific walk-throughs on getting ESP8266 ready. 

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


# DHCP DNS option

The latest version of the NodeMCU firmware sends the DNS server DHCP option correctly as the board's own IP. If this ever changes, then we can re-enable it by adding "#define USE_DNS 1" in "app/include/lwip/app/dhcpserver.h".


# ESP32

The ESP32 is [getting NodeMCU support](https://github.com/nodemcu/nodemcu-firmware/projects/1) but it's not quite there yet. That means we could likely migrate with minimal porting effort.

The ESP32 is more expensive (~$7 instead of ~$2). This is comparing the ESP8266-07 with a u.fl plug and 4 MB flash to an ESP-32S with 4 MB flash but no u.fl plug since no ESP32 with u.fl plug is available yet.

The ESP32 has the same maximum transmit power as the ESP8266 (19.5 dBm, 802.11b only) but it claims a better receive sensitivity at -98 dBm vs -91 dBm for the ESP8266 which is five times better! If this translates to a real world 5x improvement then we could get away with a 7 dBi antenna instead of a 14 dBi antenna or simply have much better performance when the roof is more than one floor above the access point.

Conclusion: When an ESP32 with u.fl plug becomes available _and_ NodeMCU is ready we should compare wifi performance to the ESP8266 and consider swithing if it's significantly better.

# debugging

The ESP8266 only has one serial port and we're using it to talk to the RN2903. We have lua consoles via telnet and via the web but the web console is currently being re-implemented so is not in a working state. To use the telnet console:

```
telnet 100.127.0.1
```

Right now the ESP8266 serial acts as a debug console, but as soon as a network console connection is opened the serial console is disabled and the connection to the RN2903 is activated.

The network console is not the same as the serial terminal. Notably it currently lack multiline input support ([see this issue](https://github.com/sudomesh/disaster-radio-nodemcu/issues/1)).

# RN2903 connection

The ESP8266 supports switching the serial TX/RX to use alternate pins after bootup and this happens automatically as soon as a telnet console is opened. The alternate pins are GPIO 13 and GPIO 15, also called pins 7 and 8 in nodemcu or pins D7 and D8 on the Weemos D1 mini board. We additionally use GPIO 5 (pin 1 / D1) to reset the RN2903 after bootup.

Connect the following pins like so from ESP8266 to RN2903:

```
ESP8266 - Weemos D1 mini  -   RN2903
----------------
GPIO05  -       D1      -->    RST
GPIO13  -       D7      -->    TX
GPIO15  -       D8      -->    RX
```

When connecting via telnet terminal the serial port will be automatically switch to the alternate pins and the lua debug console will be disabled.

# ToDo

## Automatic RN2903 init startup

* Run switchSerial as soon as web node is started via web client (and after telnet connection, as is currently the case).
* Init RN2903 after switchSerial

## Web dev console

* Switch server to calling `run(cmd)` from interpret.lua
* Test client

## Fix memory leak

* Fix memory leak in webserver that causes OOM after ~20-40 GET requests
* Get automatic web client chat receive loop working

## Get retransmission working

* Hash received message
* If message not retransmitted before (not in hash list)
* Add to hash list (limited size circular buffer)
* Retransmit after randomized delay

## DNS issues

* Enabling the DNS server makes uart.write flaky (only some characters sent)
* Make DNS server only respond to requests for a specified hostname

## Misc

* Make webserver send index.html for all unknown routes (handle 404 client side)
* Give lora transmit queue more than one slot
* Catch XML parsing error on XMLHTTPRequest (firefox)
* Figure out how to set TxPower to 19.5 dBm (apparently NodeMCU per default maxes out at 17 dBm)

# Directly talking to the RN2903

If you hook up the RN2903 directly to you usb to serial 3.3v adapter then be aware that you need to terminate each command with ctrl-m ctrl-enter (at least in minicom).

# Talking to the RN2903

The 3.3v on the ESP8266 dev boards are not able to power the RN2903. It needs power from e.g. a dedicated 3.3v regulator.

It seems that the RN2903 becomes uncommunicative if it's connected to the ESP8266 serial while the ESP8266 reboots. I wonder if it might be the RN2903 baud-rate auto-detection that changes the baudrate to 115200. The solution for now is to disconnect and reconnect BOTH the Gnd and 3V3 connections on the RN2903. It also works to momentarily connect the 3.3v RN2903 input to ground, so we should just have a small mosfet that can be controlled with a GPIO to toggle RN2903 power.

After booting the ESP8266, power-cycle the RN2903 as explained above, then connect to the network console and run;

```
loraInit()
```

If the RN2903 is responding you will see the message "RN2903 chip is connected". If it is not responding then currently you will get no output.

Then to start the transceive loop which handles receive and transmit, run:

```
loraTransceiveLoop()
```

# Fixing annoying /dev/ttyUSB0 names

When you plug in an ESP8266 USB module or USB serial adapter the first will generally show up as `/dev/ttyUSB0` and the next as `/dev/ttyUSB1` etc. but this will depend on the order you use to plug them in. When you are repeatedly restarting and replugging multiple devices during development this can get tedious.

You can use `scripts/usb_alias` to generate udev rules to give these devices more sane names when plugged in.

Since most of these devices don't have a USB serial number the only way to differentiate them is through the bus that they are attached to. Many laptops have multiple USB buses. You might find that attaching to the left side of your laptop and running `lsusb` will show that the device is on e.g. bus 1 and then plugging it on the right hand side will show it connected to bus 2.

Plug in a ESP8266 or serial adapter to the left USB port and use `lsusb` to determine the name. My device shows up as "QinHeng Electronics HL-340 USB-Serial adapter". Try plugging into different usb ports and verify that the bus changes between the right and left side usb ports. Now run:

```
./scripts/usb_alias -b qinheng disaster/left
```

add the resulting udev line to a new file `/etc/udev/rules.d/disaster.conf` and restart udev with e.g. `/etc/init.d/udev restart`.

Now when such a device is plugged into the left USB port it will appear as `/dev/disaster/left`.

Plug it into a right hand side USB port and do:

```
./scripts/usb_alias -b qinheng disaster/right
```

and again restart udev. Now you will be able to work with two devices without becoming confused about which `/dev` devices is which.

# License and copyright

License and copyright information for files in the `firmware/` directory can be found at the NodeMCU website.

For all other files in this repository:

License: GPLv3

Copyright 2017 Marc Juul

