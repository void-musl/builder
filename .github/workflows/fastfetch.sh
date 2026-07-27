#!/bin/env bash

sudo apt remove fastfetch || true
curl -LO https://github.com/fastfetch-cli/fastfetch/releases/download/2.66.0/fastfetch-linux-amd64.deb || echo 'File not found'
sudo apt install ./fastfetch-linux-amd64.deb || echo 'File install failed'
fastfetch
