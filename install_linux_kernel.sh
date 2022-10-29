#!/bin/bash

sudo apt-get install linux-image-$1-generic -y
sudo apt-get install linux-modules-$1-generic -y
sudo apt-get install linux-modules-extra-$1-generic -y
