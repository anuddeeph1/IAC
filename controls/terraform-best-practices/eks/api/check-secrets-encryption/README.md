# Check Secrets Encryption on AWS EKS

Secrets encryption is a crucial security measure that ensures sensitive data, such as secrets, passwords, and credentials, stored within Kubernetes, is encrypted. This adds an essential layer of protection by preventing unauthorized access to confidential information, even in the event of a security breach. By leveraging encryption mechanisms, such as AWS KMS or other providers, Kubernetes ensures that secrets are securely stored and transmitted, reducing the risk of exposure and enhancing the overall security posture of the cluster.

## Policy Details:

- **Policy Name:** check-secrets-encryption
- **Check Description:** Ensure AWS EKS Cluster is created using Secrets Encryption
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    a. Bad EKS Clusters

    Bad Cluster (The encryptionConfig is not defined with a keyArn)
    ```bash
    aws eks create-cluster \
    --name example-cluster \
    --role-arn arn:aws:iam::xxxx:role/example-role \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 securityGroupIds=sg-xxxx \
    --region us-west-2

    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    b. Good EKS Clusters

    Good EKS Cluster (The encryptionConfig is defined with a keyArn)
    ```bash
    aws eks create-cluster \
    --name example-cluster \
    --role-arn arn:aws:iam::ACCOUNT_ID:role/EKSClusterRole \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 securityGroupIds=sg-xxxx \
    --encryption-config "resources=[secrets],provider={keyArn=arn:aws:kms:us-west-2:xxxx:key/YOUR_KMS_KEY}" \
    --region us-west-2
    ```


    Substitute subnet-id-1 and subnet-id-2 accordingly

2. **Get the Payloads:**
    ```bash
    aws eks describe-cluster --name <cluster-name> > <bad-good>-payload-<number>.json
    ```

    Run the above query for each cluster that we created in step 1

3. **Clean Up the Resources Created**

4. **Test the Policy with Kyverno:**
    ```
    kyverno-json scan --payload payload.json --policy policy.yaml
    ```
    
    a. **Test Policy Against Valid Payload:**
    ```
    kyverno-json scan --policy check-secrets-encryption.yaml --payload test/good-test/good-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-secrets-encryption / check-secrets-encryption /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-secrets-encryption.yaml --payload test/bad-test/bad-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-secrets-encryption / check-secrets-encryption /  FAILED
    -> Secrets encryption is enabled. The field cluster.encryptionConfig is defined for secrets.
    -> all[0].check.cluster.(encryptionConfig[].resources[] | contains(@, 'secrets')): Invalid value: false: Expected value: true
    Done
    ```

---