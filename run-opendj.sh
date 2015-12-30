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

cd /opt
file=/opt/repo/bin/staging/opendj.zip
if [ -s "$file" ]; then
		cp "$file" opendj.zip
else
	curl https://forgerock.org/djs/opendjrel.js?948497823 | grep -o "http://.*\.zip" | tail -1 | xargs curl -o opendj.zip
fi
unzip opendj.zip && ./opendj/setup --cli -p 389 --ldapsPort 636 --enableStartTLS --generateSelfSignedCertificate \
    --sampleData 100 --baseDN "dc=example,dc=com" -h localhost --rootUserPassword password --acceptLicense --no-prompt \
    && rm opendj.zip && /opt/opendj/bin/stop-ds


cd /opt/opendj

# Instance dir does not exist?
if [ ! -d instances/instance1/config ] ; then
  # Copy the template
  mkdir -p instances/instance1
  echo Instance Directory is empty. Creating new instance from template
  cp -r instances/template/* instances/instance1
  echo "./instances/instance1" > instance.loc
fi

./bin/start-ds --nodetach