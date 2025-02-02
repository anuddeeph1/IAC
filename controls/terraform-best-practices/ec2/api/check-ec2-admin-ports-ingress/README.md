# Check EC2 Admin Ports Ingress

EC2 security groups should not allow ingress from `0.0.0.0/0` to remote server administration ports.
This policy checks whether an Amazon EC2 security group allows ingress from `0.0.0.0/0` to remote server administration ports (ports `22` and `3389`). 
The policy fails if the security group allows ingress from `0.0.0.0/0` to port `22` or `3389`. Security groups provide stateful filtering of ingress and egress 
network traffic to AWS resources. It is recommended that no security group allow unrestricted ingress 
access to remote server administration ports, such as SSH to port `22` and RDP to port `3389`, using either the TDP (6), UDP (17), or ALL (-1) protocols. 
Permitting public access to these ports increases resource attack surface and the risk of resource compromise.

## Policy Details:

- **Policy Name:** check-ec2-admin-ports-ingress
- **Check Description:** This policy checks whether an Amazon EC2 security group allows ingress from `0.0.0.0/0` to remote server administration ports (ports `22` and `3389`). 
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create the Security Groups:**

    a. Good SG

    `good-sg-01` (Ports `22` and `3389` are open to a specific IP `192.168.1.0/24`, and not `0.0.0.0/0`)

    ```bash
    aws ec2 create-security-group \
    --group-name good-sg-01 \
    --description "Compliant SG, no unrestricted SSH or RDP" \
    --vpc-id <vpc-id>
    ```

    ```bash
    aws ec2 authorize-security-group-ingress \
    --group-name good-sg-01 \
    --protocol tcp \
    --port 22 \
    --cidr 192.168.1.0/24
    ```

    ```bash
    aws ec2 authorize-security-group-ingress \
    --group-name good-sg-01 \
    --protocol tcp \
    --port 3389 \
    --cidr 192.168.1.0/24
    ```

    `good-sg-02` (Does not have ingress permissions)

    ```bash
    aws ec2 create-security-group   --group-name good-sg-02   --description "Compliant SG"   --vpc-id <vpc-id>
    ```

    b. Bad SG
    
    `bad-sg-01` (Allows ingress from `0.0.0.0/0` to port `22`)

    ```bash
    aws ec2 create-security-group \
    --group-name bad-sg-01 \
    --description "Non-compliant SG, allows SSH from anywhere" \
    --vpc-id <vpc-id>
    ```

    ```bash
    aws ec2 authorize-security-group-ingress \
    --group-name bad-sg-01 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
    ```

    `bad-sg-02` (Allows ingress from `0.0.0.0/0` to port `3389`)

    ```bash
    aws ec2 create-security-group \
    --group-name bad-sg-02 \
    --description "Non-compliant SG, allows RDP from anywhere" \
    --vpc-id <vpc-id>
    ```

    ```bash
    aws ec2 authorize-security-group-ingress \
    --group-name bad-sg-02 \
    --protocol tcp \
    --port 3389 \
    --cidr 0.0.0.0/0
    ```

    Substitute `vpc-id` accordingly

2. **Get the Payloads:**

    a. Good Payloads

    ```bash
    aws ec2 describe-security-groups --group-names good-sg-01 > good-payload-01.json
    ```

    ```bash
    aws ec2 describe-security-groups --group-names good-sg-02 > good-payload-02.json
    ```

    b. Bad Payloads

    ```bash
    aws ec2 describe-security-groups --group-names bad-sg-01 > bad-payload-01.json
    ```

    ```bash
    aws ec2 describe-security-groups --group-names bad-sg-02 > bad-payload-02.json
    ```

3. **Clean Up the Resources:**
    ```bash
    aws ec2 delete-security-group --group-name good-sg-01
    aws ec2 delete-security-group --group-name good-sg-02
    aws ec2 delete-security-group --group-name bad-sg-01
    aws ec2 delete-security-group --group-name bad-sg-02
    ```

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy check-ec2-admin-ports-ingress.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-admin-ports-ingress / check-ec2-admin-ports-ingress /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy check-ec2-admin-ports-ingress.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-admin-ports-ingress / check-ec2-admin-ports-ingress /  FAILED
    -> EC2 security group should not allow ingress from 0.0.0.0/0 to remote server administration ports (ports 22 and 3389)
    -> all[0].check.~.(SecurityGroups)[0].~.(IpPermissions[?ToPort == `22` || ToPort == `3389`])[0].~.(IpRanges)[0].(CidrIp != '0.0.0.0/0'): Invalid value: false: Expected value: true
    Done
    ```

---