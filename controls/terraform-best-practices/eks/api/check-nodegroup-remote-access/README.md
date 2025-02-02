# Check Nodegroup Remote Access

As a general security measure, it's crucial to ensure that your AWS EKS node group does not have implicit SSH access from 0.0.0.0/0, thus not being accessible over the internet. This protects your EKS node group from unauthorized access by external entities.

To avoid unauthorized access of Nodegroup define sourceSecurityGroups. You can read more about Nodegroup Remote Access [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-eks-nodegroup-remoteaccess.html)

## Policy Details:

- **Policy Name:** check-nodegroup-remote-access
- **Check Description:** Ensure AWS EKS node group does not have implicit SSH access from 0.0.0.0/0
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    ```bash
    aws eks create-cluster \
    --name example-cluster \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
    --region us-west-2
    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    Creating Good NodeGroup
    ```bash
    aws eks create-nodegroup \
    --cluster-name example-cluster \
    --nodegroup-name good-example-node-group \
    --node-role arn:aws:iam::<account-id>:role/example-role \
    --subnets subnet-id-1,subnet-id-2 \
    --scaling-config minSize=2,maxSize=4,desiredSize=2 \
    --remote-access ec2SshKey="some-key",sourceSecurityGroups=["sg-12345678"]

    ```

    Substitute subnet-id-1, subnet-id-2 and account-id accordingly

    Creating Bad NodeGroup
    ```bash
    aws eks create-nodegroup \
    --cluster-name example-cluster \
    --nodegroup-name good-example-node-group \
    --node-role arn:aws:iam::<account-id>:role/example-role \
    --subnets subnet-id-1,subnet-id-2 \
    --scaling-config minSize=2,maxSize=4,desiredSize=2 \
    --remote-access ec2SshKey="some-key"

    ```

    Substitute subnet-id-1, subnet-id-2 and account-id accordingly

2. **Get the Payloads:**
    ```bash
    aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --region <region> --output json > <bad-good>-payload-<number>.json
    ```

    Run the above query for each Nodegroup in the cluster that we created in step 1

3. **Clean Up the Resources Created**

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```
    
    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --policy check-nodegroup-remote-access.yaml --payload test/good-test/good-payload-1.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-nodegroup-remote-access / check-nodegroup-remote-access /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-nodegroup-remote-access.yaml --payload test/bad-test/bad-payload-1.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-nodegroup-remote-access / check-nodegroup-remote-access /  FAILED
    -> AWS EKS node group should not have implicit SSH access from 0.0.0.0/0
    -> all[0].check.nodegroup.remoteAccess.((!ec2SshKey == `false`) && (!sourceSecurityGroups == `true`)): Invalid value: true: Expected value: false
    Done
    ```

---