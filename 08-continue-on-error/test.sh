#!/bin/bash

function is_restore_complete() {
    velero restore get | grep "$1" | awk '{ print $3 }' | grep -q Completed
}

id=$(< /dev/urandom tr -dc a-z0-9 | head -c4)
restore=restore-08-${id}
kubectl -n restore delete all --all --force --grace-period=0
kubectl -n restore apply -f pod.yaml
kubectl -n restore wait --for=condition=Ready -f pod.yaml
velero backup create backup-08-${id} --include-namespaces restore
kubectl delete ns restore
sed -i "s/restore-.*/restore-08-${id}/" restore.yaml
sed -i "s/backup-.*/backup-08-${id}/" restore.yaml
kubectl apply -f restore.yaml

while ! is_restore_complete $restore; do
    sleep 1
done

out=$(kubectl -n restore exec pod cat /world.txt)

if [ "$out" != "hello" ]; then
    echo "Exec failed in restored pod after faile with onError continue"
    exit 1
fi

echo "Success"
