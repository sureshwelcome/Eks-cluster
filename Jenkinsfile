def COLOR_MAP = [
   'SUCCESS': 'good',
   'FAILURE': 'danger',
]

pipeline {
  agent any
   tools {
     maven "maven3.9"
     jdk "OpenJDK17"
   }
   environment {
       JAVA_HOME = tool name: 'OpenJDK17', type: 'jdk'
       PATH = "${env.JAVA_HOME}/bin:${env.PATH}"
       SONAR_SCANNER_OPTS = "--add-opens java.base/java.lang=ALL-UNNAMED"    
       registry = "sureshaws/docker-first"
       registryCredential = 'dockerhublogin'
   }
  stages {
//     stage('fetch code') {
//       steps {
//         git branch: 'main', url: 'https://github.com/hkhcoder/vprofile-project.git'
//       }
//     }
    stage('unit test') {
      steps {
        sh 'mvn test'
      }
    }
    stage('build') {
      steps {
        sh 'mvn install -DskipTests'
      }
      post {
        success {
          archiveArtifacts artifacts: '**/*.war'
        }
      }
    }
    stage('checkstyle analysis') {
      steps {
        sh 'mvn checkstyle:checkstyle'
      }
    }
    stage('sonarqube analysis') {
        environment {
          scannerHome = tool 'sonar6.2'
        }
        steps {
          withSonarQubeEnv('sonarserver') {
            sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
                   -Dsonar.projectName=vprofile-repo \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
                }

            }
        }
       stage('remove previous docker images') {
                 steps {
                      script {
                          sh 'docker image prune -f'
                      }
                  }
              }
       stage('build docker image') {
           steps {
               script {
                   docker.build registry + ":$BUILD_NUMBER"
               }
           }
       }
       stage('push docker image') {
           steps {
              script {
                   docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        docker.image(registry + ":$BUILD_NUMBER").push()
                  }
             }
          }
       }
       stage('remove unused docker images') {
           steps {
               script {
                   sh "docker rmi ${registry}:${BUILD_NUMBER}"
               }
           }
       }
       stage('kubernetes deployment') {
           agent { label 'kube-node02'}
           steps {
               sh "helm upgrade --install force vprofile-stack helm/devops --set appimage=$registry:$BUILD_NUMBER --namespace devops"
               }
           }
       }

//     stage('upload artifacts'){
//       steps {
//           nexusArtifactUploader(
//                       nexusVersion: 'nexus3',
//                       protocol: 'http',
//                       nexusUrl: '192.168.125.130:8081',
//                       groupId: 'QA',
//                       version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
//                       repository: 'Devops',
//                       credentialsId: 'nexuslogin',
//                       artifacts: [
//                           [artifactId: 'vproapp',
//                            classifier: '',
//                            file: 'target/vprofile-v2.war',
//                            type: 'war']
//                       ]
//                )
//           }
//       }
    }

  post {
    always {
      echo 'slack Notification'
      slackSend channel: '#devops',
                color: COLOR_MAP[currentBuild.currentResult],
                message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}"
    }
  }

