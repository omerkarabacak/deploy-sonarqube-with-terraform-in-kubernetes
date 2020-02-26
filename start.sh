#!/bin/bash
sudo sysctl -w vm.max_map_count=262144
minikube config set memory 8192
minikube config set cpus 4
minikube config set vm-driver virtualbox
minikube start
minikube addons enable ingress
cd terraform-kubernetes-helm
terraform init
terraform apply -auto-approve
cd ..
cd terraform-mysql
terraform init
terraform apply -auto-approve
cd ..
cd terraform-sonarqube
terraform init
terraform apply -auto-approve
cd ..
cd terraform-nginx-ingress
terraform init
terraform apply -auto-approve
cd ..
kubectl apply -f sonarqube-ingress.yaml
minikubeip=$(minikube ip)
echo "Sonarqube URL: https://$minikubeip/sonarqube/"