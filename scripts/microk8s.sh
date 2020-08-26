#!/usr/bin/env bash
set -ex

echo ">>> Start microk8s and check its status"
microk8s.start
microk8s.status --wait-ready
microk8s.enable storage dns
microk8s.inspect

sudo microk8s enable helm3

sudo snap alias microk8s.helm3 helm
sudo snap alias microk8s.kubectl kubectl

echo ">>> Using microk8s docker daemon for the rest of operations"
echo $ARTIFACTORY_PASSWORD | microk8s.docker login -u $ARTIFACTORY_USER --password-stdin $ARTIFACTORY_URL
