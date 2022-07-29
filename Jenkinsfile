pipeline {
    agent any
    environment{
        registry='nitingoyal/fonetwish'
    }
    options {
        timestamps()
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build . -t i-nitingoyal-master
                '''
            }
        }
        stage('Containers'){
            parallel {
                stage ('docker run') {
                    steps {
                        sh "docker run -p 4124:80 --name ussd${BUILD_NUMBER} i-nitingoyal-master"
                    }
                }
                stage ('clean running docker') {
                    steps {
                        sh "docker ps | grep ussd${BUILD_NUMBER} | awk '{print \$1}' | xargs docker stop"
                        sh "docker ps -a | grep ussd${BUILD_NUMBER} | awk '{print \$1}' | xargs docker rm"
                    }
                }
                stage('Push Image to DockerHub') {
                    steps {
                        sh 'docker tag i-nitingoyal-master ${registry}:${BUILD_NUMBER}'
                        sh 'docker tag i-nitingoyal-master ${registry}:latest'
                        withDockerRegistry([credentialsId: 'Dockerhub', url: '']){
                            sh 'docker push ${registry}:${BUILD_NUMBER}'
                            sh 'docker push ${registry}:latest'
                        }
                    }
                }
            }
        }
        stage('Docker Deployment') {
            steps {
                sh ">ndi.txt"
                sh "echo NEW_DOCKER_IMAGE=${registry}:${BUILD_NUMBER} >> ndi.txt"
                sh ''' 
                TASK_FAMILY=FoneTwishTaskDefinition
                SERVICE_NAME=FoneTwish
                CLUSTER_NAME=FoneTwishCluster
                OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY)
                NEW_TASK_DEF=$(echo $OLD_TASK_DEF | jq --arg NDI $(cat ndi.txt | cut -f2 -d'=') '.taskDefinition.containerDefinitions[0].image=$NDI')
                FINAL_TASK=$(echo $NEW_TASK_DEF | jq '.taskDefinition|{family: .family, networkMode: .networkMode, containerDefinitions: .containerDefinitions, executionRoleArn: .executionRoleArn}')
                aws ecs register-task-definition --family $TASK_FAMILY --cli-input-json "$(echo $FINAL_TASK)"
                aws ecs update-service --service $SERVICE_NAME --task-definition $TASK_FAMILY --cluster $CLUSTER_NAME
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}