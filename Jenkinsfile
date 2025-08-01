pipeline {
    agent any

    
    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Nandoo-03/Mini_Project1.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t nandoo03/app:latest .'
            }
        }

        stage('Push to Dockerhub') {
            steps {
                    echo "Pushing an image to Dockerhub"
                withCredentials([usernamePassword(credentialsId:"dockerHublogin",passwordVariable:"dockerHubPass",usernameVariable:"dockerHubUser")]){
                    sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
                    sh "docker tag apps:latest ${env.dockerHubUser}/apps:latest"
                    sh "docker push ${env.dockerHubUser}/apps:latest"
                }
            }
        }

        stage('update kubeconfig') {
            steps{
                sh './kubeconfig.sh'
            }
        }

        stage('Deploy to EKS') {
            steps {
                
                sh 'kubectl apply -f namespace.yaml --validate=false'
                sh 'kubectl apply -f deployment.yaml --validate=false'
                sh 'kubectl apply -f service.yaml --validate=false'
            }
        }
    }
}