#!/bin/bash

BUCKET=$(aws s3api list-buckets --query Buckets[].BucketName --output text | grep cloudlogs-)
aws s3 rm s3://$BUCKET --recursive
aws cloudformation delete-stack --stack-name building-detections
