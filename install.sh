#!/bin/bash

echo "Starting Enterprise Cluster Deployment..."

echo "Applying RBAC and Security Policies..."
sudo k3s kubectl apply -f security-rbac.yaml

echo "Deploying MinIO Storage Vault..."
sudo k3s kubectl apply -f ./minio/minio-config.yaml
sudo k3s kubectl apply -f ./minio/minio-policy.yaml
sleep 10

echo "Creating MinIO Backup Bucket..."
sudo k3s kubectl exec -n backup deploy/minio -- mkdir -p /data/velero-backups

echo "Deploying MySQL Database..."
sudo k3s kubectl apply -f ./mysql/mysql-storage.yaml
sudo k3s kubectl apply -f ./mysql/mysql-deploy.yaml

echo "Deploying CRUD Service API..."
sudo k3s kubectl apply -f ./crud-service/crud-deploy.yaml

echo "Installing Velero Disaster Recovery Engine..."
tar -xvf ./velero/velero-v1.18.1-linux-amd64.tar.gz
sudo mv velero-v1.18.1-linux-amd64/velero /usr/local/bin/

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.9.0 \
    --bucket velero-backups \
    --secret-file ./velero/credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio-service.backup.svc.cluster.local:9000

echo "Waiting for Velero Engine to boot (30s)..."
sleep 30

echo "Applying Automated Backup Schedule..."
sudo k3s kubectl apply -f ./velero/trigger-backup.yaml

echo "Cluster Deployment Complete!"
sudo k3s kubectl get pods -A