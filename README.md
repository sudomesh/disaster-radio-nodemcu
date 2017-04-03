
Experimenting with ESP8266 and node-mcu for lower power usage than a full Omega2 system.

# Requirements

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
