# Deploy Sonarqube with Terraform in Kubernetes (Minikube)

## Requirements
1. Configure Helm and Tiller for use with Kubernetes cluster;
2. Configure Nginx ingress controller;
3. Prepare MySql DB instance;
4. Configure Sonarqube to use the DB instance provisioned in 3;
5. Install Sonarqube (should use a persistent disk volume);
6. There should be a readme file with setup instructions.

## Tools needed before run
* Virtualbox
* Minikube
* Kubectl
* Terraform
* Helm

## How to run
Just run **start.sh** and it will first configure and create Minikube cluster.
After creating it, it will automatically run Terraform scripts one by one.
Deploy Sonarqube ingress controller and expose url for accessing Sonarqube.
```bash
./start.sh
```

## Why I have created different directories for each component
It is because maybe we can create some Terraform modules and combine them into one big project later.

## Potential improvements

### Tiller removed in Helm version 3
Although Tiller has been removed in Helm version 3, I have deployed it too.

### Sonarqube version 7.9 and higher doesn't support MySQL
Because of this, I have selected Sonarqube 7.8 which is the latest version which support MySQL

### No need for Nginx Ingress controller because Minikube has ingress plugin for it. (At least, setup with Minikube)
