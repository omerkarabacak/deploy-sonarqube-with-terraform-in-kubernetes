#!/bin/bash
rm -rf terraform-*/.terraform
rm terraform-*/terraform.tfstate*
minikube delete