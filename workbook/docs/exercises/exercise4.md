# Exercise 4: Detecting the Attack

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #0000ff;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Discover where the CloudTrail data is being written to within the `cloudlogs-` S3 bucket
* Download just today's data to your CloudShell session
* Analyze the data looking for all API calls made by the honey user (this is the basis of the detection and what will trigger the alert automation in Exercise 5)

## Challenges

### Challenge 1: Discover CloudTrail Data Location

Using your CloudShell session, sift through your `cloudlogs-` S3 bucket to discover how the CloudTrail data is written to your S3 bucket. What kind of format is this data stored in?

??? cmd "Solution"

    1. Re-open your CloudShell session if it has closed.

    2. Since you'll be crafting several commands targeting your S3 bucket, create an environment variable consisting of the bucket name called `LOGBUCKET` like so:

        ```bash
        export LOGBUCKET=$(aws s3api list-buckets --query \
          "Buckets[? contains(Name,'cloudlogs-')].Name" --output text)
        echo "The log bucket is: $LOGBUCKET"
        ```

        !!! summary "Sample result"

            ```bash
            The log bucket is: cloudlogs-123456789010
            ```

    3. Now, use the AWS CLI to view the root of that bucket.

        ```bash
        aws s3 ls s3://$LOGBUCKET/
        ```

        !!! summary "Expected result"

            ```bash
                                       PRE AWSLogs/
            ```

    4. Looks like just a single folder called `AWSLogs`. Now see what is in that folder.

        ```bash
        aws s3 ls s3://$LOGBUCKET/AWSLogs/
        ```

        !!! summary "Expected result"

            ```bash
                                       PRE 123456789010/
            ```

    5. Those contents should be a folder that match your AWS account number. Now see what is in that folder.

        ```bash
        export ACCTNUM=$(aws sts get-caller-identity --query Account --output text)
        aws s3 ls s3://$LOGBUCKET/AWSLogs/$ACCTNUM/
        ```

        !!! summary "Expected result"

            ```bash
                                       PRE CloudTrail/
            ```

    6. Further down the rabbit hole, we found another folder called `CloudTrail`. Take a look inside.

        ```bash
        aws s3 ls s3://$LOGBUCKET/AWSLogs/$ACCTNUM/CloudTrail
        ```

        !!! summary "Sample result"

            ```bash
                                       PRE us-east-1/
            2023-03-18 11:37:56          0
            ```

    7. In this folder, you probably found one or more other folders with names of a valid AWS region. Since we were performing our attacker behaviors in the `us-east-1` region, see what is in that folder.

        ```bash
        aws s3 ls s3://$LOGBUCKET/AWSLogs/$ACCTNUM/CloudTrail/us-east-1/
        ```

        !!! summary "Sample result"

            ```bash
                                       PRE 2023/
            ```

    8. The next folder down is the year. Now, you could repeat this a few more times, but we'll save you the trouble: under this folder is another folder with the number of the month (e.g., `03/`), then the day of the month (e.g., `18`), and then finally the CloudTrail data. To get to the data for today, here's a cheat:

        ```bash
        DATE=$(date +"%Y/%m/%d")
        aws s3 ls s3://$LOGBUCKET/AWSLogs/$ACCTNUM/CloudTrail/us-east-1/$DATE/
        ```

        !!! summary "Sample result"

            ```bash
            2023-03-18 11:49:49       4536 123456789010_CloudTrail_us-east-1_20230318T1035Z_dksdeM5YJ305GQqr.json.gz
            2023-03-18 11:44:06       1696 123456789010_CloudTrail_us-east-1_20230318T1145Z_hya7foJGvajqVkrL.json.gz
            2023-03-18 11:49:17       1455 123456789010_CloudTrail_us-east-1_20230318T1150Z_HfyMXO29h8phuMgw.json.gz
            2023-03-18 11:54:26       2574 123456789010_CloudTrail_us-east-1_20230318T1155Z_GzmUZDpzTamyk5q3.json.gz
            2023-03-18 11:59:15        756 123456789010_CloudTrail_us-east-1_20230318T1155Z_l71CvCGGtNrtFQYd.json.gz
            2023-03-18 11:59:37       2125 123456789010_CloudTrail_us-east-1_20230318T1200Z_XfRqC4uM9ZAmMPH7.json.gz
            2023-03-18 12:07:06        666 123456789010_CloudTrail_us-east-1_20230318T1205Z_yOQrfO2eVslVrhHL.json.gz

            <snip>
            ```

    9. As you can see, every 5 minutes or so, one or more GZIP-compressed JSON files are being created. This is the data we are interested in to discover our attacer's actions.

