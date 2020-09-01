#!/bin/bash

function is_restore_complete() {
    velero restore get | grep "$1" | awk '{ print $3 }' | grep -q Completed
}

id=$(< /dev/urandom tr -dc a-z0-9 | head -c4)
restore=restore-07-${id}
sed -i "s/restore-.*/restore-07-${id}/" restore.yaml
sed -i "s/backup-.*/backup-07-${id}/" restore.yaml
sed -i "s/backup-.*/backup-07-${id}/" backup.yaml
kubectl -n restore delete all --all --force --grace-period=0
kubectl -n restore apply -f pod.yaml
kubectl -n restore wait --for=condition=Ready -f pod.yaml
while ! kubectl -n restore exec postgres -- pg_isready ; do
    sleep 1
done
kubectl -n restore exec postgres -- psql -U velero -c "CREATE TABLE velero (foo text)"
kubectl -n restore exec postgres -- psql -U velero -c "INSERT INTO velero (foo) VALUES ('bar')"

kubectl apply -f backup.yaml
kubectl delete ns restore
kubectl apply -f restore.yaml

while ! is_restore_complete $restore; do
    sleep 1
done

select=$(kubectl -n restore exec postgres -- psql -U velero -c "SELECT foo FROM velero")

if ! echo $select | grep -q "bar"; then
    echo "Postgres data was not restored"
    exit 1
fi

echo "Success"
