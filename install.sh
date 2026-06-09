#!/bin/bash

# create backup namespace
kubectl create namespace backup 

# apply policy for backup system
kubectl apply -f minio-policy.yaml 

# apply minIO pod in the "minio" namespace
kubectl apply -f minio-config.yaml

# install velero
tar -xvf velero-v1.18.1-linux-amd64.tar.gz
sudo mv velero-v1.18.1-linux-amd64/velero /usr/local/bin
sudo chmod +x /usr/local/bin/velero

# exec velero on the cluster
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.9.0 \
  --bucket velero-backups \
  --secret-file ./credentials-velero \
  --use-node-agent \
  --uploader-type kopia \
  --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio-service.backup.svc.cluster.local:9000
  
# start taking snapshots
kubectl apply -f trigger-backup.yaml
