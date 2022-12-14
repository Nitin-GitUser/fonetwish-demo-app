pipeline {
    agent any
    environment{
        registry='nitingoyal/fonetwish'
        region='us-east-1'
        service_name='FoneTwishDemo'
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
        stage ('docker run') {
            steps {
                sh "docker run -p 4124:80 -d --name ussd${BUILD_NUMBER} i-nitingoyal-master"
                sh "sleep 5s"
            }
        }
        stage ('clean running docker') {
            steps {
                sh "docker stop ussd${BUILD_NUMBER}"
                sh "docker rm ussd${BUILD_NUMBER}"
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
        stage('Docker Deployment') {
            steps {
                sh ">ndi.txt"
                sh "echo NEW_DOCKER_IMAGE=${registry}:${BUILD_NUMBER} >> ndi.txt"
                sh ''' 
                TASK_FAMILY=${service_name}TaskDefinition
                SERVICE_NAME=${service_name}
                CLUSTER_NAME=${service_name}Cluster
                OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --region ${region})
                NEW_TASK_DEF=$(echo $OLD_TASK_DEF | jq --arg NDI $(cat ndi.txt | cut -f2 -d'=') '.taskDefinition.containerDefinitions[0].image=$NDI')
                FINAL_TASK=$(echo $NEW_TASK_DEF | jq '.taskDefinition|{family: .family, networkMode: .networkMode, containerDefinitions: .containerDefinitions, executionRoleArn: .executionRoleArn}')
                aws ecs register-task-definition --family $TASK_FAMILY --cpu 256 --memory 512 --requires-compatibilities FARGATE --cli-input-json "$(echo $FINAL_TASK)" --region ${region}
                aws ecs update-service --service $SERVICE_NAME --task-definition $TASK_FAMILY --cluster $CLUSTER_NAME --region ${region}
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