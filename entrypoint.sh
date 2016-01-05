#!/bin/bash
set -e

# Access interface
if [ "${1}" == "net" ]; then
	shift; 
	INTERFACE=$1
	PUBLICIP=$(ip a s dev eth0 | grep -Po "(?<=inet )\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
	echo $PUBLICIP $INTERFACE
	#sed -i "/port 3000/a \\\t\taccess-address $PUBLICIP virtual" /opt/aerospike/etc/aerospike.conf
	shift;
fi

# if command starts with an option, prepend asd
if [ "${1:0:1}" = '-' ]; then
	set -- asd "$@"
fi

# if asd is specified for the command, start it with any given options
if [ "$1" = 'asd' ]; then
	# asd should always run in the foreground
	set -- "$@" --foreground

fi


# the command isn't asd so run the command the user specified

exec "$@"
