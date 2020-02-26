# Kubernetes Tiller Deployment On Minikube

The root folder of this repo shows an example of how to use the Terraform modules in this repository to deploy
Tiller (the server component of Helm) onto a Kubernetes cluster. Here we will walk through a detailed guide on how you
can setup `minikube` and use this module to deploy Tiller onto it.

**WARNING: The private keys generated in this example will be stored unencrypted in your Terraform state file. If you are
sensitive to storing secrets in your Terraform state file, consider using `kubergrunt` to generate and manage your TLS
certificate. See [the k8s-tiller-kubergrunt-minikube example](/examples/k8s-tiller-kubergrunt-minikube) for how to use
`kubergrunt` for TLS management.**


## Background

We strongly recommend reading [our guide on Helm](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md)
before continuing with this guide for a background on Helm, Tiller, and the security model backing it.


## Overview

In this guide we will walk through the steps necessary to get up and running with deploying Tiller using this module,
using `minikube` to deploy our target Kubernetes cluster. Here are the steps:

1. [Install and setup `minikube`](#setting-up-your-kubernetes-cluster-minikube)
1. [Install the necessary tools](#installing-necessary-tools)
1. [Apply the terraform code](#apply-the-terraform-code)
1. [Verify the deployment](#verify-tiller-deployment)
1. [Granting access to additional roles](#granting-access-to-additional-users)
1. [Upgrading the deployed Tiller instance](#upgrading-deployed-tiller)


## Setting up your Kubernetes cluster: Minikube

In this guide, we will use `minikube` as our Kubernetes cluster to deploy Tiller to.
[Minikube](https://kubernetes.io/docs/setup/minikube/) is an official tool maintained by the Kubernetes community to be
able to provision and run Kubernetes locally your machine. By having a local environment you can have fast iteration
cycles while you develop and play with Kubernetes before deploying to production.

To setup `minikube`:

1. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [Install the minikube utility](https://kubernetes.io/docs/tasks/tools/install-minikube/)
1. Run `minikube start` to provision a new `minikube` instance on your local machine.
1. Verify setup with `kubectl`: `kubectl cluster-info`

**Note**: This module has been tested to work against GKE and EKS as well. You can checkout the examples in the
respective repositories for how to deploy Tiller on those platforms. <!-- TODO: link to examples -->


## Installing necessary tools

Additionally, this example depends on `terraform` and `helm`. Optionally, you can install `kubergrunt` which automates a
few of the steps. Here are the installation guide for each:

1. [`terraform`](https://learn.hashicorp.com/terraform/getting-started/install.html)
1. [`helm` client](https://docs.helm.sh/using_helm/#installing-helm)
1. [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt#installation), minimum version: v0.3.6

Make sure the binaries are discoverble in your `PATH` variable. See [this stackoverflow
post](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix) for instructions on
setting up your `PATH` on Unix, and [this
post](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) for instructions on
Windows.


## Apply the Terraform Code

Now that we have a working Kubernetes cluster, and all the prerequisite tools are installed, we are ready to deploy
Tiller! To deploy Tiller, we will use the example Terraform code at the root of this repo:

1. If you haven't already, clone this repo:
    - `git clone https://github.com/gruntwork-io/terraform-kubernetes-helm.git`
1. Make sure you are at the root of this repo:
    - `cd terraform-kubernetes-helm`
1. Initialize terraform:
    - `terraform init`
1. Apply the terraform code:
    - `terraform apply`
    - Fill in the required variables based on your needs. <!-- TODO: show example inputs here -->

The Terraform code creates a few resources before deploying Tiller:

- A Kubernetes `Namespace` (the `tiller-namespace`) to house the Tiller instance. This namespace is where all the
  Kubernetes resources that Tiller needs to function will live. In production, you will want to lock down access to this
  namespace as being able to access these resources can compromise all the protections built into Helm.
- A Kubernetes `Namespace` (the `resource-namespace`) to house the resources deployed by Tiller. This namespace is where
  all the Helm chart resources will be deployed into. This is the namespace that your devs and users will have access
  to.
- A Kubernetes `ServiceAccount` (`tiller-service-account`) that Tiller will use to apply the resources in Helm charts.
  Our Terraform code grants enough permissions to the `ServiceAccount` to be able to have full access to both the
  `tiller-namespace` and the `resource-namespace`, so that it can:
    - Manage its own resources in the `tiller-namespace`, where the Tiller metadata (e.g release tracking information) will live.
    - Manage the resources deployed by helm charts in the `resource-namespace`.
- Generate a TLS CA certificate key pair and a set of signed certificate key pairs for the server and the client. These
  will then be uploaded as `Secrets` on the Kubernetes cluster.

These resources are then passed into the `k8s-tiller` module where the Tiller `Deployment` resources will be created.
Once the resources are applied to the cluster, this will wait for the Tiller `Deployment` to roll out the `Pods` using
`kubergrunt helm wait-for-tiller`.

At the end of the `apply`, you should now have a working Tiller deployment. So let's verify that in the next step!


## Verify Tiller Deployment

To start using `helm`, we must first configure our client with the generated TLS certificates. This is done by
downloading the client side certificates in to the Helm home folder. The client side TLS certificates are available as
outputs by the terraform code. We can store them in the home directory using the `terraform output` command:

```bash
mkdir -p $HOME/.helm
terraform output helm_client_tls_private_key_pem > "$HOME/.helm/client.pem"
terraform output helm_client_tls_public_cert_pem > "$HOME/.helm/client.crt"
terraform output helm_client_tls_ca_cert_pem > "$HOME/.helm/ca.crt"
```

Once the certificate key pairs are stored, we need to setup the default repositories where the helm charts are stored.
This can be done using the `helm init` command:

```bash
helm init --client-only
```

If you have `kubergrunt` installed, the above steps can be automated in a single using the `helm configure` command of
`kubergrunt`:

```bash
kubergrunt helm configure \
  --tiller-namespace $(terraform output tiller_namespace) \
  --resource-namespace $(terraform output resource_namespace) \
  --rbac-user minikube
```

Once the certificates are installed and the client is configured, you are ready to use `helm`. However, by default the
`helm` client does not assume a TLS setup. In order for the `helm` client to properly communicate with the deployed
Tiller instance, it needs to be told to use TLS verification. These are specified through command line arguments. If
everything is configured correctly, you should be able to access the Tiller that was deployed with the following args:

```
helm version --tls --tls-verify --tiller-namespace NAMESPACE_OF_TILLER
```

If you have access to Tiller, this should return you both the client version and the server version of Helm. Note that
you need to pass the above CLI argument every time you want to use `helm`.

If you used `kubergrunt` to configure your helm client, it will install an environment file into your helm home
directory that you can dot source to set environment variables that guide `helm` to use those options:

```
. ~/.helm/env
helm version
```

This can be a convenient way to avoid specifying the TLS parameters for each and every `helm` command you run.

<!-- TODO: Mention windows -->


## Granting Access to Additional Users

Now that you have deployed Tiller and setup access for your local machine, you are ready to start using `helm`! However,
you might be wondering how do you share the access with your team?

In order to allow other users access to the deployed Tiller instance, you need to explicitly grant their RBAC entities
permission to access it. This involves:

- Granting enough permissions to access the Tiller pod
- Generating and sharing TLS certificate key pairs to identify the client

You have two options to do this:

- [Using the `k8s-helm-client-tls-certs` module](#using-the-k8s-helm-client-tls-certs-module)
- [Using `kubergrunt`](#using-kubergrunt)

#### Using the k8s-helm-client-tls-certs module

`k8s-helm-client-tls-certs` is designed to take a CA TLS cert generated using `k8s-tiller-tls-certs` and generate new
signed TLS certs that can be used as verified clients. To use the module for this purpose, you can either call out to
the module in your terraform code (like we do here to generate one for the operator), or use it directly as a temporary
module.

Follow these steps to use it as a temporary module:

1. Copy this module to your computer.
1. Open `variables.tf` and fill in the variables that do not have a default.
1. DO NOT configure Terraform remote state storage for this code. You do NOT want to store the state files as they will
   contain the private keys for the certificates.
1. DO NOT configure `store_in_kubernetes_secret` to `true`. You do NOT want to store the certificates in Kubernetes
   without the state file.
1. Run `terraform apply`.
1. Extract the generated certificates from the output and store to a file. E.g:

    ```bash
    terraform output tls_certificate_key_pair_private_key_pem > client.pem
    terraform output tls_certificate_key_pair_certificate_pem > client.crt
    terraform output ca_tls_certificate_key_pair_certificate_pem > ca.crt
    ```

1. Share the extracted files with the user.
1. Delete your local Terraform state: `rm -rf terraform.tfstate*`. The Terraform state will contain the private keys for
   the certificates, so it's important to clean it up!

The user can then install the certs and setup the client in a similar manner to the process described in [Verify Tiller
Deployment](#verify-tiller-deployment)

#### Using kubergrunt

`kubergrunt` automates this process in the `grant` and `configure` commands. For example, suppose you wanted to grant
access to the deployed Tiller to a group of users grouped under the RBAC group `dev`. You can grant them access using
the following command:

```
kubergrunt helm grant --tiller-namespace NAMESPACE_OF_TILLER --rbac-group dev --tls-common-name dev --tls-org YOUR_ORG
```

This will generate a new certificate key pair for the client and upload it as a `Secret`. Then, it will bind new RBAC
roles to the `dev` RBAC group that grants it permission to access the Tiller pod and the uploaded `Secret`.

This in turn allows your users to configure their local client using `kubergrunt`:

```
kubergrunt helm configure --tiller-namespace NAMESPACE_OF_TILLER --rbac-group dev
```

At the end of this, your users should have the same helm client setup as above.
