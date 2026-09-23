pipeline {
    agent any

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
        stage('Tools'){
            steps{
                sh 'dotnet tool restore'
                sh 'dotnet tool run dotnet-sonarscanner --version'
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