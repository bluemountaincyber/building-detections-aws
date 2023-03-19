#!/bin/bash

pushd ~/building-detections-aws >/dev/null
aws cloudformation deploy --stack-name building-detections --template-file ./BuildingDetections.yaml --capabilities CAPABILITY_NAMED_IAM
cat << 'EOF' > /tmp/password-backup.txt
AWS Root: admin@sherlock.com    | P@ssw0rd1234
Sherlock: sherlock@sherlock.com | $h3rL0ck!
EOF
BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("databackup-")) | .Name')
aws s3 cp /tmp/password-backup.txt s3://$BUCKET/password-backup.txt >/dev/null
popd >/dev/null
