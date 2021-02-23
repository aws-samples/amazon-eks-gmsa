# Patch CoreDNS
This documemt gives list of steps to deploy credspec resources and gMSA webhook.
*Set Working Directory to ./amazon-eks-gmsa/eks-deployments/patch-coredns*

```powershell
$directoryName = aws ssm get-parameter --name $directoryNameParam --query "Parameter.Value" --output text

./Patch-Coredns.ps1 -ActiveDirectoryDNS "$directoryName" -DNSServerIPs $dnsIPAddresses.Replace(',',' ')
```

# Verify the coredns configfile has patched
```powershell
# Command to verify coredns configmap
kubectl get configmap coredns -n kube-system -o yaml

# The sample configmap
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        # Note that the keyword "upstream" is deprecated starting from Kubernetes 1.18,
        # refer to https://github.com/aws/containers-roadmap/issues/1115 for more detail
        upstream
        fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
      cache 30
      loop
      reload
      loadbalance
    }
    <<ActiveDirectoryname>>:53 { 
	errors 
	cache 30 
	forward . <<DNSServer1>> <<DNSServer2>>
          } 
kind: ConfigMap
```