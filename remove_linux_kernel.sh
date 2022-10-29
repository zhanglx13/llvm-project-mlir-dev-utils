#!/bin/bash

sudo apt remove linux-modules-extra-$1-generic -y
sudo apt remove linux-modules-$1-generic -y
sudo apt remove linux-image-$1-generic -y
