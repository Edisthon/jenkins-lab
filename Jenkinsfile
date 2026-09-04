pipeline {
    agent any

    parameters {
        string(name: 'PROD_SERVER_IP', defaultValue: '', description: 'Public IP address of the Production Server')
    }

    environment {
        DOCKER_USERNAME = 'edisthon'
        APP_NAME = 'flask-ci-cd'
        IMAGE_TAG = "${DOCKER_USERNAME}/${APP_NAME}:${env.BUILD_ID}"
        LATEST_TAG = "${DOCKER_USERNAME}/${APP_NAME}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                dir('app') {
                    // Builds only the test stage. If pytest fails, the pipeline stops here!
                    sh "docker build --target test -t ${APP_NAME}-test:latest ."
                }
            }
        }

        stage('Docker Build (Production)') {
            steps {
                dir('app') {
                    // Builds the final production image without test dependencies
                    sh "docker build --target production -t ${IMAGE_TAG} -t ${LATEST_TAG} ."
                }
            }
        }

        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${IMAGE_TAG}"
                    sh "docker push ${LATEST_TAG}"
                }
            }
        }

        stage('Deploy to Prod') {
            steps {
                sshagent(['prod-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${env.PROD_SERVER_IP} '
                        docker stop ${APP_NAME} || true
                        docker rm ${APP_NAME} || true
                        docker pull ${LATEST_TAG}
                        docker run -d --name ${APP_NAME} -p 80:80 -e OTEL_EXPORTER_OTLP_ENDPOINT="http://${env.MONITORING_SERVER_IP}:4317" ${LATEST_TAG}
                        docker image prune -f
                    '
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker logout"
        }
        success {
            echo "Pipeline succeeded! App deployed to Production."
        }
        failure {
            echo "Pipeline failed. Please check the logs."
        }
    }
}
