# Check Public Endpoint access to AWS EKS
 	
Ensuring that the Amazon EKS public endpoint is not accessible to 0.0.0.0/0 is a fundamental security measure that helps protect your EKS clusters from unauthorized access, security threats, and compliance violations.

## Policy Details:

- **Policy Name:** check-public-access-cidr
- **Check Description:** Ensuring that the Amazon EKS public endpoint is not accessible to 0.0.0.0/0
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    a. Bad EKS Clusters

    Bad Cluster (Endpoint Public Access is set to True and publicAccessCidrs is not defined.)
    ```bash
    aws eks create-cluster \
    --name bad-cluster-1 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2, \
    endpointPublicAccess=true, endpointPrivateAccess=true \
    --region us-west-2
    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    b. Good EKS Clusters

    Good EKS Cluster (Endpoint Public Access is set to True and publicAccessCidrs is defined.)
    ```bash
    aws eks create-cluster \
    --name good-cluster-1 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2, \
    endpointPublicAccess=true, publicAccessCidrs="192.168.0.0/16", endpointPrivateAccess=true \
    --region us-west-2
    ```
    
    Good EKS Clusters (Endpoint Public Access is set to False, Default is true when not set)
    ```bash
    aws eks create-cluster \
    --name good-cluster-2 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2, \
    endpointPublicAccess=false, endpointPrivateAccess=true \
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
    kyverno-json scan --policy check-public-access-cidr.yaml --payload test/good-test/good-payload-1.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-public-access-cidr / check-public-access-cidr /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-public-access-cidr.yaml --payload test/bad-test/bad-payload-1.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-public-access-cidr / check-public-access-cidr /  FAILED
    -> Ensuring that the Amazon EKS public endpoint is not accessible to 0.0.0.0/0
    -> any[0].check.cluster.resourcesVpcConfig.(endpointPublicAccess): Invalid value: true: Expected value: false
    -> Ensuring that the Amazon EKS public endpoint is not accessible to 0.0.0.0/0
    -> any[1].check.cluster.resourcesVpcConfig.(endpointPublicAccess == `true` && publicAccessCidrs[?@ == '0.0.0.0/0'] | length(@) == `0`): Invalid value: false: Expected value: true
    Done
    ```

---