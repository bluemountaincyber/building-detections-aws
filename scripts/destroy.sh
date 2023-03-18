#!/bin/bash

BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("cloudlogs-")) | .Name')
aws s3 rm s3://$BUCKET --recursive
aws s3api delete-bucket --bucket $BUCKET
aws cloudtrail delete-trail --name security
aws cloudformation delete-stack --stack-name building-detections
