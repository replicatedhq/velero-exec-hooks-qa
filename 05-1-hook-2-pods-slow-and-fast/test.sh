#!/bin/bash

function is_restore_complete() {
    velero restore get | grep "$1" | awk '{ print $3 }' | grep -q Completed
}

id=$(< /dev/urandom tr -dc a-z0-9 | head -c4)
restore=restore-05-${id}
kubectl -n restore delete all --all --force --grace-period=0
kubectl -n restore apply -f pod.yaml
kubectl -n restore wait --for=condition=Ready -f pod.yaml
velero backup create backup-05-${id} --include-namespaces restore
kubectl delete ns restore
sed -i "s/restore-.*/restore-05-${id}/" restore.yaml
sed -i "s/backup-.*/backup-05-${id}/" restore.yaml
kubectl apply -f restore.yaml

while ! is_restore_complete $restore; do
    sleep 1
done

fast=$(kubectl -n restore exec fast cat /time.txt)
slow=$(kubectl -n restore exec slow cat /time.txt)

# The slow pod initContainer sleeps 15 seconds so timestamp should be later
if [ "$fast" -ge "$slow" ]; then
    echo "Exec hook should have run in fast pod before slow pod"
    exit 1
fi

echo "Success"
