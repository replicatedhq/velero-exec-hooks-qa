#!/bin/bash

function is_restore_complete() {
    velero restore get | grep "$1" | awk '{ print $3 }' | grep -q Completed
}

id=$(< /dev/urandom tr -dc a-z0-9 | head -c4)
restore=restore-04-${id}
kubectl -n restore delete all --all --force --grace-period=0
kubectl -n restore apply -f pod.yaml
kubectl -n restore wait --for=condition=Ready -f pod.yaml
velero backup create backup-04-${id} --include-namespaces restore
kubectl delete ns restore
sed -i "s/restore-.*/restore-04-${id}/" restore.yaml
sed -i "s/backup-.*/backup-04-${id}/" restore.yaml
kubectl apply -f restore.yaml

while ! is_restore_complete $restore; do
    sleep 1
done

kubectl -n restore exec -i pod -c container1 -- test -f /world.txt
if [ "$?" != "1" ]; then
    echo "/world.txt should not exist in container1"
    exit 1
fi

echo "Success"
