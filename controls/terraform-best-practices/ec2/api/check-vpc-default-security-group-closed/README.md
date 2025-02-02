# Check VPC Default Security Group Closed

This policy checks whether the default security group of a VPC allows inbound or outbound traffic. 
The policy fails if the security group allows inbound or outbound traffic.
The rules for the default security group allow all outbound and inbound traffic from network interfaces (and their associate instances) 
that are assigned to the same security group. We recommend that you don't use the default security group. 
Because the default security group cannot be deleted, you should change the default security group rules setting to restrict 
inbound and outbound traffic. This prevents unintended traffic if the default security group is accidentally configured for resourcesuch as EC2 instances.
You can read more about it [here](https://docs.aws.amazon.com/securityhub/latest/userguide/ec2-controls.html#ec2-2)

## Policy Details:

- **Policy Name:** check-vpc-default-security-group-closed
- **Check Description:** This policy ensures that the default security group of a VPC does not allow inbound or outbound traffic. 
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Get the Payload for the `default` security groups:**

    a. Bad Payload (The default SG created will allow all outbound and inbound traffic)
    ```bash
    aws ec2 describe-security-groups --filters Name=group-name,Values=default > bad-payload-01.json
    ```

    b. Good Payload
    Use the AWS Console to remove the inbound and outbound rules of the default SG
    ```bash
    aws ec2 describe-security-groups --filters Name=group-name,Values=default > good-payload-01.json
    ```

2. **Test the Policy with Kyverno:**

    ```bash
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy check-vpc-default-security-group-closed.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-vpc-default-security-group-closed / check-vpc-default-security-group-closed /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy check-vpc-default-security-group-closed.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-vpc-default-security-group-closed / check-vpc-default-security-group-closed /  FAILED
    -> Default security group of a VPC should not allow inbound or outbound traffic.
    -> all[0].check.~.(SecurityGroups[?GroupName == 'default'])[0].(IpPermissionsEgress == `[]`): Invalid value: false: Expected value: true
    -> all[0].check.~.(SecurityGroups[?GroupName == 'default'])[0].(IpPermissions == `[]`): Invalid value: false: Expected value: true
    Done
    ```

    c. **Test Against Payload to Be Skipped:**
    ```
    kyverno-json scan --payload test/skip-test/skip-payload-01.json --policy check-vpc-default-security-group-closed.yaml 
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