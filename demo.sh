#Create a manual backup of the default namespace

velero backup create chaos-test-backup-6 --include-namespaces default --wait

#Watch the backup process

velero backup describe chaos-test-backup-6

#Disaster: delete the API deployment

sudo kubectl delete deployment crud-api-deploy -n default

#Verify the damage

sudo kubectl get pods -n default

#Resurrection: trigger the restore

velero restore create --from-backup chaos-test-backup-6 --wait

#Monitor the recovery

velero restore get

#Final: let's look if all is recovered

sudo kubectl get pods -n default