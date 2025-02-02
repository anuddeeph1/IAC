# Subnet Auto Assign Public IP Disabled

This policy checks whether the assignment of public IPs in Amazon Virtual Private Cloud (Amazon VPC) subnets have `MapPublicIpOnLaunch` set to `FALSE`. The policy passes if the flag is set to `FALSE`. All subnets have an attribute that determines whether a network interface created in the subnet automatically receives a public IPv4 address. subnets that are launched into subnets that have this attribute enabled have a public IP address assigned to their primary network interface. Public IP addresses can make EC2 subnets directly accessible from the internet, which might not always be desirable from a security or compliance standpoint. In many cases, you might not want your EC2 subnets to have public IP addresses unless they need to be publicly accessible. Having a public IP address can expose your EC2 subnet to potential security risks, such as unauthorized access or attacks.

## Policy Details:

- **Policy Name:** subnet-auto-assign-public-ip-disabled
- **Check Description:** This policy checks EC2 subnets do not automatically assign public IP addresses
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create the Subnet:**

    a. Good Subnet (`MapPublicIpOnLaunch` is `false` by default)
    ```bash
    aws ec2 create-subnet \
    --vpc-id vpc-0a0e88c4f0aa13753 \
    --cidr-block 172.31.48.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=good-subnet-01}]'
    ```

    b. Bad Subnet 
    ```bash
    aws ec2 create-subnet \
    --vpc-id vpc-0a0e88c4f0aa13753 \
    --cidr-block 172.31.64.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=bad-subnet-01}]'
    ```

    Modify it to set `--map-public-ip-on-launch`
    ```bash
    aws ec2 modify-subnet-attribute --subnet-id <bad-subnet-01-id> --map-public-ip-on-launch 
    ```

    Substitute the values accordingly

2. **Get the Payloads:**

    a. Good Payload
    ```bash
    aws ec2 describe-subnets --subnet-ids <subnet-id> > good-payload-01.json
    ```

    b. Bad Payload
    ```bash
    aws ec2 describe-subnets --subnet-ids <subnet-id> > bad-payload-01.json
    ```

3. **Clean Up the Resources:**
    ```bash
    aws ec2 delete-subnet --subnet-id <subnet-id>
    ```

4. **Test the Policy with Kyverno:**

    ```bash
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**

    ```bash
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy subnet-auto-assign-public-ip-disabled.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - subnet-auto-assign-public-ip-disabled / subnet-auto-assign-public-ip-disabled /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**

    ```bash
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy subnet-auto-assign-public-ip-disabled.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - subnet-auto-assign-public-ip-disabled / subnet-auto-assign-public-ip-disabled /  FAILED
    -> EC2 subnets should not automatically assign public IP addresses
    -> all[0].check.~.(Subnets)[0].(MapPublicIpOnLaunch): Invalid value: true: Expected value: false
    Done
    ```

    c. **Test Against Payload to Be Skipped:**
    ```
    kyverno-json scan --payload test/skip-test/skip-payload-01.json --policy subnet-auto-assign-public-ip-disabled.yaml 
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