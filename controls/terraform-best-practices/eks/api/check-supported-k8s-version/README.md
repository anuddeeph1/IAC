# Check Standard Supported K8s Version on AWS EKS

Using a standard Kubernetes version ensures access to the latest features, security updates, and community support. It’s more cost-effective than extended support versions, as AWS charges extra for extended support while standard versions offer faster updates and new capabilities at no additional cost.

## Policy Details:

- **Policy Name:** check-supported-k8s-version
- **Check Description:** Ensure AWS EKS Cluster is created using Standard Supported K8s Version
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    a. Bad EKS Clusters

    Bad Cluster (The K8s version is set to an extended support version)
    ```bash
    aws eks create-cluster \
    --name bad-eks-cluster \
    --role-arn <eks-cluster-role> \
    --version 1.27 \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
    --region us-west-2
    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    b. Good EKS Clusters

    Good EKS Cluster (The K8s version is set to an standard support version)
    ```bash
    aws eks create-cluster \
    --name good-eks-cluster \
    --role-arn <eks-cluster-role> \
    --version 1.31 \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
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
    kyverno-json scan --policy check-supported-k8s-version.yaml --payload test/good-test/good-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-supported-k8s-version / check-supported-k8s-version /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-supported-k8s-version.yaml --payload test/bad-test/bad-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-standard-supported-k8s-version / check-standard-supported-k8s-version /  FAILED
    -> Version specified must be one of these suppported versions ['1.29', '1.30', '1.31']
    -> all[0].check.cluster.version.(contains($supported_k8s_versions, @)): Invalid value: false: Expected value: true
    Done
    ```

---