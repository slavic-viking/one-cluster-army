# Home System

GitOPS managed Kubernetes cluster

## Requirements

* terraform
* kubectl
* kubeseal
* kustomize
* argocd

## Kubernetes cluster

A simple code that allows to run small kubernetes cluster in Digital Ocean cloud.
For state management I strongly recommend to use [Terraform Cloud](app.terraform.io).

### Requirements
* Digital Ocean account
* Digital Ocean token
* Terraform installed

The *variables.tf* file contains default variable values.

### Deployment

First, export Digital Ocean token

```console
cd terraform
export DIGITALOCEAN_TOKEN=""
```

#### Init terraform

```console
terraform init
```

#### Plan changes

```console
terraform plan
```

#### Deployment on Digital Ocean cloud

```console
terraform apply
```

## Manual steps

What came first? Egg or chicken? Unfortunately at the beginning some things have to be done manually.

### Environment variables

Some manifests contain my data (email address, url) so please change it :)

`export OVH_CONSUMER_KEY=...`

`export OVH_APPLICATION_KEY=...`

`export OVH_APPLICATION_SECRET=...`

`export GH_ORG=...`

`export GH_EMAIL=...`

`export GH_TOKEN=...`

`export REGISTRY_SERVER=https://index.docker.io/v1/`

`export REGISTRY_USER=...`

`export REGISTRY_PASS=...`

`export REGISTRY_EMAIL=...`

`export BASE_HOST=...`

`export AROCD_PASS=...`

`export CERT_EMAIL=...`

`export GRAFANA_USER=...`

`export GRAFANA_PASSWORD=...`

### NGINX Ingress Controller

```console
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

```console
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n kube-system
```

### cert-manager

Automatic certificate generation

```console
helm repo add jetstack https://charts.jetstack.io
```

```console
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```

#### Create issuers

Replace my email address

Prod issuer

```console
sed -i "s|tomasz\@wostal.eu|$CERT_EMAIL|g" misc/cert-manager-issuers/production/cert-manager-issuer.yaml
```

Staging issuer

```console
sed -i "s|tomasz\@wostal.eu|$CERT_EMAIL|g" misc/cert-manager-issuers/staginf/cert-manager-issuer.yaml
```

Apply both manifests

Staging

```console
kubectl apply -f misc/cert-manager-issuers/staging/cert-manager-issuer.yaml
```

Prod

```console
kubectl apply -f misc/cert-manager-issuers/production/cert-manager-issuer.yaml
```

### Sealed Secrets

This is needed for storing secrets in public repository. The SealedSecret can be decrypted only by the controller
running in the cluster and nobody else.

The quickest way to install Sealed Secrets is to use helm.

The official repo
```console
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
```

Install the chart

```console
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets --namespace kube-system
```

### ExternalDNS

ExternalDNS synchronizes exposed Kubernetes Services and Ingresses with DNS providers. I'm using OVH as my provider
therefore the configuration is customized for OVH. For other providers please check documentation.

#### Create secret

```console
kubectl --namespace kube-system \
    create secret \
    generic ovh \
    --from-literal=ovh_consumer_key=$OVH_CONSUMER_KEY \
    --from-literal=ovh_application_key=$OVH_APPLICATION_KEY \
    --from-literal=ovh_application_secret=$OVH_APPLICATION_SECRET \
    --output json \
    --dry-run=client \
    | kubeseal --format yaml \
    --controller-name=sealed-secrets \
    --controller-namespace=kube-system \
    | tee misc/secrets/ovh.yaml
```

Apply manifest

```console
kubectl apply -f misc/secrets/ovh.yaml
```

#### Install ExternalDNS

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
```

```console
helm upgrade --install external-dns bitnami/external-dns -n kube-system --set provider=ovh --set ovh.secretName=ovh --set policy=sync
```

### Argo CD

Change ingress configuration

```console
sed -i "s|argo-cd.wostal.eu|argo-cd.$BASE_HOST|g" argo-cd/overlays/cicd/ingress.yaml
```

Change ConfigMap

```console
sed -i "s|argo-cd.wostal.eu|argo-cd.$BASE_HOST|g" argo-cd/overlays/cicd/argocd-cm.yaml
```

Create project for whole CI/CD:

```console
kubectl apply -f misc/argocd/project-cicd.yaml
```

Create application for whole CI/CD:

```console
kubectl apply -f misc/argocd/app-cicd.yaml
```

Get current admin password:

```console
export PASS=$(kubectl \
--namespace argocd \
get secret argocd-initial-admin-secret \
--output jsonpath="{.data.password}" \
| base64 --decode)
```

Login to Argo CD:

```console
argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    argo-cd.$BASE_HOST
```

Change password:

```console
argocd account update-password \
--current-password $PASS \
--new-password $ARGOCD_PASS
```

From now you can install all apps using Argo CD and git.

## Automate instalation manually installed apps

Projects and applications are defined in misc/argo-cd directory.

## Prometheus

Prometheus stack (Prometheus, Alert Manager and Grafana ) are part of *monitoring* project which is defined in *misc/argo-cd* directory.
Declaration of kube-prometheus-stack itself is stored in *monitorig/kube-prometheus.yaml* file.

### Create secret for Grafana admin user

```console
kubectl --namespace monitoring \
    create secret \
    generic grafana-admin-user \
    --from-literal=username=$GRAFANA_USER \
    --from-literal=password=$GRAFANA_PASSWORD \
    --output json \
    --dry-run=client \
    | kubeseal --format yaml \
    --controller-name=sealed-secrets \
    --controller-namespace=kube-system \
    | tee misc/secrets/grafana.yaml
```




kubectl --namespace tick \
    create secret \
    generic telegraf-secrets \
    --from-literal=INFLUXDB_DB=$INFLUXDB_DB \
    --from-literal=INFLUXDB_URL=$INFLUXDB_URL \
    --from-literal=INFLUXDB_USER=$INFLUXDB_USER \
    --from-literal=INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD \
    --output json \
    --dry-run=client \
    | kubeseal --format yaml \
    --controller-name=sealed-secrets \
    --controller-namespace=kube-system \
    | tee misc/secrets/telegraf.yaml


kubectl --namespace monitoring \
    create secret \
    generic grafana-secrets \
    --from-literal=INFLUXDBHA_USERNAME=$INFLUXDBHA_USERNAME \
    --from-literal=INFLUXDBHA_URL=$INFLUXDBHA_URL \
    --from-literal=INFLUXDBHA_PASSWORD=$INFLUXDBHA_PASSWORD \
    --from-literal=INFLUXDBHA_DATABASE=$INFLUXDBHA_DATABASE \
    --output json \
    --dry-run=client \
    | kubeseal --format yaml \
    --controller-name=sealed-secrets \
    --controller-namespace=kube-system \
    | tee misc/secrets/grafana-secrets.yaml

