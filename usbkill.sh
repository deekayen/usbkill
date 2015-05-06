#!/bin/bash

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Contact: david@dkn.email - 7E38 B4FF 0A7C 2F28 5C31  2C8C EFD7 EC8D B5D4 C172

LOGPATH="/var/log/usbkill"
LOGFILE="/var/log/usbkill/usbkill.log"
SETTINGSPATH="/etc/usbkill"
SETTINGSFILE="/etc/usbkill/settings"
USAGE=$(cat <<EOF_USAGE
USAGE: ${SCRIPT} <options>

The following options are supported:

--help                       : Displays this help message.

EOF_USAGE
)

# Print usage message and exit
print_usage () {
  echo "${USAGE}" >&2
}

log () {
	# Log the message that needed to be logged:
	echo "$(date) $1" >> $LOGFILE

	# Log current usb state:
	echo 'Current state:' >> $LOGFILE
	listusb
	echo $DEVICES >> $LOGFILE
}

kill_computer () {
	# Log what is happening:
	log "Detected usb change. Dumping system_profiler and killing computer..."

	# This function will poweroff your computer immediately
	case "$(uname -s)" in
		# https://en.wikipedia.org/wiki/Uname
		Darwin)
			# Flushes to disk, then un-gracefully shuts down without signaling open apps
			# https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/halt.8.html
			halt -q
			;;
		DragonFly)
			# http://leaf.dragonflybsd.org/cgi/web-man?command=halt&section=ANY
			halt -q
			;;
		FreeBSD)
			# https://www.freebsd.org/cgi/man.cgi?query=halt&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
			halt -q
			;;
		Linux)
			# Sync the filesystem so that the recent log entry does not get lost.
			# http://manpages.ubuntu.com/manpages/lucid/man8/sync.8.html
			sync
			# Tested on Ubuntu 15.04
			# http://manpages.ubuntu.com/manpages/natty/man8/halt.8.html
			poweroff -f
			;;
		NetBSD)
			# http://netbsd.gw.com/cgi-bin/man-cgi?sync++NetBSD-current
			sync
			# http://netbsd.gw.com/cgi-bin/man-cgi?halt++NetBSD-current
			halt -q
		OpenBSD)
			# http://www.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man8/halt.8?query=halt
			halt -q
			;;
		*)
			echo 'Your operating system is not supported yet. Submit a patch.'
			log "Unknown operating system. Cannot halt."
			exit 1
			;;
	esac

	halt -q
}

listusb () {
  case "$(uname -s)" in
		Darwin)
			# A Yosemite version of the command 'lsusb' that returns a trimmed list of connected Product IDs
			DEVICES=( $(system_profiler SPUSBDataType | grep "Product ID:" | awk '{ print $3 }') )
			;;
		Linux)
			# Tested on Ubuntu 15.04 to list Device IDs
			DEVICES=( $(lsusb | awk '{ print $6 }') )
			;;
		*)
			echo 'Your operating system is not supported yet. Submit a patch.'
			log "Unknown operating system. Cannot generate USB ID list."
			exit 1
			;;
	esac
}

settings_template () {
	if [ ! -d $SETTINGSPATH ]; then
		mkdir $SETTINGSPATH
	fi

	if [ ! -f $SETTINGSFILE ]; then
		# Pre-populate the settings file if it does not exist yet
		touch $SETTINGSFILE
		echo "# whitelist command lists the usb ids that you want whitelisted" >> $SETTINGSFILE
		echo "# find the correct usbid for your trusted usb using" >> $SETTINGSFILE
		echo "# the command 'system_profiler SPUSBDataType'" >> $SETTINGSFILE
		echo "# Look for the Product ID, like 0x1a10" >> $SETTINGSFILE
		echo "# Be warned! other parties can copy your trusted usbid to another usb device!" >> $SETTINGSFILE
		echo "# Use whitelist command and single space separation as follows:" >> $SETTINGSFILE
		echo "# for Mac:" >> $SETTINGSFILE
		echo "# whitelist=( \"0x0024\" \"0x8510\" \"0x0024\" \"0x2512\" \"0x4500\" \"0x8286\" \"0x0262\" )" >> $SETTINGSFILE
		echo "# for Linux:" >> $SETTINGSFILE
		echo "# whitelist=( \"8087:8000\" \"1d6b:0002\" \"0781:5580\" \"1d6b:0003\" \"0489:e056\" \"1bcf:2c67\" \"1d6b:0002\" )" >> $SETTINGSFILE
		echo "whitelist=( )" >> $SETTINGSFILE
		echo ""  >> $SETTINGSFILE
		echo "# allow for a certain amount of sleep time between checks, e.g. 1 second:" >> $SETTINGSFILE
		echo "sleep=1" >> $SETTINGSFILE
	fi
}

load_settings () {
	# read all lines of settings file
	source $SETTINGSFILE
	# This should do more fancy filtering for malicious "variables" instead of doing a plain source
}

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

monitor () {
	# Main loop that checks every 'sleep_time' seconds if computer should be killed.
	# Allows only whitelisted usb devices to connect!
	# Allows no usb device that wat present during program start to disconnect!
	listusb
	startdeviceindicies=${!DEVICES[*]}
	for index in $startdeviceindicies; do
		start_devices[$index]=${DEVICES[$index]}
	done
	load_settings

	# Write to logs that loop is starting:
	log "Started patrolling the USB ports every $sleep seconds."

	# Main loop
	while true
	do
		# List the current USB devices
		listusb
		currentdeviceindicies=${!DEVICES[*]}
		for index in $currentdeviceindicies; do
			current_devices[$index]=${DEVICES[$index]}
		done

		# Check that all current devices are in the set of acceptable devices
		for i in "${current_devices[@]}"; do
			# Was the current device
			if [[ ! "${start_devices[@]}" =~ "$i" && ! "${whitelist[@]}" =~ "$i" ]]; then
				kill_computer
			fi
		done


		# Check that all start devices are still present in current devices
		for i in "${start_devices[@]}"; do
			if [[ ! "${current_devices[@]}" =~ "$i" ]]; then
				kill_computer
			fi
		done

        current_devices=( )
		sleep $sleep
	done
}

signaled () {
	echo "Exiting because exit signal was received"
	log "Exiting because exit signal was received"
	exit 0
}

# parse the command line
# for each command line argument that requires
# a second parameter, assign "BAD" if it's empty
# or begins with -- (ie picking another argument)
while [ "${1}" != "" ]; do
  case ${1} in
    --help|-h|--*)
      print_usage
      exit 0
      ;;
  esac
done

# Check if program is run as root, else exit.
# Root is needed to power off the computer.
if [[ $EUID != 0 ]]; then
    echo "This program needs to run as root."
    exit 1
fi

# Make sure there is a logging folder
if [ ! -d $LOGPATH ]; then
	mkdir $LOGPATH
fi

if [ ! -f $LOGFILE ]; then
	touch $LOGFILE
fi

# Make sure settings file is available
settings_template

trap signaled SIGHUP SIGINT SIGTERM SIGQUIT
# add an option for trap to cause a shutdown

# Start main loop
monitor

