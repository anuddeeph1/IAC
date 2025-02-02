# Check EC2 IAM Role

An IAM role acts as an identity with specific permission policies that determine the allowed and disallowed actions within AWS. Creating IAM roles and attaching them to manage permissions for EC2 instances ensures that access is controlled and temporary credentials are used, enhancing security.

## Policy Details:

- **Policy Name:** check-ec2-iam-role
- **Check Description:** This policy ensures that an IAM role is attached to an EC2 instance
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create the EC2 Instances:**

    a. Good EC2 Instance
    ```bash
    aws ec2 run-instances \
    --image-id ami-0e53db6fd757e38c7 \
    --count 1 \
    --instance-type t3a.2xlarge \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=good-instance-01}]' \
    --iam-instance-profile Name=ec2-role
    ```

    b. Bad EC2 Instance
    ```bash
    aws ec2 run-instances \
    --image-id ami-0e53db6fd757e38c7 \
    --count 1 \
    --instance-type t3a.2xlarge \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bad-instance-01}]'
    ```

    Substitute the values accordingly

2. **Get the Payloads:**

    a. Good Payload
    ```bash
    aws ec2 describe-instances --filters "Name=tag:Name,Values=good-instance-01" > good-payload-01.json
    ```

    b. Bad Payload
    ```bash
    aws ec2 describe-instances --filters "Name=tag:Name,Values=bad-instance-01" > bad-payload-01.json 
    ```

3. **Clean Up the Resources:**
    ```bash
    aws ec2 terminate-instances --instance-ids <id-1> <id-2>
    ```

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy check-ec2-iam-role.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-iam-role / check-ec2-iam-role /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy check-ec2-iam-role.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-iam-role / check-ec2-iam-role /  FAILED
    -> IAM Instance Profile must be attached to EC2 instances
    -> all[0].check.~.(Reservations)[0].~.(Instances)[0].(IamInstanceProfile != null): Invalid value: false: Expected value: true
    Done
    ```

---