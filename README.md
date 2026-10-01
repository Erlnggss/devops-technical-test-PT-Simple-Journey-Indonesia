# Technical Test - Shift Engineer (DevOps)
**PT Simple Journey Indonesia**

Dokumentasi pengerjaan technical test DevOps untuk otomatisasi build, deployment, dan pipeline CI/CD aplikasi HTTP server berbasis Go.

---

## Technical Stack & Environment
- **Language:** Go 1.21 (Alpine base)
- **Containerization:** Docker Desktop (WSL2 Engine)
- **CI/CD:** Jenkins (Docker container on port 8081)
- **Version Control:** Git & GitHub

---

## Part I: Build (Multi-Stage Dockerfile)

### Dockerfile
Proses build memanfaatkan teknik multi-stage untuk memisahkan stage kompilasi/testing dengan stage runtime.

```dockerfile
# Stage 1: Build & Unit Test
FROM golang:1.21-alpine AS builder
ARG VERSION=1.0.0
WORKDIR /app

COPY go.mod ./
COPY *.go ./

RUN go test ./...
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.version=${VERSION}" -o myapp .

# Stage 2: Runtime
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/myapp .

EXPOSE 8080
CMD ["./myapp"]

Build Command & Image Size
Command:
Bash
docker build --build-arg VERSION=1.0.0 -t devops-app:1.0.0 .
docker images devops-app:1.0.0
Final Image Size: ~8.75 MB
    Analisis: Penggunaan alpine:latest pada stage runtime membuang Go SDK, compiler, dan cache dependency. Hasil akhirnya hanya berupa satu file binary statis Go di atas OS minimalis, sehingga ukuran image sangat kecil dan efisien untuk produksi.

## Part II: Deploy & Hotfix Scenario
    Running Container
Bash
docker run -d --name devops-app -p 8080:8080 --restart always devops-app:1.0.0

Hotfix Binary Swap (Tanpa Rebuild Image)
Skenario perbaikan bug cepat tanpa perlu melakukan rebuild Docker image dari awal:
    # 1. Compile binary hotfix baru dengan injeksi versi baru:
        Bash
        CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.version=1.0.1-hotfix" -o myapp-hotfix .
    # 2. Copy binary ke container yang sedang aktif:
        Bash
        docker cp myapp-hotfix devops-app:/root/myapp
    # 3. Restart proses container:
        Bash
        docker restart devops-app

    ## Hasil Verifikasi
    Sebelum Swap:
        Bash
        $ curl http://localhost:8080
        Hello, DevOps! version=1.0.0
    
    Setelah Swap & Restart:
        Bash
        $ curl http://localhost:8080
        Hello, DevOps! version=1.0.1-hotfix

Alasan Pemilihan Metode:
Kombinasi docker cp dan docker restart dipilih karena hanya membutuhkan waktu downtime beberapa detik (saat restart container) tanpa overhead proses build image baru dan transfer layer image.

## Part III: CI/CD Pipeline dengan Jenkins

Jenkinsfile Structure
Pipeline menjalankan proses dari checkout hingga deployment otomatis:
pipeline {
    agent any

    environment {
        APP_NAME = 'devops-app'
        BUILD_VER = '1.0.0'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Pulling source code...'
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image & running tests...'
                sh "docker build --build-arg VERSION=${BUILD_VER} -t ${APP_NAME}:${BUILD_VER} ."
            }
        }

        stage('Deploy Container') {
            steps {
                echo 'Deploying application container...'
                sh "docker rm -f ${APP_NAME} || true"
                sh "docker run -d --name ${APP_NAME} -p 8080:8080 --restart always ${APP_NAME}:${BUILD_VER}"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

Penanganan Rollback
Jika stage deployment gagal di tengah jalan, penanganan dilakukan via blok post { failure { ... } }. Pada skala produksi, blok ini difungsikan untuk memicu skrip rollback otomatis yang me-deploy ulang image versi stabil sebelumnya (previous green build).