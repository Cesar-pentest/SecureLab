pipeline {
    agent any
    
    environment {
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        ACR_LOGIN_SERVER = "securelabacr.azurecr.io"
     }

    stages {

        stage('Infrastructure') {
            steps {
                sh '''
                    docker compose up -d sonarqube

                    echo "Waiting for SonarQube to become healthy..."

                    CONTAINER_ID=$(docker compose ps -q sonarqube)

                    for i in $(seq 1 60); do
                        STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_ID")

                        echo "SonarQube health: $STATUS"

                        if [ "$STATUS" = "healthy" ]; then
                            echo "SonarQube is healthy."
                            break
                        fi

                        if [ "$STATUS" = "unhealthy" ]; then
                            echo "SonarQube became unhealthy."
                            exit 1
                        fi

                        sleep 5
                    done

                    if [ "$STATUS" != "healthy" ]; then
                        echo "SonarQube did not become healthy in time."
                        exit 1
                    fi
                '''
            }
        }

        stage('Tools') {
            steps {
                sh 'dotnet tool restore'
            }
        }

        stage('SAST Begin') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'LaultimaPorFavor',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                        dotnet tool run dotnet-sonarscanner begin \
                            /k:"SecureLab" \
                            /d:sonar.host.url="http://localhost:9000" \
                            /d:sonar.cs.opencover.reportsPaths="**/coverage.opencover.xml" \
                            /d:sonar.token="$SONAR_TOKEN"
                    '''
                }
            }
        }

        stage('Build') {
            steps {
                sh 'dotnet restore SecureLab.slnx'
                sh 'dotnet build SecureLab.slnx --no-restore'
            }
        }

        stage('Test') {
            steps {
                sh '''
                    rm -rf tests/SecureLab.Tests/TestResults

                    dotnet test SecureLab.slnx --no-build \
                        --collect:"XPlat Code Coverage" \
                        -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover
                '''
            }
        }

        stage('SCA') {
            steps {
                sh '''
                    trap 'rm -f sca-result.json' EXIT

                    dotnet list SecureLab.slnx package \
                        --vulnerable \
                        --include-transitive \
                        --format json \
                        > sca-result.json

                    python3 scripts/sca-gate.py sca-result.json
                '''
            }
        }

        stage('Gitleaks') {
            steps {
                sh 'gitleaks detect --source . --verbose'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker compose build securelab-staging'
            }
        }

        stage('Container Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL --exit-code 1 securelab:${IMAGE_TAG}'
            }
        }
        stage('Push to Azure Container Registry') {
            steps {
                withCredentials([
                    usernamePassword(
                credentialsId: 'securelab-azure-sp',
                usernameVariable: 'AZURE_CLIENT_ID',
                passwordVariable: 'AZURE_CLIENT_SECRET'
            )
        ]) {
            sh '''
                echo "$AZURE_CLIENT_SECRET" | docker login \
                    "$ACR_LOGIN_SERVER" \
                    --username "$AZURE_CLIENT_ID" \
                    --password-stdin

                docker tag \
                    "securelab:${IMAGE_TAG}" \
                    "${ACR_LOGIN_SERVER}/securelab:${IMAGE_TAG}"

                docker push \
                    "${ACR_LOGIN_SERVER}/securelab:${IMAGE_TAG}"
            '''
        }
    }
}
stage('Azure Authentication Test') {
    steps {
        withCredentials([
            usernamePassword(
                credentialsId: 'securelab-deployer',
                usernameVariable: 'AZURE_CLIENT_ID',
                passwordVariable: 'AZURE_CLIENT_SECRET'
            )
        ]) {
            sh '''
                az login \
                    --service-principal \
                    --username "$AZURE_CLIENT_ID" \
                    --password "$AZURE_CLIENT_SECRET" \
                    --tenant "d44b8214-c8f3-436d-be12-d6931c1f1555" \
                    --output none

                az account show \
                    --query "{name:name,state:state}" \
                    --output table

                az logout
            '''
        }
    }
}

        stage('SAST End') {
            steps {
                withSonarQubeEnv('SecureLabCodeTesting') {
                    withCredentials([
                        string(
                            credentialsId: 'LaultimaPorFavor',
                            variable: 'SONAR_TOKEN'
                        )
                    ]) {
                        sh '''
                            dotnet tool run dotnet-sonarscanner end \
                                /d:sonar.token="$SONAR_TOKEN"
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker compose up -d securelab-staging'
            }
        }
        stage('Smoke Test'){
            steps{
                sh 'curl --fail http://localhost:8081'
            }
        }
        stage('DAST') {
            steps {
                sh '''
                    rm -rf zap-output
                    mkdir -p zap-output
                    chmod 777 zap-output

                    docker run --rm \
                  --network securelab_default \
                    -v "$PWD/zap-output:/zap/wrk/:rw" \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py \
                    -t http://securelab-staging:8080 \
                    -r zap-report.html \
                    -I
                    '''
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'zap-output/zap-report.html',
                             allowEmptyArchive: true
        }
    }
}