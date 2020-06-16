## Run EKS Windows containers with group Managed Service Account (gMSA)

This repository contains cloudformation templates, powershell scripts, kubernetes deployment configurations and sample applications required to set up AWS managed Active Directory and gMSA account setup to demonstrate gMSA end-to-end workflow with Amazon Elastic Kubernetes Services (EKS) cluster.

NOTE: gMSA functionality has been validated on EKS v1.14 master with v1.14 worker nodes, v1.16. EKS master with v1.16 worker nodes, v1.17 EKS master with v1.16 & v1.17 worker nodes. v1.15 is pending validation.

# Prerequisites
* AWS CLI
* Powershell core
* EKS Cluster where AWS Managed AD is available

**Clone the repo and execute the commands from the respective directories**

# 1. Infrastructure Setup
Follow the instructions from [./amazon-eks-gmsa/cloud-formation-templates/README.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/cloud-formation-templates/README.md) to setup infrastructure required to demonstrate EKS gMSA. This step will install following resources.
* Customer Master Key
* Customer Master Key IAM Policy
* SSM Parameters
* AWS Managed Active Directory (AD)
* SSM document to join a AWS managed AD
* SSM document to generate a gMSA account and credential spec content

# 2. Launch EKS Windows Workers with AD Domain Join
Follow the [EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html) to launch EKS Windows worker. *You may have to enable gMSA feature-gates. Refer the following readme to enable featuregate*.
Follow the instructions [./amazon-eks-gmsa/eks-deployments/instance-domain-join.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/eks-deployments/instance-domain-join.md) to join AD Domain
* Enable gMSA Feature-Gates if gMSA is in alpha state
* Attach Customer Master Key IAM Policy to EKS Windows Instances
* Attach Domain Join SSM document to EKS Windows Autoscaling group

# 3. EKS Deployment
Follow the instructions from [./amazon-eks-gmsa/eks-deployments/README.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/eks-deployments/README.md) to deploy the following resources to EKS Cluster.
* Custom Resource Definition (CRD)
* Create a new gMSA Account 
* Deploy Credspec to EKS Cluster
* Deploy gMSA webhook
* CoreDNS config patching

# 4. Deploy Sample Applications
Follow the instructions from [./amazon-eks-gmsa/sample-applications/README.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/sample-applications/README.md) for launching an online bookstore application. Another simple application that uses gMSA credentials to open web service can be launched following the instructions from [./amazon-eks-gmsa/sample-applications/IIS-auth-application/README.md](https://github.com/aws-samples/amazon-eks-gmsa/blob/master/sample-applications/IIS-auth-application/README.md)

# 5. Troubleshooting
For troubleshooting, please follow the steps [here](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/gmsa-troubleshooting) and refer kubernetes official documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-gmsa/).

## License

This project is licensed under the MIT-0 License.
