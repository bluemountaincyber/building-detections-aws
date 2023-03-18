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

* Create an access and secret key (honey token) for the honey user and configure those credentials for use with the AWS CLI
* Attempt to perform reconnaissance of the cloud account to generate event data

## Challenges

### Challenge 1: Create and Configure Access and Secret Key

The honey user created in the first exercise will do us no good if it can't be used by an attacker (in an effort to help us determine they are active in our account). This user account needs either a password set for AWS Management Console access or (as we'll do here) an access and secret key pair configured. Deploy a new access and secret key using CloudShell for the `HoneyUser` IAM account. 

Also, so the credentials can be used in your CloudShell session, create a profile in your `~/.aws/credentials` file called `honeyuser` with the new access and secret key info.

??? cmd "Solution"

    1. Once again, return to your CloudShell session (you may need to refresh the page if it timed out).

    2. Using the AWS CLI, you can easily create an access and secret key pair for any IAM user (maximum of two per user). Create one and save the results as the `ACCESS` and `SECRET` environment variables for the `HoneyUser` account by running the following commands:

        ```bash
        export SECRET=$(aws iam create-access-key --user-name \
          HoneyUser --query AccessKey.SecretAccessKey --output text)
        export ACCESS=$(aws iam list-access-keys --user-name HoneyUser \
          --query AccessKeyMetadata[0].AccessKeyId --output text)
        echo "Access Key ID:     $ACCESS"
        echo "Secret Access Key: $SECRET"
        ```

        !!! summary "Sample results"

            ```bash
            Access Key ID:     AKIATAI5Z6332EXAMPLE
            Secret Access Key: 7XHwl0TEm24iCNRaj4VNDrYfvoMkcCGpWEXAMPLE
            ```

    3. Use those environment variables to configure a profile called `honeyuser` for use with the AWS CLI tool.

        ```bash
        aws configure set aws_access_key_id $ACCESS --profile honeyuser
        aws configure set aws_secret_access_key $SECRET --profile honeyuser
        aws configure set region us-east-1 --profile honeyuser
        ```

### Challenge 2: Perform Reconnaissance with "Stolen Credentials"

A typical first step once credentials are stolen are to enumerate (i.e., see what you can access). Perform reconnaissance of the following AWS resources to see what this honey user has access to:

- IAM users
- S3 buckets
- EC2 instances
- DynamoDB databases

This should generate a decent amount of data to help in the creation of our detection in the next exercise.

??? cmd "Solution"

    1. When performing reconnaissance with stolen credentials, there are automated tools (like `pacu`) and manual approaches using vendor-provided tools (like the AWS CLI). We will choose the latter.

    2. The enumeration techniques using the AWS CLI will leverage commands with the `describe-` and `list-` prefixes as these commands perform read only actions against the greater service—showing which resources are deployed in those services and some of the configuration details.

    3. Run a few (or all) of the `describe-` or `list-` commands below:

        !!! note

            These commands will FAIL because the `HoneyUser` has no privileges. This is fine as we don't want an attacker that may stumble upon these credentials to do anything other than make their presense known.

        **Find IAM users**

        ```bash
        aws iam list-users --profile honeyuser
        ```

        !!! summary "Expected result"

            ```bash
            An error occurred (AccessDenied) when calling the ListUsers operation: User: 
            arn:aws:iam::123456789010:user/HoneyUser is not authorized to perform: iam:ListUsers on resource: 
            arn:aws:iam::123456789010:user/ because no identity-based policy allows the iam:ListUsers action
            ```

        **List S3 buckets**

        ```bash
        aws s3api list-buckets --profile honeyuser
        ```

        !!! summary "Expected result"

            ```bash
            An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
            ```

        **Describe EC2 instances**

        ```bash
        aws ec2 describe-instances --profile honeyuser
        ```

        !!! summary "Expected result"

            ```bash
            An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation: 
            You are not authorized to perform this operation.
            ```

        **Discover DynamoDb databases**

        ```bash
        aws dynamodb list-tables --profile honeyuser
        ```

        !!! summary "Expected result"

            ```bash
            An error occurred (AccessDeniedException) when calling the ListTables operation: User: 
            arn:aws:iam::123456789010:user/HoneyUser is not authorized to perform: dynamodb:ListTables on 
            resource: arn:aws:dynamodb:us-east-1:123456789010:table/* because no identity-based policy allows
            the dynamodb:ListTables action
            ```

    4. At this point, you have successful acted as an attacker with access to cloud credentials. Now to clean things up a bit before getting to the detection of this activity.

## Conclusion

Pretty easy, right? It can be easy for an attacker too to perform reconnaissance if they have access to legitimate cloud credentials. Now off to identify the usage of this honey token so that we are aware of a "fox in the hen house" (i.e., attacker in the cloud account).