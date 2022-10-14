#!/bin/bash
# Load shared setup scripts
source /home/dev/.profile

sudo apt-get update && sudo apt-get upgrade -y --no-install-recommends && \
	DEBIAN_FRONTEND=noninteractive TZ=America/Toronto sudo -E apt-get install -y --no-install-recommends \
	jq \
	python3

################################################
### Custom Excludes - Not point in commiting ###
################################################
echo "/home/dev/src/ockam/target" >> /home/dev/.simplesync_exclude