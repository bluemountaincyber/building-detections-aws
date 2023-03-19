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
* Analyze the data looking for all API calls made related to the download of the honey file

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

### Challenge 2: Download Today's Events

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

### Challenge 3: Detect Honey File Usage

Review the CloudTrail data looking for evidence of the `password-backup.txt` honey file being accessed.

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

    3. You may or may not have gotten a record related to a data event. We can fix that by using `jq` to extract only those records where the `managementEvent` is `false`. The command below will grab just data events from the event data using the `select()` filtering option.

        ```bash
        zcat $(ls /home/cloudshell-user/cloudtrail-logs/*.json.gz) \
         | jq -r '. | select(.Records[].managementEvent == false)'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "Records": [
                    {
                        "eventVersion": "1.08",
                        "userIdentity": {
                            "type": "Root",
                            "principalId": "123456789010",
                            "arn": "arn:aws:iam::123456789010:root",
                            "accountId": "123456789010",
                            "accessKeyId": "ASIATAI5Z633YGJXOFXZ",
                            "userName": "ryanryanic",
                            "sessionContext": {
                                "attributes": {
                                    "creationDate": "2023-03-19T04:54:36Z",
                                    "mfaAuthenticated": "false"
                                }
                            }
                        },
                        "eventTime": "2023-03-19T10:57:19Z",
                        "eventSource": "s3.amazonaws.com",
                        "eventName": "ListObjects",
                        "awsRegion": "us-east-1",
                        "sourceIPAddress": "44.202.147.98",
                        "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.ls]",
                        "requestParameters": {
                            "list-type": "2",
                            "bucketName": "databackup-123456789010",
                            "encoding-type": "url",
                            "prefix": "",
                            "delimiter": "/",
                            "Host": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                        },
                        "responseElements": null,
                        "additionalEventData": {
                            "SignatureVersion": "SigV4",
                            "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                            "bytesTransferredIn": 0,
                            "AuthenticationMethod": "AuthHeader",
                            "x-amz-id-2": "vEFGxniqw03bet/amSETCYdavMQRdTtpYCk+f1GPpsC184l16EZNRMuHBp3nYCUMuSrsyuogRo8ddMv5NtaEvg==",
                            "bytesTransferredOut": 523
                        },
                        "requestID": "5WDT0JW454734NF5",
                        "eventID": "da646419-bad0-4d64-bd4a-1e2b44276299",
                        "readOnly": true,
                        "resources": [
                            {
                                "type": "AWS::S3::Object",
                                "ARNPrefix": "arn:aws:s3:::databackup-123456789010/"
                            },
                            {
                                "accountId": "123456789010",
                                "type": "AWS::S3::Bucket",
                                "ARN": "arn:aws:s3:::databackup-123456789010"
                            }
                        ],
                        "eventType": "AwsApiCall",
                        "managementEvent": false,
                        "recipientAccountId": "123456789010",
                        "eventCategory": "Data",
                        "tlsDetails": {
                            "tlsVersion": "TLSv1.2",
                            "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                            "clientProvidedHostHeader": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                        }
                    }
                ]
            }

            <snip>
            ```

    4. Now we're getting somewhere. You will likely see, if you scroll through the data, the access of the honey file, but let's create one more filter to match just the access of the honey file. To do this, you may have noticed that the file name is included in the `.requestParameters.key` field and the `eventName` is `GetObject`. You can combine both of those cases in the following command:

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select((.eventName == "GetObject") and .requestParameters.key == "password-backup.txt")'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "Root",
                    "principalId": "123456789010",
                    "arn": "arn:aws:iam::123456789010:root",
                    "accountId": "123456789010",
                    "accessKeyId": "ASIATAI5Z633WXL7W5UQ",
                    "userName": "ryanryanic",
                    "sessionContext": {
                        "attributes": {
                            "creationDate": "2023-03-19T04:54:36Z",
                            "mfaAuthenticated": "false"
                        }
                    }
                },
                "eventTime": "2023-03-19T11:00:50Z",
                "eventSource": "s3.amazonaws.com",
                "eventName": "GetObject",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "44.202.147.98",
                "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.cp]",
                "requestParameters": {
                    "bucketName": "databackup-123456789010",
                    "Host": "databackup-123456789010.s3.us-east-1.amazonaws.com",
                    "key": "password-backup.txt"
                },
                "responseElements": null,
                "additionalEventData": {
                    "SignatureVersion": "SigV4",
                    "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "bytesTransferredIn": 0,
                    "AuthenticationMethod": "AuthHeader",
                    "x-amz-id-2": "nKl0ChcIi+IUpXN2b7DHChT9ivctg5wEOC+aoLZBVK8AF5GPuAcUCAco3SETgystQmjyabnMd3o=",
                    "bytesTransferredOut": 91
                },
                "requestID": "X3WAD8N3JFZKSY05",
                "eventID": "7adf0612-f936-4368-bccb-6a2afde40d15",
                "readOnly": true,
                "resources": [
                    {
                    "type": "AWS::S3::Object",
                    "ARN": "arn:aws:s3:::databackup-123456789010/password-backup.txt"
                    },
                    {
                    "accountId": "123456789010",
                    "type": "AWS::S3::Bucket",
                    "ARN": "arn:aws:s3:::databackup-123456789010"
                    }
                ],
                "eventType": "AwsApiCall",
                "managementEvent": false,
                "recipientAccountId": "123456789010",
                "eventCategory": "Data",
                "tlsDetails": {
                    "tlsVersion": "TLSv1.2",
                    "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "clientProvidedHostHeader": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                }
            }
            ```

    5. Now we're down to the single record (unless you downloaded the file multiple times). But that record is still quite busy. Let's extent that filter one final time to extract the following key details about the attacker:

        | Field | Description |
        |:------|:------------|
        | `userIdentity.userName` | The AWS username (IAM user) or account alias (root user) that made the request |
        | `sourceIPAddress` | The client IP address |
        | `eventTime` | The time of the request |
        | `eventName` | The name of the API call |
        | `requestParameters.bucketName` | The name of the S3 bucket where the file is stored |
        | `requestParameters.key` | The name of the downloaded file |
        | `userAgent` | The likely application that interacted with AWS |

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select((.eventName == "GetObject") and '\
        '.requestParameters.key == "password-backup.txt") | '\
        '{"userName": .userIdentity.userName, '\
        '"sourceIPAddress": .sourceIPAddress, '\
        '"eventTime": .eventTime, '\
        '"bucketName": .requestParameters.bucketName, '\
        '"fileName": .requestParameters.key, '\
        '"userAgent": .userAgent}'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "userName": "ryanryanic",
                "sourceIPAddress": "44.202.147.98",
                "eventTime": "2023-03-19T11:00:50Z",
                "bucketName": "databackup-123456789010",
                "fileName": "password-backup.txt",
                "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.cp]"
            }
            ```

## Conclusion

In this exercise, you walked through an example hunt for ATT&CK technique T1530 (Data from Cloud Storage) using a honey file and some slicing and dicing of CloudTrail data events. That was a lot of manual effort. In the next exercise, you will automate this discovery with the assistance of a few cloud services.