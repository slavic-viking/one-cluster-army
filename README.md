# Home System

## Kubernetes cluster

A simple code that allows to run small kubernetes cluster in Digital Ocean cloud.

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
