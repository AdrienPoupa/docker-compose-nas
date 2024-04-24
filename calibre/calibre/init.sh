#!/bin/bash

echo $@

USERNAME=abc

groupadd --gid $PGID $USERNAME
useradd --uid $PUID --gid $PGID -m $USERNAME

su abc -c "/start-calibre-server.sh $@"