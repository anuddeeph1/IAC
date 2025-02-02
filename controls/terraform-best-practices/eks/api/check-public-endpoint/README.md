# Check Public Endpoint access to AWS EKS

Disabling the public endpoint minimizes the risk of unauthorized access and potential security breaches by reducing the attack surface of the EKS control plane. 
It protects against external threats and enforces network segmentation, restricting access to only trusted entities within the network environment. 
This measure helps organizations meet compliance requirements, maintains operational security, and safeguards the reliability and performance of Kubernetes clusters.

To disable public access to the control plane, ensure that **endpointPublicAccess** is set to *false* explicitly. You can read more about endpoint access control [here](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html)

## Policy Details:

- **Policy Name:** check-public-endpoint
- **Check Description:** Ensure public endpoint access to AWS EKS is disabled
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    a. Bad EKS Clusters

    Bad Cluster (Endpoint Public Access is set to True, Default is true when not set)
    ```bash
    aws eks create-cluster \
    --name bad-eks-cluster \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
    --region us-west-2
    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    b. Good EKS Clusters

    Good EKS Cluster (Endpoint Public Access is set to False, Default is true when not set)
    ```bash
    aws eks create-cluster \
    --name good-eks-cluster \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2, endpointPublicAccess=false,endpointPrivateAccess=true \
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
    kyverno-json scan --policy check-public-endpoint.yaml --payload test/good-test/good-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-public-endpoint / check-public-endpoint /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-public-endpoint.yaml --payload test/bad-test/bad-payload.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-public-endpoint / check-public-endpoint /  FAILED
    -> Public access to EKS cluster endpoint must be explicitly set to false
    -> all[0].check.cluster.resourcesVpcConfig.(endpointPublicAccess): Invalid value: true: Expected value: false
    Done
    ```

---