# Exercise 5: Building an Automated Detection

<!-- markdownlint-disable MD007 MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #0000ff;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Create an AWS EventBridge rule to capture a CloudTrail data events involving your `password-backup` honey file and trigger a Lambda function called `HoneyFileDetection`
* Perform T1530 (Data from Cloud Storage) once more to trigger this automation
* Review Security Hub to find your automated detection

## Challenges

### Challenge 1: Create EventBridge Rule

Create an AWS EventBridge rule with the following logic:

- 



{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["GetObject"],
    "requestParameters": {
      "key": ["password-backup.txt"]
    }
  }
}

### Challenge 2: Emulate Stolen Credential Usage

### Challenge 3: Review Security Hub Detection

## Conclusion