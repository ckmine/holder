pipeline { 
         agent any  
         
           environment {
        jenkins_server_url = "http://192.168.152.130:8080"
        notification_channel = 'devops'
        slack_url = 'https://hooks.slack.com/services/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'
        deploymentName = "web-server"
    containerName = "web-server"
    serviceName = "web-server"
    imageName = "master.mine.com/holder/$JOB_NAME:v1.$BUILD_ID"
     applicationURL="http://192.168.152.131"
    applicationURI="epps-smartERP/" 		   
		   
        
    }
         
    
    tools {
        maven 'maven3'
    }
    
    stages { 
        stage('Build Checkout') { 
            steps { 
              checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/ckmine/holder.git']]])
         }
        }
        stage('Build Now') { 
            steps { 
              
                  dir("/var/lib/jenkins/workspace/mine-project") {
                    sh 'mvn -version'
                    sh 'mvn clean install'
                      
                    echo "build succses"
                }

       
              }

            }
            
            
            
             
              stage ('Code Quality scan') {
              steps {
       // withSonarQubeEnv('sonar') {
          
       sh "mvn clean verify sonar:sonar -Dsonar.projectKey=mine-project -Dsonar.host.url=http://192.168.152.130:9000 -Dsonar.login=sqp_181476661b16866f247bdcd671c74d0d3563bc98 "
      
        }
   //}
              }
              
              
              //synk
              
              
              stage ('Vulnerability Scan - Docker ') {
              steps {
                  
                 parallel   (
       "Dependency Scan": {
       	     	sh "mvn dependency-check:check"
		},
	 	  "Trivy Scan":{
	 		    sh "bash trivy-docker-image-scan.sh"
		     	},
		   "OPA Conftest":{
			sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
		    }   	
		             	
   	                      )
                    
              }
               }
              
           
              stage(' Rename and move Build To Perticuler Folder '){
                steps {
                   sh 'mv /var/lib/jenkins/workspace/mine-project/target/jenkins-git-integration.war   /var/lib/jenkins/workspace/mine-project/epps-smartERP.war'
                  sh 'chmod -R 777 /var/lib/jenkins/workspace/mine-project/epps-smartERP.war'
                  
                  sh 'chmod -R 777 /var/lib/jenkins/workspace/mine-project/Dockerfile'
                  sh 'chmod -R 777 /var/lib/jenkins/workspace/mine-project/shell.sh'
                  sh 'chown jenkins:jenkins  /var/lib/jenkins/workspace/mine-project/trivy-docker-image-scan.sh'                
                 
                                     }
                       }
                       
                       stage ("Slack-Notify"){
                         steps {
                            slackSend channel: 'devops', message: 'deployment successfully'
                         }
                       }

    stage ('Regitsry Approve') {
      steps {
      echo "Taking approval from DEV Manager forRegistry Push"
        timeout(time: 7, unit: 'DAYS') {
        input message: 'Do you want to deploy?', submitter: 'admin'
        }
      }
    }

 // Building Docker images
    stage('Building image | Upload to Harbor Repo') {
      steps{
            sh '/var/lib/jenkins/workspace/mine-project/shell.sh'  
    }
      
    }
    
    
	 stage('Vulnerability Scan - Kubernetes') {
       steps {
         parallel(
           "OPA Scan": {
             sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego blue.yml'
         },
          "Kubesec Scan": {
            sh "bash kubesec-scan.sh"
          },
           "Trivy Scan": {
             sh "bash trivy-k8s-scan.sh"
           }
        )
      }
    }
    
    
    stage('K8S Deployment - DEV') {
       steps {
         parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment.sh"
             }
           },
         "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
             sh "bash k8s-deployment-rollout-status.sh"
             }
           }
        )
       }
     }
	    
	   stage('Integration Tests - DEV') {
         steps {
         script {
          try {
            withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "bash integration-test.sh"
             }
            } catch (e) {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "kubectl -n default rollout undo deploy ${deploymentName}"
             }
             throw e
           }
         }
       }
     }  
	    
	 stage('OWASP ZAP - DAST') {
       steps {
         withKubeConfig([credentialsId: 'kubeconfig']) {
           sh 'bash zap.sh'
         }
       }
     }  
	    
	    stage('Prompte to PROD?') {
       steps {
         timeout(time: 2, unit: 'DAYS') {
           input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
         }
       }
     }

     stage('K8S CIS Benchmark') {
       steps {
         script {

           parallel(
            "Master": {
               sh "bash cis-master.sh"
             },
             "Etcd": {
               sh "bash cis-etcd.sh"
             },
             "Kubelet": {
               sh "bash cis-kubelet.sh"
             }
           )

         }
       }
     }
	    
	  stage('K8S Deployment - PROD') {
       steps {
         parallel(
           "Deployment": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
               sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
             }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "bash k8s-PROD-deployment-rollout-status.sh"
             }
           }
         )
       }
     }  
	
	    stage('Integration Tests - PROD') {
       steps {
         script {
          try {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash integration-test-PROD.sh"
             }
           } catch (e) {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "kubectl -n prod rollout undo deploy ${deploymentName}"
             }
             throw e
           }
         }
       }
     }  
	    
     
}

			 post{
                      always{
              dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
              publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
       }
   }

    }
