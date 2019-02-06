#!/usr/bin/env bash
# Run the OpenDJ server
# The idea is to consolidate all of the writable DJ directories to
# a single instance directory root, and update DJ's instance.loc file to point to that root
# This allows us to to mount a data volume on that root which  gives us
# persistence across restarts of OpenDJ. 
# For Docker - mount a data volume on /opt/opendj/instances/instance1. 
# For Kubernetes mount a PV
# To "prime" the sytem the first time DJ is run, we copy in a skeleton 
# DJ instance from the instances/template directory that was created in the Dockerfile

# opendj=/opt/opendj
# opendjconf=/opt/repo/opendj
# opendjbin=/opt/repo/bin/opendj
# opendjzip=/opt/repo/bin/zip/opendj.zip

if [ -e "$opendjbin" ]; then
	cp -r $opendjbin $opendj
else
	if [ -s "$opendjzip" ]; then
		unzip $opendjzip -d /opt/
	else
		echo "Did not find any opendj folder at $opendjbin, and don't have any open access to zipfile $opendjzip"	
	fi
fi

if [ -e "$opendjconf" ]; then
	cp -r $opendjconf/* $opendj/
fi

if [ -e "$opendj/bin" ]; then
	cd $opendj
	mkdir -p $opendj/instances/instance1
	./setup -p 389 --ldapsPort 636 --adminConnectorPort 4444 --enableStartTLS --sampleData 100 --baseDN "dc=example,dc=com" -h localhost --rootUserPassword password --acceptLicense --instancePath $opendj/instances/instance1 --doNotStart 
	./bin/stop-ds

	# Instance dir does not exist?
	if [ ! -d $opendj/instances/instance1/config ] ; then
		# Copy the template
		mkdir -p $opendj/instances/instance1
		echo Instance Directory is empty. Creating new instance from template
		cp -r $opendj/instances/template/* $opendj/instances/instance1
	fi
	echo "$opendj/instances/instance1" > $opendj/instance.loc
	./bin/start-ds --nodetach
else 
	echo "Failed to find opendj binaries"
	exit 1
fi
