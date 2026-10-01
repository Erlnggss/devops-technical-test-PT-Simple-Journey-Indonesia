pipeline {
    agent any

    environment {
        APP_NAME = 'devops-app'
        BUILD_VER = '1.0.0'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Memeriksa file project...'
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Membuat image Docker...'
                sh "docker build --build-arg VERSION=${BUILD_VER} -t ${APP_NAME}:${BUILD_VER} ."
            }
        }

        stage('Deploy Container') {
            steps {
                echo 'Deploying aplikasi ke container...'
                sh "docker rm -f ${APP_NAME} || true"
                sh "docker run -d --name ${APP_NAME} -p 8080:8080 --restart always ${APP_NAME}:${BUILD_VER}"
            }
        }
    }

    post {
        success {
            echo 'Pipeline CI/CD Berhasil Dijalankan!'
        }
        failure {
            echo 'Pipeline CI/CD Gagal!'
        }
    }
}