#!/bin/bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NAMESPACE=$1; shift
ACCESS_KEY=$1; shift
SECRET_KEY=$1; shift

if [ -z "${SECRET_KEY}" ]; then echo "Usage: $0 <namespace> <accessKey> <secretKey>";  exit 1; fi

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: s3access
  namespace: ${NAMESPACE}
type: Opaque
data:
  accessKey: $(echo $ACCESS_KEY | base64)
  secretKey: $(echo $SECRET_KEY | base64)
EOF