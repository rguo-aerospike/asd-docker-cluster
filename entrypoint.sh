#!/bin/bash
set -e

# Access interface
if [ -f "/opt/aerospike/etc/aerospike.conf" ]; then
	cp /opt/aerospike/etc/aerospike.conf /etc/aerospike/aerospike.conf
	PUBLICIP=$(ip a s dev eth0 | grep -Po "(?<=inet )\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
	sed -i "/port 3000/a \\\t\taccess-address $PUBLICIP virtual" /etc/aerospike/aerospike.conf
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
