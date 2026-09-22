pipeline {
    agent any

    stages {

        stage('Infrastructure') {
            steps {
                sh '''
                    docker compose up -d sonarqube

                    echo "Waiting for SonarQube to become healthy..."

                    for i in $(seq 1 60); do
                        STATUS=$(docker inspect --format='{{.State.Health.Status}}' securelab-pipeline-sonarqube-1 2>/dev/null || true)

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

        stage('Build') {
            steps {
                sh 'dotnet restore SecureLab.slnx'
                sh 'dotnet build SecureLab.slnx --no-restore'
            }
        }

        stage('Test') {
            steps {
                sh '''
                    dotnet test SecureLab.slnx --no-build \
                    --collect:"XPlat Code Coverage" \
                    -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover
                '''
            }
        }
    }
}