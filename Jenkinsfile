pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION='ap-south-1'
        EKS_CLUSTER_NAME = 'eks-cluster'
    }

    stages {

        stage ('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Nandoo-03/Mini_Project1.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t app:latest .'
                
            }
        }

        stage('Push to Dockerhub') {
            steps {
                    echo "Pushing an image to Dockerhub"
                withCredentials([usernamePassword(credentialsId:"dockerHublogin",passwordVariable:"dockerHubPass",usernameVariable:"dockerHubUser")]){
                    sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
                    sh "docker tag app:latest ${env.dockerHubUser}/apps:latest"
                    sh "docker push ${env.dockerHubUser}/apps:latest"
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                    echo "AWS Credentials"
                withAWS(credentials: 'aws_credentials', region: "${AWS_DEFAULT_REGION}") {
                script{
                    sh "aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${EKS_CLUSTER_NAME}"
                    sh 'chmod +x deploy.sh && ./deploy.sh'
                    }
                }
            }
        }
    }
}
