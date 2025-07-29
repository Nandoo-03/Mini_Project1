pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/Nandoo-03/Mini_Project1.git'
            }
        }
    

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t nandoo03/app:latest .'
            }
        }
    }
}