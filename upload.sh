#!/bin/bash

DEVICE="/dev/ttyUSB0"
BAUD="115200"

if [ "$#" -gt 0 ]; then
  DEVICE=$1
  if [ "$#" -gt 1 ]; then
  BAUD=$2
  fi
fi

if [ ! -d "node_modules" ]; then
  echo "Run 'npm install' before uploading" > /dev/stderr
  exit 1
fi

if [ ! -f "bundle.js" ]; then
  echo "Run 'npm run build' before uploading" > /dev/stderr
  exit 1
fi

nodemcu-uploader --port $DEVICE --baud $BAUD upload *.lua *.html *.css bundle.js
