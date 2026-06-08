#!/bin/bash

# create backup namespace
kubectl create namespace backup 
kubectl create namespace minio-operator

# add minIO operator repo
helm repo add minio-operator https://operator.min.io
helm repo update

# install minIO operator
helm install --namespace minio-operator minio-operator minio/operator
