#!/bin/bash

# Variables
RD_OPTION_APP="nginx"

kubectl --kubeconfig /home/user/.kube/config delete all --all -n $RD_OPTION_APP-namespace
kubectl --kubeconfig /home/user/.kube/config delete namespace $RD_OPTION_APP-namespace