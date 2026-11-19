#!/bin/bash

set -e
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

python -c '
import configparser
config = configparser.ConfigParser(allow_no_value=True, delimiters=("=", " "))
config.optionxform = lambda option: option
config.read("/etc/pacman.conf")
config["options"]["Color"] = None
config["options"]["ILoveCandy"] = None
config["options"]["VerbosePkgLists"] = None
with open("/etc/pacman.conf", "w") as f:
    config.write(f, space_around_delimiters=True)
'