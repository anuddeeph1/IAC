# Check Control Plane Logging for Amazon EKS

Enabling Amazon EKS control plane logging for all log types is a best practice for enhancing the security, monitoring, troubleshooting, performance optimization, and operational management of your Kubernetes clusters. By capturing comprehensive logs of control plane activities, you can effectively manage and secure your EKS infrastructure while ensuring compliance with regulatory requirements and industry standards.

You should enable control plane logging for all these types: "api", "audit", "authenticator", "controllerManager" and "scheduler". You can read more about the log types [here](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)

## Policy Details:

- **Policy Name:** check-control-plane-logging
- **Check Description:** Ensure Amazon EKS control plane logging is enabled for all log types
- **Policy Category:** EKS Best Practices 

### Policy Validation Testing Instructions

For testing this policy you will need to:
- Make sure you have `kyverno-json` installed on the machine 
- Properly authenticate with AWS

1. **Create EKS Clusters:**

    a. Bad EKS Clusters

    Bad Cluster 1 (No logging types specified. Every type defaults to disabled)
    ```bash
    aws eks create-cluster \
    --name bad-eks-cluster-01 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2
    ```

    Bad Cluster 2 (Explicitly specifying certain logging types as false)
    ```bash
    aws eks create-cluster \
    --name bad-eks-cluster-02 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 --logging '{"clusterLogging":[{"types":["controllerManager","scheduler"],"enabled":false}]}'
    ```

    Bad Cluster 3 (Only some logging types are enabled)
    ```bash
    aws eks create-cluster \
    --name bad-eks-cluster-03 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 --logging '{"clusterLogging":[{"types":["audit","scheduler"],"enabled":true}]}'
    ```

    Substitute subnet-id-1 and subnet-id-2 accordingly

    b. Good EKS Clusters

    Good EKS Cluster 1 (All logging types are enabled)
    ```bash
    aws eks create-cluster \
    --name good-eks-cluster-01 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
    ```

    Good EKS Cluster 2 
    (All logging types are enabled by using two elements within `clusterLogging`, 
    `{"types":["api","audit","authenticator"],"enabled":true}` and `{"types":["controllerManager","scheduler"],"enabled":true}]}` 
    This ultimately gives a response with one element in `clusterLogging` where `enabled: true`)
    ```bash
    aws eks create-cluster \
    --name good-eks-cluster-01 \
    --role-arn <eks-cluster-role> \
    --resources-vpc-config subnetIds=subnet-id-1,subnet-id-2 \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator"],"enabled":true},{"types":["controllerManager","scheduler"],"enabled":true}]}'
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
    kyverno-json scan --policy check-control-plane-logging.yaml --payload test/good-test/good-payload-01.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-control-plane-logging / check-control-plane-logging /  PASSED
    Done
    ```

    b. **Test Against Invalid Payload:**
    ```
    kyverno-json scan --policy check-control-plane-logging.yaml --payload test/bad-test/bad-payload-01.json 
    ```

    This produces the output:
    ```bash
    Loading policies ...
    Loading payload ...
    Pre processing ...
    Running ( evaluating 1 resource against 1 policy ) ...
    - check-control-plane-logging / check-control-plane-logging /  FAILED
    -> EKS control plane logging must be enabled for all log types
    -> all[0].check.cluster.logging.(clusterLogging[?enabled == `true`] | length(@) == `1`): Invalid value: false: Expected value: true
    Done
    ```

---