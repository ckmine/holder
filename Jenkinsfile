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
       withSonarQubeEnv('sonar') {
          
       sh "mvn sonar:sonar -f /var/lib/jenkins/workspace/mine-project/pom.xml"
      
        }
   }
              }
              
              
              
              
              
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
     
}

			 post{
                      always{
              dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
       }
   }

    }
