#!/bin/bash
# Initialization script for travis ci jobs
# Sets up access to Quid's python package and docker repos on artifactory. Also configures the environment to support buildkit (see https://docs.docker.com/develop/develop-images/build_enhancements/)
# Usage: source <(curl https://raw.githubusercontent.com/quid/public/master/scripts/travis-init.sh)
set -e

setup_version_tag() {
  # Reads the current version from .bumpversion.cfg and stores it in 
  # the environment variable STACK_VERSION
  
  echo "Setting up STACK_VERSION environment variable"
  unset STACK_VERSION
  # try to extract the version from bumpversion
  if test -f ".bumpversion.cfg"; then
    STACK_VERSION=$(cat .bumpversion.cfg | sed -En 's/^current_version[ ]*=[ ]*([0-9].[0-9].[0-9])$/\1/p')
  fi
  
  if [ -z "$STACK_VERSION" ]; then
    echo "Warning: Failed to parse version tag from .bumpversion.cfg"
  else
    echo "Successfully parsed version '${STACK_VERSION}' from .bumpversion.cfg"
    echo "Running: export STACK_VERSION=${STACK_VERSION}"
    export STACK_VERSION=${STACK_VERSION}
  fi
}

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

if [[ -z $DOCKER_COMPOSE_VERSION ]]; then
  export DOCKER_COMPOSE_VERSION=1.25.4
fi

if [[ -z $ARTIFACTORY_PASSWORD || -z $ARTIFACTORY_USER ]]; then
  echo 'The environment variables ARTIFACTORY_PASSWORD, ARTIFACTORY_USER, ARTIFACTORY_URL, and PYPI_ARTIFACTORY_URL must be set'
  exit 1
fi

# login into artifactory docker repo
echo "Logging into artifactory docker repo"
echo $ARTIFACTORY_PASSWORD | docker login -u $ARTIFACTORY_USER --password-stdin $ARTIFACTORY_URL

# Configure pip
pipfile=${1:-apps/common/pip.conf}
# The PIP_INDEX_URL env var is required by builds that use pipenv. 
export PIP_INDEX_URL=${PIP_INDEX_URL:-https://$ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD@$PYPI_ARTIFACTORY_URL/repository/pypi/simple}
# create pip.conf with secrets for mounting into docker image
echo "Setting PIP_INDEX_URL env var and placing pip.conf with private python repo creds in ${pipfile}"
mkdir -p apps/common && \
    printf "[global]\nindex-url = ${PIP_INDEX_URL}\ntrusted-host = nexus.quid.com\n" > ${pipfile}


# install latest version of docker (for buildkit support)
echo "Installing latest docker release"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -qq update
sudo apt-get -qq -y -o Dpkg::Options::="--force-confnew" install docker-ce

# install 1.25 version of docker-compose (for buildkit support)
# https://github.com/docker/compose/releases/tag/1.25.0
echo "Installing ${DOCKER_COMPOSE_VERSION} version of docker-compose"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
docker-compose version

# enable buildkit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
# clear out the setting 'registry-mirrors' from docker config file which causes buildkit to fail
# see https://github.com/moby/moby/issues/39120
sudo bash -c "echo '{}' > /etc/docker/daemon.json"

echo "Restarting Docker service"
sudo service docker restart

setup_version_tag

echo "Travis initialization complete"
