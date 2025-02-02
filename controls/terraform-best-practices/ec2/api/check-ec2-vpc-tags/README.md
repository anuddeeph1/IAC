# Check EC2 VPC Tags

This control checks whether an Amazon Virtual Private Cloud (Amazon VPC) has tags with the specific keys
defined in the parameter requiredTagKeys. The control fails if the Amazon VPC doesn't have any tag keys or if it doesn't 
have all the keys specified in the parameter requiredTagKeys. If the parameter requiredTagKeys isn't provided, the control only checks 
for the existence of a tag key and fails if the Amazon VPC isn't tagged with any key. System tags, which are automatically applied and begin with aws:, 
are ignored. A tag is a label that you assign to an AWS resource, and it consists of a key and an optional value. 
You can create tags to categorize resources by purpose, owner, environment, or other criteria. Tags can help you identify, organize, search for, and filteresources. 
Tagging also helps you track accountable resource owners for actions and notifications.

This policy checks to ensure that both `Environment` and `Owner` tags are present in the VPC. You can customize this according to your needs.

## Policy Details:

- **Policy Name:** check-ec2-vpc-tags
- **Check Description:** This policy ensures that the required tags are present in the VPC
- **Policy Category:** AWS EC2 Best Practices

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create the EC2 Instances:**

    a. Good VPC
    ```bash
    aws ec2 create-vpc \
    --cidr-block 10.2.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Owner,Value=JohnDoe},{Key=Environment,Value=Production}]'
    ```

    b. Bad VPCs

    `Bad VPC 1` (No Tags)
    ```bash
    aws ec2 create-vpc \
    --cidr-block 10.1.0.0/16
    ```

    `Bad VPC 2` (Only contains `Environment` tag)
    ```bash
    aws ec2 create-vpc \
    --cidr-block 10.2.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Environment,Value=Production}]'
    ```

2. **Get the Payloads:**

    ```bash
    aws ec2 describe-vpcs --vpc-ids <vpc-id> > <good-bad>-payload-<number>.json
    ```

3. **Clean Up the Resources:**
    ```bash
    aws ec2 delete-vpc --vpc-id <vpc-id>
    ```

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```

    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --payload test/good-test/good-payload-01.json --policy check-ec2-vpc-tags.yaml 
    ```

    This produces the output:
    ```
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-vpc-tags / check-ec2-vpc-tags /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --payload test/bad-test/bad-payload-01.json --policy check-ec2-vpc-tags.yaml 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-ec2-vpc-tags / check-ec2-vpc-tags /  FAILED
    -> VPCs must be tagged with the required keys
    -> all[0].check.(Vpcs[].Tags[].Key)->keys.~.($requiredTagKeys)[0].(contains($keys, @)): Invalid value: false: Expected value: true
    -> all[0].check.(Vpcs[].Tags[].Key)->keys.~.($requiredTagKeys)[1].(contains($keys, @)): Invalid value: false: Expected value: true
    Done
    ```

---