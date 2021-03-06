#!/bin/bash

function is_restore_complete() {
    velero restore get | grep "$1" | awk '{ print $3 }' | grep -q Completed
}

id=$(< /dev/urandom tr -dc a-z0-9 | head -c4)
restore=restore-06-${id}
kubectl -n restore delete all --all --force --grace-period=0
kubectl -n restore apply -f pod.yaml
kubectl -n restore wait --for=condition=Ready -f pod.yaml
velero backup create backup-06-${id} --include-namespaces restore
kubectl delete ns restore
sed -i "s/restore-.*/restore-06-${id}/" restore.yaml
sed -i "s/backup-.*/backup-06-${id}/" restore.yaml
kubectl apply -f restore.yaml

while ! is_restore_complete $restore; do
    sleep 1
done

pod1=$(kubectl -n restore exec pod1 cat /hook.txt)

if [ "$pod1" != "hook1" ]; then
    echo "Hook1 did not execute in pod 1"
    exit 1
fi

pod2=$(kubectl -n restore exec pod2 cat /hook.txt)

if [ "$pod2" != "hook2" ]; then
    echo "Hook2 did not execute in pod 2"
    exit 1
fi

echo "Success"
