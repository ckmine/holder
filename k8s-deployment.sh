#!/bin/bash
sed -i "s#replace#${imageName}#g" blue.yml
kubectl -n default apply -f blue.yml
