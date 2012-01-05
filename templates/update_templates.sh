#!/bin/bash

DIR="${HOME}/Library/Developer/Xcode/Templates/File Templates/pressure"
rm -rf "$DIR"
cp -R "file_templates/pressure" "$DIR"
