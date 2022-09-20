#!/bin/bash
sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml
kubectl -n default apply -f k8s_deployment_service.yaml
