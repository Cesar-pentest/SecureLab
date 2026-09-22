pipeline {
    agent any

    stages {

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