### Challenge 2: Download Today's Management Events

Now that you have the location of the CloudTrail data, download just today's data to your CloudShell session in a folder called `cloudtrail-logs` in your home directory.

??? cmd "Solution"

    1. Begin by creating a folder in your CloudShell session to store this data.

        ```bash
        mkdir /home/cloudshell-user/cloudtrail-logs
        ```

        !!! summary "Expected result"

            This command does not have output.

    2. Next, use the `aws s3 cp` command to download all of today's CloudTrail data.

        ```bash
        aws s3 cp s3://$LOGBUCKET/AWSLogs/$ACCTNUM/CloudTrail/us-east-1/$DATE/ \
          /home/cloudshell-user/cloudtrail-logs --recursive
        ```

        !!! summary "Sample results"

            ```bash
            download: s3://cloudlogs-123456789010/AWSLogs/123456789010/CloudTrail/us-east-1/2023/03/18/123456789010_CloudTrail_us-east-1_20230318T1150Z_HfyMXO29h8phuMgw.json.gz to cloudtrail-logs/123456789010_CloudTrail_us-east-1_20230318T1150Z_HfyMXO29h8phuMgw.json.gz
            download: s3://cloudlogs-123456789010/AWSLogs/123456789010/CloudTrail/us-east-1/2023/03/18/123456789010_CloudTrail_us-east-1_20230318T1035Z_dksdeM5YJ305GQqr.json.gz to cloudtrail-logs/123456789010_CloudTrail_us-east-1_20230318T1035Z_dksdeM5YJ305GQqr.json.gz
            download: s3://cloudlogs-123456789010/AWSLogs/123456789010/CloudTrail/us-east-1/2023/03/18/123456789010_CloudTrail_us-east-1_20230318T1155Z_GzmUZDpzTamyk5q3.json.gz to cloudtrail-logs/123456789010_CloudTrail_us-east-1_20230318T1155Z_GzmUZDpzTamyk5q3.json.gz
            download: s3://cloudlogs-123456789010/AWSLogs/123456789010/CloudTrail/us-east-1/2023/03/18/123456789010_CloudTrail_us-east-1_20230318T1145Z_hya7foJGvajqVkrL.json.gz to cloudtrail-logs/123456789010_CloudTrail_us-east-1_20230318T1145Z_hya7foJGvajqVkrL.json.gz

            <snip>
            ```

    3. Ensure that the data downloaded properly by reviewing the contents of the `/home/cloudshell-user/cloudtrail-logs` directory.

        ```bash
        ls /home/cloudshell-user/cloudtrail-logs
        ```

        !!! summary "Sample results"

            ```bash
            123456789010_CloudTrail_us-east-1_20230318T1035Z_dksdeM5YJ305GQqr.json.gz
            123456789010_CloudTrail_us-east-1_20230318T1145Z_hya7foJGvajqVkrL.json.gz
            123456789010_CloudTrail_us-east-1_20230318T1150Z_HfyMXO29h8phuMgw.json.gz
            123456789010_CloudTrail_us-east-1_20230318T1155Z_GzmUZDpzTamyk5q3.json.gz

            <snip>
            ```

### Challenge 3: Detect Honey Token Usage

Review the CloudTrail data looking for evidence of the `HoneyUser` user account performing actions in this AWS account and region.

