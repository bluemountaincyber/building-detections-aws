#!/bin/bash

pushd ~/building-detections-aws >/dev/null
aws cloudformation deploy --stack-name building-detections --template-file ../BuildingDetections.yaml --capabilities CAPABILITY_IAM
popd >/dev/null
