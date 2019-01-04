pipeline {
  agent {
    label "jenkins-go"
  }
  environment {
    ORG = 'kjwilde-hotmail-com'
    APP_NAME = 'lightning-node-easy'
    CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
  }
  stages {



    stage('Determine Environment') {
      steps {
        script {
          kubeEnv = sh(returnStdout: true, script: 'echo "${KUBE_ENV}"')
        }
        echo "kubeEnv: ${kubeEnv}"
      }
    }

    stage('Setup staging deployment.') {
      when {
        branch 'feature-*'
      }
      steps {
        script {
          deployToEnvironment = "staging"

        }
      }
    }

    stage('Setup production deployment.') {
      when {
        branch 'master'
      }
      steps {
        script {
          deployToEnvironment = "production"
        }
      }
    }

    stage('Test deploy plan') {
      steps {
        echo "deployToEnvironment: ${deployToEnvironment}"
      }
    }


//    stage('execute unit tests') {
//      steps {
//        container('nodejs') {
//          sh "npm install"
//          sh "npm install -g grunt-cli"
//          sh "grunt test"
//        }
//      }
//    }
//
//    stage('execute acceptance tests') {
//      steps {
//        container('nodejs') {
//          sh "npm install"
//          sh "npm install -g grunt-cli"
//          sh "grunt cucumber"
//        }
//      }
//    }

    stage('push branch') {
      when {
        expression { env.KUBE_ENV == 'local' }
      }
      steps {
        script {
          if (kubeEnv?.trim() == 'local') {
            container('go') {
              sh "./push.sh ${env.BRANCH_NAME}"
            }
          }
        }
      }
    }



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
          dir('/home/jenkins/go/src/github.com/kjwilde-hotmail-com/lightning-node-easy') {
            checkout scm
            sh "make linux"
            sh "export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml"
            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }
          dir('/home/jenkins/go/src/github.com/kjwilde-hotmail-com/lightning-node-easy/charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
    }

    stage('Build Release') {
      when {
//          branch 'master'
        anyOf { branch 'master'; branch 'feature-*' }
      }
      steps {
        script {
          if (kubeEnv?.trim() != 'local') {
            release()
          }
        }
      }
    }
    stage('Promote to Environments') {
      when {
//          branch 'master'
        anyOf { branch 'master'; branch 'feature-*' }
      }
      steps {
        script {
          if (kubeEnv?.trim() != 'local') {
            promote()
          }
        }
      }
    }

  }

  post {
    always {
      cleanWs()
    }
  }
}

def release() {

  container('go') {
    // ensure we're not on a detached head
//            sh "git checkout master"
    sh "git checkout ${env.BRANCH_NAME}"

    sh "git config --global credential.helper store"

    sh "jx step git credentials"
    // so we can retrieve the version in later steps
    sh "echo \$(jx-release-version) > VERSION"
  }
  dir ('./charts/wildebot') {
    container('go') {
//      sh "ls ./templates/"
//      sh "../../scripts/deployment/setup-${deployToEnvironment}.sh"
//      sh "ls ./templates/"
      sh "make tag"
    }
  }
  container('go') {
//    sh "npm install"
//    sh "CI=true DISPLAY=:99 npm test"

    sh "make build"

    sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'

    sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
  }

}

def promote() {

  dir ('./charts/wildebot') {
    container('go') {
      sh 'jx step changelog --version v\$(cat ../../VERSION)'

      // release the helm chart
      sh 'jx step helm release'

      // promote through all 'Auto' promotion Environments
//              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
      sh "jx promote -b --env ${deployToEnvironment} --timeout 1h --version \$(cat ../../VERSION)"
    }
  }

}


//    stage('Build Release') {
//      when {
//        branch 'master'
//      }
//      steps {
//        container('go') {
//          dir('/home/jenkins/go/src/github.com/kjwilde-hotmail-com/lightning-node-easy') {
//            checkout scm
//
//            // ensure we're not on a detached head
//            sh "git checkout master"
//            sh "git config --global credential.helper store"
//            sh "jx step git credentials"
//
//            // so we can retrieve the version in later steps
//            sh "echo \$(jx-release-version) > VERSION"
//            sh "jx step tag --version \$(cat VERSION)"
//            sh "make build"
//            sh "export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml"
//            sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
//          }
//        }
//      }
//    }
//    stage('Promote to Environments') {
//      when {
//        branch 'master'
//      }
//      steps {
//        container('go') {
//          dir('/home/jenkins/go/src/github.com/kjwilde-hotmail-com/lightning-node-easy/charts/lightning-node-easy') {
//            sh "jx step changelog --version v\$(cat ../../VERSION)"
//
//            // release the helm chart
//            sh "jx step helm release"
//
//            // promote through all 'Auto' promotion Environments
//            sh "jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)"
//          }
//        }
//      }
//    }
//
//
//  }
//}
