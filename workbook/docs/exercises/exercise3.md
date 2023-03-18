# Exercise 3: Attacking the Cloud Account

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #ff0000;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Create an access and secret key (honey token) for the honey user and set environment variables
* Attempt to perform reconnaissance of the cloud account to generate event data
* Unset the environment variables so that your default cloud account is used from the command line in future exercises

## Challenges

### Challenge 1: Create and Configure Access and Secret Key

The honey user created in the first exercise will do us no good if it can't be used by an attacker (in an effort to help us determine they are active in our account). This user account needs either a password set for AWS Management Console access or (as we'll do here) an access and secret key pair configured. Deploy a new access and secret key using CloudShell for the `HoneyUser` IAM account. 

Also, so the credentials can be used in your CloudShell session, set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables to their appropriate values.

### Challenge 2: Perform Reconnaissance with "Stolen Credentials"

A typical first step once credentials are stolen are to enumerate (i.e., see what you can access). Perform reconnaissance of the following AWS resources to see what this honey user has access to:

- IAM users
- S3 buckets
- EC2 instances
- DynamoDB databases

This should generate a decent amount of data to help in the creation of our detection in the next exercise.

### Challenge 3: Unset Environment Variables

So that these honey tokens are not used in future labs, unset the environment variables and use the `GetCallerIdentity` API call to ensure that you are using your correct IAM user (i.e., not `HoneyUser`).