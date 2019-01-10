# KubeBench

> kube-bench is a Go application that checks whether Kubernetes is deployed securely by running the checks documented in the [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes/).[*](https://github.com/aquasecurity/kube-bench)

CIS Kubernetes Benchmark is a reference document to check and secure configuration of kubernetes. Running the benchmark in `Master` node is not possible in AKS but I will share `Worker` node benchmark results.

#### Benchmark result in RBAC Disabled Cluster

- [INFO] 2 Worker Node Security Configuration
- [INFO] 2.1 Kubelet
- <span style="color:red">[FAIL]</span> 2.1.1 Ensure that the --allow-privileged argument is set to false (Scored)
- <span style="color:red">[FAIL]</span> 2.1.2 Ensure that the --anonymous-auth argument is set to false (Scored)
- <span style="color:green">[PASS]</span> 2.1.3 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Scored)
- <span style="color:red">[FAIL]</span> 2.1.4 Ensure that the --client-ca-file argument is set as appropriate (Scored)
- <span style="color:red">[FAIL]</span> 2.1.5 Ensure that the --read-only-port argument is set to 0 (Scored)
- <span style="color:red">[FAIL]</span> 2.1.6 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Scored)
- <span style="color:red">[FAIL]</span> 2.1.7 Ensure that the --protect-kernel-defaults argument is set to true (Scored)
- <span style="color:green">[PASS]</span> 2.1.8 Ensure that the --make-iptables-util-chains argument is set to true (Scored)
- <span style="color:green">[PASS]</span> 2.1.9 Ensure that the --hostname-override argument is not set (Scored)
- <span style="color:green">[PASS]</span> 2.1.10 Ensure that the --event-qps argument is set to 0 (Scored)
- <span style="color:red">[FAIL]</span> 2.1.11 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Scored)
- <span style="color:green">[PASS]</span> 2.1.12 Ensure that the --cadvisor-port argument is set to 0 (Scored)
- <span style="color:red">[FAIL]</span> 2.1.13 Ensure that the --rotate-certificates argument is not set to false (Scored)
- <span style="color:red">[FAIL]</span> 2.1.14 Ensure that the RotateKubeletServerCertificate argument is set to true (Scored)
- <span style="color:red">[FAIL]</span> 2.1.15 Ensure that the Kubelet only makes use of Strong Cryptographic Ciphers (Not Scored)
- [INFO] 2.2 Configuration Files
- <span style="color:red">[FAIL]</span> 2.2.1 Ensure that the kubelet.conf file permissions are set to 644 or more restrictive (Scored)
- <span style="color:red">[FAIL]</span> 2.2.2 Ensure that the kubelet.conf file ownership is set to root:root (Scored)
- <span style="color:red">[FAIL]</span> 2.2.3 Ensure that the kubelet service file permissions are set to 644 or more restrictive (Scored)
- <span style="color:red">[FAIL]</span> 2.2.4 Ensure that the kubelet service file ownership is set to root:root (Scored)
- <span style="color:red">[FAIL]</span> 2.2.5 Ensure that the proxy kubeconfig file permissions are set to 644 or more restrictive (Scored)
- <span style="color:red">[FAIL]</span> 2.2.6 Ensure that the proxy kubeconfig file ownership is set to root:root (Scored)
- <span style="color:orange">[WARN]</span> 2.2.7 Ensure that the certificate authorities file permissions are set to 644 or more restrictive (Scored)
- <span style="color:orange">[WARN]</span> 2.2.8 Ensure that the client certificate authorities file ownership is set to root:root (Scored)
- <span style="color:red">[FAIL]</span> 2.2.9 Ensure that the kubelet configuration file ownership is set to root:root (Scored)
- <span style="color:red">[FAIL]</span> 2.2.10 Ensure that the kubelet configuration file has permissions set to 644 or more restrictive (Scored)

== Summary ==
5 checks <span style="color:green">PASS</span>
18 checks <span style="color:red">FAIL</span>
2 checks <span style="color:orange">WARN</span>

#### Benchmark result in RBAC Enabled Cluster

Additional checks passed in addition:

- <span style="color:green">[PASS]</span> 2.1.2 Ensure that the --anonymous-auth argument is set to false (Scored)
- <span style="color:green">[PASS]</span> 2.1.4 Ensure that the --client-ca-file argument is set as appropriate (Scored)

== Summary ==
7 checks <span style="color:green">PASS</span>
16 checks <span style="color:red">FAIL</span>
2 checks <span style="color:orange">WARN</span>

For the details of check items you can look at [CIS Benchmark Document](https://learn.cisecurity.org/benchmarks)

