#!/bin/bash

TARGET=$(aws events list-targets-by-rule --rule honeyfile --query Targets[0].Id --output text)
aws events remove-targets --rule honeyfile --ids $TARGET
aws events delete-rule --name honeyfile
BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("cloudlogs-")) | .Name')
aws s3 rm s3://$BUCKET --recursive
aws s3api delete-bucket --bucket $BUCKET
BUCKET=$(aws s3api list-buckets | jq -r '.Buckets[] | select(.Name | startswith("databackup-")) | .Name')
aws s3 rm s3://$BUCKET --recursive
aws cloudtrail delete-trail --name security
aws cloudformation delete-stack --stack-name building-detections
