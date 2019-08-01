pipeline {
  agent {
    label "jenkins-go"
  }
  environment {
    ORG = 'srikanthcone'
    APP_NAME = 'test-custom-bp-test'
    CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    DOCKER_REGISTRY_ORG = 'go-sample-project-246814'
  }
  stages {
    stage('CI Build and push snapshot') {
      when {
        branch 'PR-*'
      }
      environment {
        PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
        PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
        HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
      }
      steps {
        container('go') {
          dir('/home/jenkins/go/src/github.com/srikanthcone/test-custom-bp-test') {
            checkout scm
            sh "go get github.com/google/uuid"
            sh "go get -u github.com/gorilla/mux"
            sh "go get -u github.com/cweill/gotests/..."
            sh "go get github.com/tebeka/go2xunit/..."
            sh "go get github.com/securego/gosec/cmd/gosec/..."
            sh "go get github.com/securego/gosec"
            sh "make linux"
            sh "gotests -all -w ."
            sh "go test -v | go2xunit -output test_unit_output.xml"
            sh "go test -coverprofile=coverage.out"
            sh "go tool cover -func=coverage.out > test_coverage_output.out"
            sh "gosec -include=G505 -exclude=G101,G102,G103,G104,G105,G106,G107,G201,G202,G203,G204,G301,G302,G303,G304,G305,G401,G402,G403,G404,G501,G502,G503,G504 -nosec=true -fmt=json -out=test_security_output.json ."
            sh "export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml"
            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }
          dir('/home/jenkins/go/src/github.com/srikanthcone/test-custom-bp-test/charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
    }
    stage('Build Release') {
      when {
        branch 'master'
      }
      steps {
        container('go') {
          dir('/home/jenkins/go/src/github.com/srikanthcone/test-custom-bp-test') {
            checkout scm

            // ensure we're not on a detached head
            sh "git checkout master"
            sh "git config --global credential.helper store"
            sh "jx step git credentials"
            sh "go get github.com/google/uuid"
            sh "go get -u github.com/gorilla/mux"
            sh "go get -u github.com/cweill/gotests/..."
            sh "go get github.com/tebeka/go2xunit/..."
            sh "go get github.com/securego/gosec/cmd/gosec/..."
            sh "go get github.com/securego/gosec"

            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
            sh "jx step tag --version \$(cat VERSION)"
            sh "make build"
            sh "gotests -all -w ."
            sh "go test -v | go2xunit -output test_unit_output.xml"
            sh "go test -coverprofile=coverage.out"
            sh "go tool cover -func=coverage.out > test_coverage_output.out"
            sh "gosec -include=G505 -exclude=G101,G102,G103,G104,G105,G106,G107,G201,G202,G203,G204,G301,G302,G303,G304,G305,G401,G402,G403,G404,G501,G502,G503,G504 -nosec=true -fmt=json -out=test_security_output.json ."
            sh "export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml"
            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
    }
    stage('Promote to Environments') {
      when {
        branch 'master'
      }
      steps {
        container('go') {
          dir('/home/jenkins/go/src/github.com/srikanthcone/test-custom-bp-test/charts/test-custom-bp-test') {
            sh "jx step changelog --version v\$(cat ../../VERSION)"

            // release the helm chart
            sh "jx step helm release"

            // promote through all 'Auto' promotion Environments
            sh "jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)"
          }
        }
      }
    }
  }
}
