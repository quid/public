#!/bin/bash
# Initialization script for travis ci jobs
# Sets up access to Quid's python package and docker repos on artifactory. Also configures the environment to support buildkit (see https://docs.docker.com/develop/develop-images/build_enhancements/)

set -e

echo "Setting up travis build environment"

if [[ -z $ARTIFACTORY_USER ]]; then
  ARTIFACTORY_USER=$ARTIFACTORY_USERNAME
fi  

if [[ -z $ARTIFACTORY_PASSWORD || -z $ARTIFACTORY_USER || -z $ARTIFACTORY_URL || -z $PYPI_ARTIFACTORY_URL ]]; then
  echo 'The environment variables ARTIFACTORY_PASSWORD, ARTIFACTORY_USER, ARTIFACTORY_URL, and PYPI_ARTIFACTORY_URL must be set'
  exit 1
fi

# login into artifactory docker repo
echo "Logging into artifactory docker repo"
echo $ARTIFACTORY_PASSWORD | docker login -u $ARTIFACTORY_USER --password-stdin $ARTIFACTORY_URL

pipfile=${1:-apps/common/pip.conf}
# create pip.conf with secrets for mounting into docker image
echo "Placing pip.conf with private python repo creds in ${pipfile}"
mkdir -p apps/common && \
    printf "[global]\nindex-url = https://$ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD@$PYPI_ARTIFACTORY_URL/repository/pypi/simple\ntrusted-host = nexus.quid.com\n" > ${pipfile}

# install latest version of docker (for buildkit support)
echo "Installing latest docker release"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce

# enable buildkit
export DOCKER_BUILDKIT=1

# clear out the setting 'registry-mirrors' from docker config file which causes buildkit to fail
# see https://github.com/moby/moby/issues/39120
sudo bash -c "echo '{}' > /etc/docker/daemon.json"

echo "Restarting Docker service"
sudo service docker restart

echo "Travis initialization complete"
