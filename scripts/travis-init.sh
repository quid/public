#!/bin/bash
# Initialization script for travis ci jobs
# Sets up access to Quid's python package and docker repos on artifactory. Also configures the environment to support buildkit (see https://docs.docker.com/develop/develop-images/build_enhancements/)
# Usage: source <(curl https://raw.githubusercontent.com/quid/public/master/scripts/travis-init.sh)
set -e

echo "Setting up travis build environment"

if [[ -z $ARTIFACTORY_USER ]]; then
  ARTIFACTORY_USER=$ARTIFACTORY_USERNAME
fi

if [[ -z $ARTIFACTORY_URL ]]; then
  export ARTIFACTORY_URL="docker.quid.com"
fi

if [[ -z $PYPI_ARTIFACTORY_URL ]]; then
  export PYPI_ARTIFACTORY_URL="nexus.quid.com"
fi


if [[ -z $ARTIFACTORY_PASSWORD || -z $ARTIFACTORY_USER ]]; then
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
sudo apt-get -qq update
sudo apt-get -qq -y -o Dpkg::Options::="--force-confnew" install docker-ce

# install 1.25 version of docker-compose (for buildkit support)
# https://github.com/docker/compose/releases/tag/1.25.0
DOCKER_COMPOSE_VERSION=${1:-1.25.4}
echo "Installing ${DOCKER_COMPOSE_VERSION} version of docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
docker-compose version

# enable buildkit
export DOCKER_BUILDKIT=1

# clear out the setting 'registry-mirrors' from docker config file which causes buildkit to fail
# see https://github.com/moby/moby/issues/39120
sudo bash -c "echo '{}' > /etc/docker/daemon.json"

echo "Restarting Docker service"
sudo service docker restart

echo "Travis initialization complete"
