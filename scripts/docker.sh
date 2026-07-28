curl -sf https://raw.githubusercontent.com/void-musl/builder/main/scripts/fastfetch.sh | bash

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

curl -sf https://raw.githubusercontent.com/void-musl/builder/main/scripts/prepare.sh | bash
