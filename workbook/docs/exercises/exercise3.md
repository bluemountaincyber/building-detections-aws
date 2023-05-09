# Exercise 3: Attacking the Cloud Account

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #ff0000;
}
</style>

**Estimated Time to Complete:** 10 minutes

## Objectives

* Act as an attacker in the following ways to generate log data which will help build your detection and automation:
    * Perform discovery of S3 resources - ATT&CK Technique T1619 (Cloud Storage Object Discovery)
    * Download an interesting file - ATT&CK Technique T1530 (Data from Cloud Storage)

## Challenges

### Challenge 1: Perform ATT&CK Technique T1619 (Cloud Storage Object Discovery)

Using either the AWS Management Console or the AWS CLI (which is shown in the solution below), perform reconnaissance of the S3 buckets. You will find that one contains some interesting data that an attacker may be tempted to download.

??? cmd "Solution"

    1. Return to your CloudShell session (you may need to refresh the page if it timed out).

    2. Discovering cloud resources can be quite simple with the AWS CLI tool as many services have operations prefixed with `describe-` or `list-` to give high-level information about the resources deployed in a cloud service. For the S3 service, the operation to list all buckets is the aptly-named `list-buckets`.

        ```bash
        aws s3api list-buckets
        ```

        !!! summary "Sample results"

            ```bash
            {
                "Buckets": [
                    {
                        "Name": "cloudlogs-123456789010",
                        "CreationDate": "2023-03-19T10:19:13+00:00"
                    },
                    {
                        "Name": "databackup-123456789010",
                        "CreationDate": "2023-03-19T10:15:32+00:00"
                    }
                ],
                "Owner": {
                    "DisplayName": "ryan",
                    "ID": "e9c322584d211fe214b82aa1a508e8720ed920d53fb3a9c1b8d5625a354abcde"
                }
            }
            ```

    3. When you see your results, you can scroll through the data using your arrow keys on your keyboard. When finished, press `q` to exit. 
    
    4. You should have seen two buckets: one beginning with `cloudlogs-` and one beginning with `databackup-`. To drill into those buckets to view any files or folders, you can use the `aws s3 ls` command like so (the first command acquires your bucket name beginning with `cloudlogs-` programmatically):

        ```bash
        BUCKET=$(aws s3api list-buckets | jq -r \
          '.Buckets[] | select(.Name | startswith("cloudlogs-")) | .Name')
        aws s3 ls s3://$BUCKET/
        ```

        !!! summary "Expected result"

            ```bash
                                       PRE AWSLogs/
            ```

    5. Yep. Looks like there may be logs in this bucket given the first folder's name. This is commonly found at the root or a customer-defined prefix within an S3 bucket if logging is enabled on a service and writing to S3 (like you did with CloudTrail in the last exercise). If the attacker has write access here, they may be able to delete this log data! Luckily, that is not what we're emulating in this exercise, so take a look at the other bucket.

        ```bash
        BUCKET=$(aws s3api list-buckets | jq -r \
          '.Buckets[] | select(.Name | startswith("databackup-")) | .Name')
        aws s3 ls s3://$BUCKET/
        ```

        !!! summary "Sample result"

            ```bash
            2023-03-19 10:16:30         91 password-backup.txt
            ```

    6. Now *that* looks interesting!

### Challenge 2: Perform ATT&CK Technique T1530 (Data from Cloud Storage)

Now that you found your interesting file, download and review it.

??? cmd "Solution"

    1. To download data from S3 using the AWS CLI, the `aws s3 cp` or `aws s3 sync` operations can be used. We'll use the `cp` option since we're just downloading a single file (although there is a `recursive` option to download more than one file at a time).

        ```bash
        aws s3 cp s3://$BUCKET/password-backup.txt /home/cloudshell-user/password-backup.txt
        ```

        !!! summary "Sample result"

            ```bash
            download: s3://databackup-123456789010/password-backup.txt to ../password-backup.txt
            ```

    2. Review the file with the `cat` command.

        ```bash
        cat /home/cloudshell-user/password-backup.txt 
        ```

        !!! summary "Sample result"

            ```bash
            AWS Root: admin@sherlock.com    | P@ssw0rd1234
            Sherlock: sherlock@sherlock.com | $h3rL0ck!
            ```

    3. Congratulations! You have just emulated an attacker finding a file or interest, downloading it, and reviewing it.

## Conclusion

Now that you have successfully located and pulled down the honey file, the next exercise will explore how to identify this access.
