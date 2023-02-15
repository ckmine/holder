#! /bin/bash
cd /var/lib/jenkins/workspace/mine-project/
sudo su - jenkins -s/bin/bash
#docker logout   masternode.mine.com
  docker login -u admin --password Harbor12345 masternode.mine.com
docker image build -t  $JOB_NAME:v1.$BUILD_ID .
 docker image tag $JOB_NAME:v1.$BUILD_ID masternode.mine.com/holder/$JOB_NAME:v1.$BUILD_ID
 docker image tag $JOB_NAME:v1.$BUILD_ID mastenoder.mine.com/holder/$JOB_NAME:latest
 docker image push masternode.mine.com/holder/$JOB_NAME:v1.$BUILD_ID
 docker  push masternode.mine.com/holder/$JOB_NAME:latest
 #docker image rmi $JOB_NAME:v1.$BUILD_ID  masternode.mine.com/holder/$JOB_NAME:v1.$BUILD_ID   masternode.mine.com/holder/$JOB_NAME:latest 
