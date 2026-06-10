//scripted-way-PL

node
{
     properties([
        pipelineTriggers([
            pollSCM('* * * * *')
        ])
    ])


def mavenHome= tool name: "maven-3.9.0"
echo "git branch Name: ${env.BRANCH_NAME}"
echo "build number: ${env.BUILD_NUMBER}"

  try
  {
     stage('git checkout')
   {
      notifyBuild('STARTED')
      git branch: 'master', url: 'https://github.com/kkdevopsb9/maven-webapplication-project-kkfunda.git'
   }
   stage('COMPILE')
   {
    sh  "${mavenHome}/bin/mvn compile" 
   }
  stage('SQ REPORT') {
        sh "${mavenHome}/bin/mvn sonar:sonar"
    }

    stage('SQ Approval') {

        def decision = input(
            id: 'SQApproval',
            message: 'Please review the SonarQube report and approve/reject the pipeline.',
            parameters: [
                choice(
                    name: 'ACTION',
                    choices: ['Approve', 'Reject'],
                    description: 'Select your action'
                )
            ]
        )

        if (decision == 'Reject') {
            error("Pipeline rejected after SonarQube review.")
        }

        echo "Pipeline approved. Proceeding to next stage..."
    }


    
   stage('Build')
   {
     sh  "${mavenHome}/bin/mvn package"
   }
   stage('Deploy to Nexus')
   {
      sh  "${mavenHome}/bin/mvn deploy"
   }

   stage('Deploy to Tomcat') 
    {
      
      sh """

      curl -u kk:password \
--upload-file /var/lib/jenkins/workspace/webapp-Scripted-Way-PL/target/maven-web-application.war \
"http://13.233.87.148:8080/manager/text/deploy?path=/maven-web-application&update=true"
          
        """
    }
  
  }   //try block ending
   catch (e) {
   
       currentBuild.result = "FAILED"

  } finally {
    // Success or failure, always send notifications
    notifyBuild(currentBuild.result)       //function calling
  }

} //node ending

def notifyBuild(String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus =  buildStatus ?: 'SUCCESS'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESS') {
    color = 'GREEN'
    colorCode = '#27F584'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }

  // Send notifications
  slackSend (color: colorCode, message: summary, channel: '#dev-b9')
  
}
