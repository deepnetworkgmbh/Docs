# Kubernetes Security

## Authentication

One of the user types in Kubernetes is *service account*. It is managed by Kubernetes API. Credentials are stored as Kubernetes secrets and mounted into pods. These secrets allows pods to communicate with the API Server.

On the other hand, Kubernetes does not provide an identity management solution for normal users. External solutions can be integrated into Kubernetes. For AKS clusters, this integrated identity solution is Azure Active Directory.

### Authentication Strategies

1. X509 Client Certs [*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#x509-client-certs)
   - Requires extra work for renewing and redistributing client certs on a regular basis
2. Static Token File[*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#static-token-file)
   - No method for token revocation exists
   - Changes require the kube-apiserver to be restarted
   - Non-ephemeral nature
3. Bootstrap Tokens[*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#bootstrap-tokens)
   - Non-ephemeral nature
4. Static Password File[*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#static-password-file)
   - No method for token revocation exists
   - Changes require the kube-apiserver to be restarted
   - Credentials being transmitted over the network in cleartext
5. Service Account Tokens[*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens)
   - Normally mounted into Pods for in-cluster access to the kube-apiserver
   - Preferred authentication strategy for applications
6. OpenID Connect Tokens[*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
   - Preferred authentication strategy for end users by cloud providers (AD integration by Azure, AWS IAM by AWS)

For the details of the notes below each strategy, you can read https://dev.to/petermbenjamin/kubernetes-security-best-practices-hlk#authentication and https://medium.com/yld-engineering-blog/kubernetes-auth-380e57d19da0.

In order to enable AD in AKS clusters, a server and client application should be created in Azure ([Create server application](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/aad-integration.md#create-server-application) and [Create client application](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/aad-integration.md#create-client-application))
After getting client app id, server app id, server app secret and tenant id, terraform configuration [akt.tf](/aks.tf) could be used to create an AKS cluster with RBAC enabled and AD integrated. 

#### Authenticating a User

Once the cluster becomes ready, a role binding or cluster role binding need to be created to use AD. To create it:

```
$ az aks get-credentials --resource-group <resource-group-name> --name <cluster-name> --admin
$ kubectl apply -f rbac-aad-user-clusteradmin.yaml # for a single user
$ kubectl apply -f rbac-aad-usergroup-clusteradmin.yaml # for a user group
```

```yaml
# rbac-aad-user-clusteradmin.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "<user id>"
```

```yaml
# rbac-aad-usergroup-clusteradmin.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: "<group id>"
```

The yamls are configured for full access to all namespaces (Authorization details will be described in Authorization section in detail). After this step, specified user in yaml (or user in user group) need to sign in to use kubectl.

```
$ az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
$ kubectl get nodes
  To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code <CODE> to authenticate.
```

#### Authenticating within a Pod

Service account credentials are the recommended way to authenticate within a Pod. By default, default service account is automatically assigned to the pod if no other service account is specified. If RBAC is not enabled in a cluster, default service account is enough for authentication and any request to API server will always authorized by default. If not, a service account with proper role or cluster role need to be created. Details are described in Authorization section.

#### Authenticationg Long Standing Jobs

> Service account bearer tokens are perfectly valid to use outside the cluster and can be used to create identities for long standing jobs that wish to talk to the Kubernetes API. [*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens)

Here is an example scenario for creating a service account for Jenkins:

```
$ kubectl create serviceaccount jenkins
  serviceaccount "jenkins" created
$ kubectl get serviceaccounts jenkins -o yaml
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    # ...
  secrets:
  - name: jenkins-token-hhs5k
$ kubectl get secret jenkins-token-hhs5k -o yaml
  apiVersion: v1
  data:
    ca.crt: <CA of API SERVER BASE64 ENCODED>
    namespace: ZGVmYXVsdA==
    token: <BEARER TOKEN BASE64 ENCODED>
  kind: Secret
  metadata:
    # ...
  type: kubernetes.io/service-account-token
```

The token can be used to authenticate the job as the jenkins service account. The token should be send in the header of the request with `Authorization` key. [*](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#putting-a-bearer-token-in-a-request)


```
Authorization: Bearer <BEARER TOKEN BASE64 ENCODED>
```

Setting kubectl:

```
kubectl config set-cluster <context> --server=<url>
kubectl config set-context <context> --cluster=<cluster> --user=<user>
kubectl config set-credentials <user> --token=<bearer token>
kubectl config use-context <context>
```

Notes:

- Credentials obtained from azure via `az aks get-credentials` command returns a kubectl configuration (same config for everyone) with cert authentication in RBAC disabled clusters and RBAC enabled clusters without AD integration.


## Authorization

### Authorization Modules in Kubernetes

1. Node[*](https://kubernetes.io/docs/reference/access-authn-authz/node/)
   - Kubelets only
2. ABAC[*](https://kubernetes.io/docs/reference/access-authn-authz/abac/) - Attribute-based access control
   - Authorization policy changes requires master VM access
   - API server must be restarted for permission changes to take effect
   - Difficult to manage and understand
3. RBAC[*](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) - Role-based access control
   - Configured using kubectl/Kubernetes API
   - Changes are applied on the fly
4. Webhook[*](https://kubernetes.io/docs/reference/access-authn-authz/webhook/)

### Using RBAC Authorization


In the RBAC authorization, permissions are defined with a Role or ClusterRole. Role is used for granting access inside a single namespace while ClusterRole is for cluster-scoped permissions.
An example Role in `operations` namespace with get permission to services, namespaces and endpoints resources:
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: elasticsearch-logging-role
rules:
- apiGroups:
  - ""
  resources:
  - "services"
  - "namespaces"
  - "endpoints"
  verbs:
  - "get"
```

In addition to custom defined roles and clusterroles, there are also predefined clusterroles created by API server [*](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings). Most of them start with `system:` prefix which means the resource is owned by the infrastructure. Some of them are not `system:` prefixed and can be used for granting permissions to user. These are: 
- `cluster-admin` Allows super-user access to perform any action on any resource. (used in `rbac-aad-user-clusteradmin.yaml` and `rbac-aad-usergroup-clusteradmin.yaml` in Authentication section for AD users)
- `admin` Allows admin access, intended to be granted within a namespace.
- `edit` Allows read/write access to most objects in a namespace.
- `view` Allows read-only access to see most objects in a namespace.

To grant a Role or ClusterRole to a Subject(User, ServiceAccount etc.) RoleBinding or ClusterRoleBinding objects need to be created. These are basically the objects that maps reference of the role to reference of the subject.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elasticsearch-logging-serviceaccount
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: elasticsearch-logging-rolebinding
subjects:
- kind: ServiceAccount
  name: elasticsearch-logging-serviceaccount
  namespace: default
  apiGroup: ""
roleRef:
  kind: Role
  name: elasticsearch-logging-role
  apiGroup: ""
```

### Best Practices for AuthN and AuthZ in AKS[*](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/operator-best-practices-identity.md)

- Authenticate AKS cluster users with Azure Active Directory
  - Centralize the identity management component
  - Take advantage of user groups in AD
- Control access to resources with role-based access controls (RBAC)
  - Create roles and bindings that assign the least amount of permissions required.

## Admission Controllers

Admission Controllers are controllers that intercepts API requests (already authanticated and authorized) before persistence of the object. These controllers need to be compiled into API server and configurable when API server starts up.
List of admission controllers currently supported by AKS:
- `NamespaceLifecycle`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#namespacelifecycle) Requests with non-existing namespaces are rejected and namespace undergoing termination cannot have new objects created in it.
- `LimitRanger`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#limitranger) Assigns default values defined in `LimitRange` to the pod if no `resource limit` or `resource request` requested. If requested, ensures the values are not violating max and min values defined in `LimitRange`
- `ServiceAccount`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount) Implements automation for service accounts.
- `DefaultStorageClass`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#defaultstorageclass) Observes PersistentVolumeClaim objects and adds default storage class automatically if storage class is not defined
- `DefaultTolerationSeconds`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#defaulttolerationseconds) Sets the default forgiveness toleration for pods without forgiveness tolerations.
- `ResourceQuota`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#resourcequota) Ensures `ResourceQuota` defined for a namespace is not violated
- `DenyEscalatingExec`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#denyescalatingexec) Prevents exec and attach commands to pods with excalated privileges
- `AlwaysPullImages`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#alwayspullimages) Forces image pull policy of every pod to Always
- `ValidatingAdmissionWebhook`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook) Calls validating webhooks which match the request. Details are described in Dynamic Admission Controllers section.
- `MutatingAdmissionWebhook`[*](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook) Calls the mutating webhooks which match the request. Details are described in Dynamic Admission Controllers section.

### Dynamic Admission Controllers

Due to their nature (compile into API server and configurable when API server starts up) admission controllers are not flexible enough. Admission Webhooks (ValidatingAdmissionWebhook and MutatingAdmissionWebhook) address these limitatations and help configuration at run time. With ValidatingAdmissionWebhook, it is possible to reject the request. With MutatingAdmissionWebhook, it is possible to modify the request.

Validating webhooks are called in parallel and validated if all of them accepts the request. On the other hand, mutating webhooks are called in serial and each one may make modifications. An important note that, validating webhooks are called before mutating webhooks. So, if a mutating webhook makes a modification that violates a validation, there is no way to detect this.

Implementation of an example mutation webhook with the help of kubewebhook framework[*](https://github.com/slok/kubewebhook):

Webhook:
```go
package main

import (
    "context"
    "fmt"
    "net/http"
    "os"

    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

    whhttp "github.com/slok/kubewebhook/pkg/http"
    "github.com/slok/kubewebhook/pkg/log"
    mutatingwh "github.com/slok/kubewebhook/pkg/webhook/mutating"
)

func annotatePodMutator(_ context.Context, obj metav1.Object) (bool, error) {
    pod, ok := obj.(*corev1.Pod)
    if !ok {
        return false, nil
    }

    if pod.Annotations == nil {
        pod.Annotations = make(map[string]string)
    }
    pod.Annotations["mutatedby"] = "DN"

    return false, nil
}

func main() {
    logger := &log.Std{Debug: true}

    mt := mutatingwh.MutatorFunc(annotatePodMutator)

    mcfg := mutatingwh.WebhookConfig{
        Name: "podAnnotate",
        Obj:  &corev1.Pod{},
    }
    wh, err := mutatingwh.NewWebhook(mcfg, mt, nil, nil, logger)
    if err != nil {
        fmt.Fprintf(os.Stderr, "error creating webhook: %s", err)
        os.Exit(1)
    }

    whHandler, err := whhttp.HandlerFor(wh)
    if err != nil {
        fmt.Fprintf(os.Stderr, "error creating webhook handler: %s", err)
        os.Exit(1)
    }
    logger.Infof("Listening on :8080")
    err = http.ListenAndServeTLS(":8080", "/cert/cert.pem", "/cert/key.pem", whHandler)
    if err != nil {
        fmt.Fprintf(os.Stderr, "error serving webhook: %s", err)
        os.Exit(1)
    }
}
```

When API server receives a pod creation request, it will send an `admissionReview` to the webhook and webhook will send back an `admissionResponse`.

For TLS, key and cert should be created.
```
$ openssl genrsa -out key.pem 2048
$ openssl req -new -key ./key.pem -subj "/CN=mutatingwebhook.default.svc" -out webhook.csr # !<servicename.namespace.svc>
$ openssl x509 -req -days 365 -in webhook.csr -signkey key.pem -out cert.pem
```

Docker image:
```Dockerfile
FROM golang:1.10-alpine

RUN mkdir /cert
COPY main.go .
COPY *.pem /cert/

RUN apk --no-cache add git
RUN apk --no-cache add ca-certificates
RUN go get k8s.io/api/core/v1
RUN go get k8s.io/apimachinery/pkg/apis/meta/v1
RUN go get github.com/slok/kubewebhook/pkg/http
RUN go get github.com/slok/kubewebhook/pkg/log
RUN go get github.com/slok/kubewebhook/pkg/webhook/mutating

RUN CGO_ENABLED=0 go build --ldflags "-w -extldflags '-static'" -o /bin/mutatingwebhook .

ENTRYPOINT ["/bin/mutatingwebhook"]
```

Once the docker image is created and pushed to registry, webhook becomes ready to deploy:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: mutatingwebhook
  labels:
    app: mutatingwebhook
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: mutatingwebhook
    spec:
      containers:
      - name: mutatingwebhook
        image: <user>/<image>:<version>
        imagePullPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: mutatingwebhook
spec:
  ports:
  - port: 443
    targetPort: 8080
  selector:
    app: mutatingwebhook
```

A `MutatingWebhookConfiguration` object should be created for webhook to become active:

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: mutatingwebhook
webhooks:
- name: mutatingwebhook.dn.abc
  clientConfig:
    service:
      name: mutatingwebhook
      namespace: default
      path: "/mutate"
    caBundle: <CA BUNDLE>
  rules:
  - apiGroups: 
    - ""
    apiVersions: 
    - "v1"
    operations: 
    - "CREATE"
    resources: 
    - "pods"
```

```
$ CA_BUNDLE=$(cat cert.pem | base64 -w0)
```

Test the hook:

```
$ kubectl run nginx --image=nginx
  deployment.apps/nginx created
$ kubectl get pods
  NAME                              READY   STATUS    RESTARTS   AGE
  mutatingwebhook-8b86ff76d-gz5vz   1/1     Running   0          5m
  nginx-64f497f8fd-pd45p            1/1     Running   0          8s
$ kubectl describe pods nginx-64f497f8fd-pd45p
  Name:               nginx-64f497f8fd-pd45p
  Namespace:          default
  ...
  Annotations:        mutatedby: DN
  ...
```