??? cmd "Solution"

    1. Let's start by looking at your downloaded data. Before that, we need to figure out how to get to the raw data. Since the data is GZIP-compressed, you could extract every one of these files, but there is a better way: using `zcat` to both extract and review the resulant data. View all file content in the `cloudtrail-logs` directory with `zcat`.

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz
        ```

        !!! summary "Expected result"

            WAY TOO MUCH DATA TO SHOW HERE!

    2. That data is quite a lot and is very hard to review manually. Luckily, there is a utility in CloudShell that can rescue you: `jq`. Use `jq` to both present the data in an easier-to-read format and also just view the first record of the first file to see the structure of the log data like so:

        ```bash
        zcat $(ls /home/cloudshell-user/cloudtrail-logs/*.json.gz | head -1) \
         | jq '.Records[0]'
        ```

        !!! summary "Sample results"

            ```bash
            {
            "eventVersion": "1.08",
            "userIdentity": {
                "type": "AWSService",
                "invokedBy": "cloudtrail.amazonaws.com"
            },
            "eventTime": "2023-03-18T10:30:51Z",
            "eventSource": "s3.amazonaws.com",
            "eventName": "GetBucketAcl",
            "awsRegion": "us-east-1",
            "sourceIPAddress": "cloudtrail.amazonaws.com",
            "userAgent": "cloudtrail.amazonaws.com",
            "requestParameters": {
                "bucketName": "cloudlogs-123456789010",
                "Host": "cloudlogs-123456789010.s3.us-east-1.amazonaws.com",
                "acl": ""
            },
            "responseElements": null,
            "additionalEventData": {
                "SignatureVersion": "SigV4",
                "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                "bytesTransferredIn": 0,
                "AuthenticationMethod": "AuthHeader",
                "x-amz-id-2": "pMA3dNprLD8n9BXHH02Z+VIiUGqIWlpn1JNCXBn5dV4Blk7yQ83bz9qG9Qb2E/ljZfpU82mOb80=",
                "bytesTransferredOut": 542
            },
            "requestID": "035F74YAQBE4N0B9",
            "eventID": "82c10c51-1f5d-4de1-b729-4d0c3c45e0d4",
            "readOnly": true,
            "resources": [
                {
                "accountId": "123456789010",
                "type": "AWS::S3::Bucket",
                "ARN": "arn:aws:s3:::cloudlogs-123456789010"
                }
            ],
            "eventType": "AwsApiCall",
            "managementEvent": true,
            "recipientAccountId": "123456789010",
            "sharedEventID": "66965521-4adc-40f5-b23e-ccb05b66bbfb",
            "eventCategory": "Management"
            }
            ```

    3. You may or may not have gotten a record related to an IAM user performing the action because CloudTrail events also record when cloud services and roles are performing activities. We can fix that by using `jq` to extract only those records that contain the `UserName` field. The command below will grab just the results from the first log file using the `select()` filtering option.

        ```bash
        zcat $(ls /home/cloudshell-user/cloudtrail-logs/*.json.gz | head -1) \
         | jq -r '. | select(.Records[].userIdentity.userName != null)'
        ```

        !!! summary "Sample result"

            ```bash
            <snip>

            "eventTime": "2023-03-18T10:32:38Z",
            "eventSource": "s3.amazonaws.com",
            "eventName": "DeleteBucket",
            "awsRegion": "us-east-1",
            "sourceIPAddress": "35.168.12.107",
            "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3api.delete-bucket]",
            "errorCode": "BucketNotEmpty",
            "errorMessage": "The bucket you tried to delete is not empty",
            "requestParameters": {
                "bucketName": "cloudlogs-123456789010",
                "Host": "cloudlogs-123456789010.s3.us-east-1.amazonaws.com"
            },
            "responseElements": null,
            "additionalEventData": {
                "SignatureVersion": "SigV4",
                "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                "bytesTransferredIn": 0,
                "AuthenticationMethod": "AuthHeader",
                "x-amz-id-2": "F3cV/R4LjoAVJ9WunDNQd3i65B6zd8TvIrLwfkeIzHYivBbTBnmpaZI+jsHVwAoFw7a+81cN/9A=",
                "bytesTransferredOut": 322
            },
            "requestID": "19X7HQCD1567PZ1H",
            "eventID": "1b5df64d-f43f-4a30-92c3-48b29ae4a1b4",
            "readOnly": false,
            "resources": [
                {
                "accountId": "123456789010",
                "type": "AWS::S3::Bucket",
                "ARN": "arn:aws:s3:::cloudlogs-123456789010"
                }
            ],
            "eventType": "AwsApiCall",
            "managementEvent": true,
            "recipientAccountId": "123456789010",
            "eventCategory": "Management",
            "tlsDetails": {
                "tlsVersion": "TLSv1.2",
                "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                "clientProvidedHostHeader": "cloudlogs-123456789010.s3.us-east-1.amazonaws.com"
            }

            <snip>
            ```

    4. Now to create a `jq` filter to pull out just the events related to the `HoneyUser` user. We will again use the `select() filter option, but check if the userName field is equal to `HoneyUser`. This command also review all GZIP-compress JSON files.

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select(.userIdentity.userName == "HoneyUser")'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "IAMUser",
                    "principalId": "AIDATAI5Z633QFORB2QCN",
                    "arn": "arn:aws:iam::123456789010:user/HoneyUser",
                    "accountId": "123456789010",
                    "accessKeyId": "AKIATAI5Z6332LPA5KXG",
                    "userName": "HoneyUser"
                },
                "eventTime": "2023-03-18T11:51:28Z",
                "eventSource": "s3.amazonaws.com",
                "eventName": "ListBuckets",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "3.235.120.49",
                "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3api.list-buckets]",
                "errorCode": "AccessDenied",
                "errorMessage": "Access Denied",
                "requestParameters": {
                    "Host": "s3.us-east-1.amazonaws.com"
                },
                "responseElements": null,
                "additionalEventData": {
                    "SignatureVersion": "SigV4",
                    "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "bytesTransferredIn": 0,
                    "AuthenticationMethod": "AuthHeader",
                    "x-amz-id-2": "6m1fgCiEiGWEkphFcgjMD4eJb1BueFMChsExOhlxuO63+CYljg1tts8qwdzuUr5cgTVAHsRiIQE=",
                    "bytesTransferredOut": 243
                },
                "requestID": "3BGZ96T71FHAD1AY",
                "eventID": "40e7146f-f15b-455a-8b84-0fedabf086e1",
                "readOnly": true,
                "eventType": "AwsApiCall",
                "managementEvent": true,
                "recipientAccountId": "123456789010",
                "eventCategory": "Management",
                "tlsDetails": {
                    "tlsVersion": "TLSv1.2",
                    "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "clientProvidedHostHeader": "s3.us-east-1.amazonaws.com"
                }
            }
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "IAMUser",
                    "principalId": "AIDATAI5Z633QFORB2QCN",
                    "arn": "arn:aws:iam::123456789010:user/HoneyUser",
                    "accountId": "123456789010",
                    "accessKeyId": "AKIATAI5Z6332LPA5KXG",
                    "userName": "HoneyUser"
                },
                "eventTime": "2023-03-18T11:52:35Z",
                "eventSource": "ec2.amazonaws.com",
                "eventName": "DescribeInstances",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "3.235.120.49",
                "userAgent": "aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/ec2.describe-instances",
                "errorCode": "Client.UnauthorizedOperation",
                "errorMessage": "You are not authorized to perform this operation.",
                "requestParameters": {
                    "instancesSet": {},
                    "filterSet": {}
                },
                "responseElements": null,
                "requestID": "5682e090-b783-4823-9a15-48fef727c137",
                "eventID": "9b31e889-f920-48d8-a648-81e30ab5f115",
                "readOnly": true,
                "eventType": "AwsApiCall",
                "managementEvent": true,
                "recipientAccountId": "123456789010",
                "eventCategory": "Management",
                "tlsDetails": {
                    "tlsVersion": "TLSv1.2",
                    "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "clientProvidedHostHeader": "ec2.us-east-1.amazonaws.com"
                }
            }
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "IAMUser",
                    "principalId": "AIDATAI5Z633QFORB2QCN",
                    "arn": "arn:aws:iam::123456789010:user/HoneyUser",
                    "accountId": "123456789010",
                    "accessKeyId": "AKIATAI5Z6332LPA5KXG",
                    "userName": "HoneyUser"
                },
                "eventTime": "2023-03-18T11:53:44Z",
                "eventSource": "dynamodb.amazonaws.com",
                "eventName": "ListTables",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "3.235.120.49",
                "userAgent": "aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/dynamodb.list-tables",
                "errorCode": "AccessDenied",
                "errorMessage": "User: arn:aws:iam::123456789010:user/HoneyUser is not authorized to perform: dynamodb:ListTables on resource: arn:aws:dynamodb:us-east-1:123456789010:table/* because no identity-based policy allows the dynamodb:ListTables action",
                "requestParameters": null,
                "responseElements": null,
                "requestID": "KM21C3GVN2GJQU0LV0TQUSJQE7VV4KQNSO5AEMVJF66Q9ASUAAJG",
                "eventID": "4b5aec6a-6a0f-4812-812e-dcd6c6d19d24",
                "readOnly": true,
                "eventType": "AwsApiCall",
                "managementEvent": true,
                "recipientAccountId": "123456789010",
                "eventCategory": "Management",
                "tlsDetails": {
                    "tlsVersion": "TLSv1.2",
                    "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "clientProvidedHostHeader": "dynamodb.us-east-1.amazonaws.com"
                }
            }
            ```

    5. That data is still quite noisy, but it appears that we can find just the `HoneyUser` actions. But what, exactly, was the attacker attempting to perform? Use one more `jq` filter to extract the `eventName` values.

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select(.userIdentity.userName == "HoneyUser") | .eventName'
        ```

        !!! summary "Expected results"

            ```bash
            ListBuckets
            DescribeInstances
            ListTables
            ```

    6. It looks like everything was caught **except** the `aws iam list-users` command. This appears to not show up in the CloudTrail data!

## Conclusion

In this exercise, you walked through an example hunt for ATT&CK technique T1078.004 discovery using a honey user. That was a lot of manual effort. In the next exercise, you will automate this discover with the assistance of a few cloud services.