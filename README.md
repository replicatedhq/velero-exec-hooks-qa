# E2E tests for velero restore hooks

This repo contains scripts for end-to-end tests of the restore hooks contributed to the Velero project by Replicated.

## Usage:

```
cd 01-single-pod-echo-from-spec && bash test.sh
```

## Setup:

Ubuntu 18.04 GCP n1-standard-4
Kubectl 1.14.0
Kubernetes API 1.17.7, single node cluster
GCP backup object store
