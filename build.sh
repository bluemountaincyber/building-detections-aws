#!/bin/bash

aws cloudformation deploy --stack-name building-detections --template-file ./BuildingDetections.yaml --capabilities CAPABILITY_IAM
