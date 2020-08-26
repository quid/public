#!/usr/bin/env bash
set -ex

export DOCKER_HOST="unix:///var/snap/microk8s/current/docker.sock"

sudo microk8s enable helm3

sudo snap alias microk8s.helm3 helm
sudo snap alias microk8s.kubectl kubectl

echo ">>> Using microk8s docker daemon for the rest of operations"
echo $ARTIFACTORY_PASSWORD | microk8s.docker login -u $ARTIFACTORY_USER --password-stdin $ARTIFACTORY_URL
