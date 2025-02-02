# EC2 IMDSv2 Check

This policy checks whether your EC2 instance metadata version is configured with 
Instance Metadata Service Version 2 (IMDSv2). The policy passes if HttpTokens is set to required for IMDSv2. The policy fails HttpTokens is set to optional.
You use instance metadata to configure or manage the running instance. The IMDS provides access to temporary, frequently credentials. These credentials remove the need to hard code or distribute sensitive credentials to instances manually programmatically. The IMDS is attached locally to every EC2 instance. It runs on a special "link local" IP address of 169.254.169.254This IP address is only accessible by software that runs on the instance.
Version 2 of the IMDS adds new protections for the following types of vulnerabilities. 
These vulnerabilities could be used to try to access the IMDS.
- Open website application firewalls
- Open reverse proxies
- Server-side request forgery (SSRF) vulnerabilities
- Open Layer 3 firewalls and network address translation (NAT)

## Policy Details:

- **Policy Name:** ec2-imdsv2-check
- **Check Description:** This policy ensures EC2 instances use Instance Metadata Service Version 2 (IMDSv2)
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create the EC2 Instances:**

    a. Good EC2 Instance (`HttpTokens` is `required` by default)
    ```bash
    aws ec2 run-instances \
    --image-id ami-0e53db6fd757e38c7 \
    --count 1 \
    --instance-type t3a.2xlarge \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=good-instance-01}]' 
    ```

    b. Good EC2 Instance (`HttpEndpoint` is set to `disabled` in which case the instance metadata can't be accessed.)
    ```bash
    aws ec2 run-instances \
    --image-id ami-0e53db6fd757e38c7 \
    --count 1 \
    --instance-type t3a.2xlarge \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=good-instance-02}]' \
    --metadata-options 'HttpEndpoint=disabled'
    ```

    c. Bad EC2 Instance
    ```bash
    aws ec2 run-instances \
    --image-id ami-0e53db6fd757e38c7 \
    --count 1 \
    --instance-type t3a.2xlarge \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bad-instance-01}]' \
    --metadata-options 'HttpTokens=optional'
    ```

    Substitute the values accordingly

2. **Get the Payloads:**

    a. Good Payloads
    ```bash
    aws ec2 describe-instances --filters "Name=tag:Name,Values=good-instance-01" > good-payload-01.json
    ```

    ```bash
    aws ec2 describe-instances --filters "Name=tag:Name,Values=good-instance-02" > good-payload-02.json
    ```

    b. Bad Payload
    ```bash
    aws ec2 describe-instances --filters "Name=tag:Name,Values=bad-instance-01" > bad-payload-01.json 
    ```

3. **Clean Up the Resources:**
    ```bash
    aws ec2 terminate-instances --instance-ids <id-1> <id-2> <id-3>
    ```

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy ec2-imdsv2-check.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - ec2-imdsv2-check / ec2-imdsv2-check /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy ec2-imdsv2-check.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - ec2-imdsv2-check / ec2-imdsv2-check /  FAILED
    -> EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)
    -> all[0].check.~.(Reservations)[0].~.(Instances)[0].(MetadataOptions).(HttpEndpoint == 'disabled' || HttpTokens == 'required'): Invalid value: false: Expected value: true
    Done
    ```

    c. **Test Against Payload to Be Skipped:**
    ```
    kyverno-json scan --payload test/skip-test/skip-payload-01.json --policy ec2-imdsv2-check.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    Done
    ```

---