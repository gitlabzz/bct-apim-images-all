release = '7_7_20220228'
installerURL = "http://172.16.63.180:8081/repository/apim-releases/axway/api/management/installer/APIGateway_7.7.20220228_Install_linux-x86-64_BN02.run/28.02.2022/APIGateway_7.7.20220228_Install_linux-x86-64_BN02.run-28.02.2022.run"
emtScriptsURL = "http://172.16.63.180:8081/repository/apim-releases/axway/api/management/emt/scripts/APIGateway_7.7.20220228-DockerScripts-2.4.0.tar/28.02.2022/APIGateway_7.7.20220228-DockerScripts-2.4.0.tar-28.02.2022.tar"
portalEmtScriptsURL = "http://172.16.63.180:8081/repository/apim-releases/axway/api/management/emt/scripts/APIPortal_7.7.20220228_Docker_Samples_Package_linux-x86-64_BN724.tar/28.02.2022/APIPortal_7.7.20220228_Docker_Samples_Package_linux-x86-64_BN724.tar-28.02.2022.tar"

gitRepoProtocol = "http"
gitRepo = "gitlab.asim.com/gitlab-instance-90f20ff9/sw-apim-images-all.git"
helmGitRepo = "gitlab.asim.com/gitlab-instance-90f20ff9/apim-helm.git"

nexusHelmRepo = "http://172.16.63.180:8081/repository/apim-helm/"


buildManifest = [:]
portalBuildConfig = [:]

imageTag = ""
targetEnvironment = 'dev'
emailRecipient = "someone@sydneywater.com.au"

node {
    try {
        checkout().call()
        loadManifest().call()
        initialise().call()
        buildBaseImage().call()
        buildANM().call()
        buildAPIMgr().call()
        buildPortal().call()
        createLatestDockerTags().call()
        pushReleaseDockerTags().call()
        pushLatestDockerTags().call()
        processHelmChart().call()
        gitTag().call()
        emailNotification().call()
        clearWorkspace().call()
    } catch (e) {
        postFailure(e).call()
        currentBuild.result = 'FAILURE'
    }
}

def checkout() {
    return {
        stage("Checkout") {
            checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'userid-password-gitlab-root', url: "${gitRepoProtocol}://${gitRepo}"]]])
        }
    }
}

def loadManifest() {
    return {
        stage("Load Manifest") {
            def props = readProperties file: "build.properties"
            buildManifest.anm = Boolean.parseBoolean(props['build.api.anm.image.enabled'] as String)
            buildManifest.apim = Boolean.parseBoolean(props['build.api.manager.image.enabled'] as String)
            buildManifest.portal = Boolean.parseBoolean(props['build.api.portal.image.enabled'] as String)
            if (!buildManifest.containsValue(true)) {
                error "${buildManifest} - Nothing to build!"
            }
        }
    }
}

def initialise() {
    return {
        stage('Initialise') {
            parallel([
                    "Prepare Docker for Build"   : {
                        sh script: "docker system prune -f", label: "docker system prune"
                        echo "Successfully completed 'docker system prune -f' command"
                        try {
                            sh script: "docker rmi -f \$(docker images -aq)", label: "Remove all docker images"
                            echo "Successfully completed 'docker rmi -f \$(docker images -aq)' command"
                        } catch (exception) {
                            echo "Couldn't complete docker rmi, probably no images for deletion."
                        }
                        echo "Cleared existing and dangling images, ready for build."
                    },
                    "Generate Image Tag"         : {
                        def dateTimeSignature = new java.text.SimpleDateFormat("YYYYMMdd").format(new Date())
                        echo "The datetime signature for build is: ${dateTimeSignature}"
                        dateTimeSignature += "_${env.BUILD_NUMBER}"
                        echo "The datetime signature along with build number is: ${dateTimeSignature}"
                        imageTag = "${release}_${dateTimeSignature}"
                        echo "The Image tag is going to be: ${imageTag}"
                    },
                    "Download Gateway Installers": {
                        withCredentials([usernamePassword(credentialsId: "userid-password-nexus-admin", passwordVariable: 'pass', usernameVariable: 'user')]) {
                            if (buildManifest.anm || buildManifest.apim) {
                                def downloadStatus = sh(returnStdout: true, script: "wget --user ${user} --password ${pass} ${installerURL} --no-check-certificate && echo 'installer downloaded successfully!' || echo 'failed to download installer'", label: "Download Gateway Installer")
                                echo "${downloadStatus}"
                                if (downloadStatus.contains("failed")) {
                                    error downloadStatus + "\n" + installerURL
                                }

                                downloadStatus = sh(returnStdout: true, script: "wget --user ${user} --password ${pass} ${emtScriptsURL} --no-check-certificate && echo 'emt scripts downloaded successfully!' || echo 'failed to download emt scripts!'", label: "Download Gateway EMT Scripts")
                                echo "${downloadStatus}"
                                if (downloadStatus.contains("failed")) {
                                    error downloadStatus + "\n" + emtScriptsURL
                                }
                            } else {
                                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                                    error "Skipping downloading installers for gateway as both ANM and APIM are disabled!"
                                }
                            }
                        }
                    },
                    "Download Portal Installer"  : {
                        withCredentials([usernamePassword(credentialsId: "userid-password-nexus-admin", passwordVariable: 'pass', usernameVariable: 'user')]) {
                            if (buildManifest.portal) {
                                def downloadStatus = sh(returnStdout: true, script: "wget --user ${user} --password ${pass} ${portalEmtScriptsURL} --no-check-certificate && echo 'portal emt scripts downloaded successfully!' || echo 'failed to download portal emt scripts!'", label: "Download API Portal EMT Scripts")
                                echo "${downloadStatus}"
                                if (downloadStatus.contains("failed")) {
                                    error downloadStatus + "\n" + portalEmtScriptsURL
                                }
                            } else {
                                echo "Skip downloading portal emt scripts!"
                            }
                        }
                    }
            ])
        }
    }
}

def buildBaseImage() {
    return {
        stage('Build Base Image') {
            if (buildManifest.anm || buildManifest.apim) {
                def status = sh returnStdout: true, script: "./build_base_image.sh ${imageTag} harbor.com /apim /apim_base && echo 'EMT base image build successfully!' || echo 'failed to build EMT base image!'", label: "Build Base Image"
                echo "${status}"
                if (status.contains("failed")) {
                    error status
                }
            } else {
                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                    error "Skip building base image!"
                }
            }
        }
    }
}

def buildANM() {
    return {
        stage('Build ANM') {
            if (buildManifest.anm) {
                def status = sh returnStdout: true, script: "./build_anm_image.sh ${targetEnvironment} ${imageTag} /apim_base:${imageTag} harbor.com /apim /apim_anm && echo 'Admin Node Manager image build successfully!' || echo 'failed to build Admin Node Manager image!'", label: "Build ANM"
                echo "${status}"
                if (status.contains("failed")) {
                    error status
                }
            } else {
                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                    error "Skip building admin node manager image!"
                }
            }
        }
    }
}

def buildAPIMgr() {
    return {
        stage('Build APIMgr') {
            if (buildManifest.apim) {
                def status = sh returnStdout: true, script: "./build_apimgr_image.sh ${targetEnvironment} ${imageTag} /apim_base:${imageTag} harbor.com /apim /apim_apimgr && echo 'API Manager image build successfully!' || echo 'failed to build API Manager image!'", label: "Build APIMgr"
                echo "${status}"
                if (status.contains("failed")) {
                    error status
                }
            } else {
                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                    error "Skip building api manager image!"
                }
            }
        }
    }
}

def buildPortal() {
    return {
        stage('Build Portal') {
            if (buildManifest.portal) {
                echo "Loading config for '${targetEnvironment}' environment"
                def props = readProperties file: "portal/config/${targetEnvironment}/config.properties"
                portalBuildConfig.mySqlHost = props['MYSQL_HOST']
                portalBuildConfig.mySqlPort = props['MYSQL_PORT']
                portalBuildConfig.mySqlDatabase = props['MYSQL_DATABASE']
                portalBuildConfig.mySqlUser = props['MYSQL_USER']
                portalBuildConfig.mySqlPassword = props['MYSQL_PASSWORD']

                def status = sh returnStdout: true, script: "./build_apim_portal_image.sh harbor.com /apim /apim_portal ${imageTag} ${portalBuildConfig.mySqlHost} ${portalBuildConfig.mySqlPort} ${portalBuildConfig.mySqlDatabase} ${portalBuildConfig.mySqlUser} ${portalBuildConfig.mySqlPassword} && echo 'API Portal image build successfully!' || echo 'failed to build API Portal image!'", label: "Build Portal"
                echo "${status}"
                if (status.contains("failed")) {
                    error status
                }
            } else {
                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                    error "Skip building portal image!"
                }
            }
        }
    }
}

def createLatestDockerTags() {
    return {
        stage('Create Latest Docker Tags') {
            parallel([
                    ANM   : {
                        if (buildManifest.anm) {
                            sh "docker tag harbor.com/apim/apim_anm:${imageTag} harbor.com/apim/apim_anm:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip creating anm latest tag!"
                            }
                        }
                    },
                    APIMGR: {
                        if (buildManifest.apim) {
                            sh "docker tag harbor.com/apim/apim_apimgr:${imageTag} harbor.com/apim/apim_apimgr:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip creating apim latest tag!"
                            }
                        }
                    },
                    PORTAL: {
                        if (buildManifest.portal) {
                            sh "docker tag harbor.com/apim/apim_portal:${imageTag} harbor.com/apim/apim_portal:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip creating portal latest tag!"
                            }
                        }
                    }
            ])
        }
    }
}

def pushReleaseDockerTags() {
    return {
        stage('Push Release Docker Tags') {
            parallel([
                    ANM   : {
                        if (buildManifest.anm) {
                            //sh "docker push harbor.com/apim/apim_anm:${imageTag}"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing release tag for anm!"
                            }
                        }
                    },
                    APIMGR: {
                        if (buildManifest.apim) {
                            //sh "docker push harbor.com/apim/apim_apimgr:${imageTag}"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing release tag for apim!"
                            }
                        }
                    },
                    PORTAL: {
                        if (buildManifest.portal) {
                            //sh "docker push harbor.com/apim/apim_portal:${imageTag}"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing release tag for portal!"
                            }
                        }
                    }
            ])
        }
    }
}

def pushLatestDockerTags() {
    return {
        stage('Push Latest Docker Tags') {
            parallel([
                    ANM   : {
                        if (buildManifest.anm) {
                            //sh "docker push harbor.com/apim/apim_anm:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing latest tag for anm!"
                            }
                        }
                    },
                    APIMGR: {
                        if (buildManifest.apim) {
                            //sh "docker push harbor.com/apim/apim_apimgr:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing latest tag for apim!"
                            }
                        }
                    },
                    PORTAL: {
                        if (buildManifest.portal) {
                            //sh "docker push harbor.com/apim/apim_portal:latest"
                        } else {
                            catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                error "Skip pushing latest tag for portal!"
                            }
                        }
                    }
            ])
        }
    }
}

def processHelmChart() {
    return {
        stage('Process Helm Chart') {
            parallel(
                    'Processing': {
                        stage('Processing') {
                            if (buildManifest.containsValue(true)) {
                                sh script: "echo Processing", label: "sh echo Processing APIM Helm Chart!"
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip processing image tags updates in values.yaml file!"
                                }
                            }
                        }
                    },
                    'Update values': {
                        stage('Clone') {
                            withCredentials([usernamePassword(credentialsId: "userid-password-gitlab-root", passwordVariable: 'password', usernameVariable: 'username')]) {
                                def encodedPassword = URLEncoder.encode("$password", 'UTF-8')
                                sh script: "rm -rf apim-helm || true", label: "remove apim-helm folder for clone"
                                sh script: "git clone ${gitRepoProtocol}://${username}:${encodedPassword}@${helmGitRepo}", label: "clone helm chart repo"
                            }
                        }
                        stage("Update ANM Image Tag") {
                            if (buildManifest.anm) {
                                def currentANM = sh(returnStdout: true, script: "yq '.anm.imageTag' apim-helm/values-sit.yaml", label: "read anm image tag")
                                echo "currently .anm.imageTag is: ${currentANM}"
                                sh script: "yq -i '.anm.imageTag=\"${imageTag}\"' apim-helm/values-sit.yaml", label: "update anm image tag"
                                def afterANM = sh(returnStdout: true, script: "yq '.anm.imageTag' apim-helm/values-sit.yaml", label: "read anm image tag after update")
                                echo "after update .anm.imageTag is: ${afterANM}"
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip updating anm.imageTag in values.yaml file!"
                                }
                            }
                        }
                        stage("Update APIM Image Tag") {
                            if (buildManifest.apim) {
                                def currentApiMgr = sh(returnStdout: true, script: "yq '.apimgr.imageTag' apim-helm/values-sit.yaml", label: "read apimgr image tag")
                                echo "currently .apimgr.imageTag is: ${currentApiMgr}"
                                def currentTraffic = sh(returnStdout: true, script: "yq '.apitraffic.imageTag' apim-helm/values-sit.yaml", label: "read traffic image tag")
                                echo "currently .apitraffic.imageTag is: ${currentTraffic}"
                                sh script: "yq -i '.apimgr.imageTag=\"${imageTag}\"' apim-helm/values-sit.yaml", label: "update apimgr image tag"
                                sh script: "yq -i '.apitraffic.imageTag=\"${imageTag}\"' apim-helm/values-sit.yaml", label: "update traffic image tag"
                                def afterApiMgr = sh(returnStdout: true, script: "yq '.apimgr.imageTag' apim-helm/values-sit.yaml", label: "read apimgr image tag after update")
                                echo "after update .apimgr.imageTag is: ${afterApiMgr}"
                                def afterTraffic = sh(returnStdout: true, script: "yq '.apitraffic.imageTag' apim-helm/values-sit.yaml", label: "read traffic image tag after update")
                                echo "after update .apitraffic.imageTag is: ${afterTraffic}"
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip updating apimgr.imageTag and apitraffic.imageTag in values.yaml file!"
                                }
                            }
                        }
                        stage("Update Portal Image Tag") {
                            if (buildManifest.portal) {
                                def currentPortal = sh(returnStdout: true, script: "yq '.apiportal.imageTag' apim-helm/values-sit.yaml", label: "read apiportal image tag")
                                echo "currently .apiportal.imageTag is: ${currentPortal}"
                                sh script: "yq -i '.apiportal.imageTag=\"${imageTag}\"' apim-helm/values-sit.yaml", label: "update apiportal image tag"
                                def afterPortal = sh(returnStdout: true, script: "yq '.apiportal.imageTag' apim-helm/values-sit.yaml", label: "read apiportal image tag after update")
                                echo "after update .apiportal.imageTag is: ${afterPortal}"
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip updating apiportal.imageTag in values.yaml file!"
                                }
                            }
                        }
                        stage('Update Chart') {
                            if (buildManifest.containsValue(true)) {
                                sh script: "yq -i '.appVersion=\"2.3.${env.BUILD_NUMBER}\"' apim-helm/Chart.yaml", label: "update appVersion in Chart.yaml"
                                sh script: "yq -i '.version=\"2.3.${env.BUILD_NUMBER}\"' apim-helm/Chart.yaml", label: "update appVersion in Chart.yaml"
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip updating appVersion and version in chart!"
                                }
                            }
                        }
                        stage('Package') {
                            if (buildManifest.containsValue(true)) {
                                sh(script: "helm package apim-helm", label: "Package the Helm Chart")
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip creating helm package!"
                                }
                            }
                        }
                        stage('Push to Nexus') {
                            if (buildManifest.containsValue(true)) {
                                withCredentials([usernamePassword(credentialsId: "userid-password-nexus-admin", passwordVariable: 'pass', usernameVariable: 'user')]) {
                                    sh(script: "curl -v -u ${user}:${pass} --upload-file axway-apim-*.tgz ${nexusHelmRepo}", label: "Push Helm Package to Nexus")
                                }
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip pushing helm package to Nexus!"
                                }
                            }
                        }
                        stage('Commit & Tag') {
                            if (buildManifest.containsValue(true)) {
                                withCredentials([usernamePassword(credentialsId: 'userid-password-gitlab-root', passwordVariable: 'password', usernameVariable: 'username')]) {
                                    def encodedPassword = URLEncoder.encode("$password", 'UTF-8')
                                    sh "git config user.email jenkins@sydneywater.com.au"
                                    sh "git config user.name Jenkins"
                                    sh "cd apim-helm && " +
                                            "git add . && " +
                                            "git commit -m 'Updated by Jenkins Job: ${env.JOB_NAME} and Build No. ${env.BUILD_NUMBER}' && " +
                                            "git push ${gitRepoProtocol}://${username}:${encodedPassword}@${helmGitRepo} &&" +
                                            "git tag -a v${env.BUILD_NUMBER}_${targetEnvironment} -m 'For ${buildManifest} by Jenkins Job: ${env.JOB_NAME}; Build No. ${env.BUILD_NUMBER}' &&" +
                                            "git push ${gitRepoProtocol}://${username}:${encodedPassword}@${helmGitRepo} --tags"
                                }
                            } else {
                                catchError(buildResult: currentBuild.result, stageResult: 'UNSTABLE') {
                                    error "Skip creating helm chart's tag!"
                                }
                            }
                        }
                    }
            )
        }
    }
}

def gitTag() {
    return {
        stage('Git Tag') {
            catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                if (currentBuild.result == null || currentBuild.result.equalsIgnoreCase("SUCCESS")) {
                    withCredentials([usernamePassword(credentialsId: "userid-password-gitlab-root", passwordVariable: 'password', usernameVariable: 'username')]) {
                        def encodedPassword = URLEncoder.encode("$password", 'UTF-8')
                        sh("git config user.name 'Jenkins'")
                        sh("git config user.email 'jenkins@sydneywater.com.au'")
                        sh("git tag -a v${env.BUILD_NUMBER}_${targetEnvironment} -m 'For ${buildManifest} by Jenkins Job: ${env.JOB_NAME}; Build No. ${env.BUILD_NUMBER}'")
                        sh "git push ${gitRepoProtocol}://${username}:${encodedPassword}@${gitRepo} --tags"
                    }
                }
            }
        }
    }
}

def emailNotification() {
    return {
        stage('Email Notification') {
            mail(bcc: '', body: "Build ${env.BUILD_NUMBER} for ${env.JOB_NAME} successfully completed for ${buildManifest}.", cc: '', from: 'jenkins@sydneywater.com.au', replyTo: '', subject: "Build ${env.BUILD_NUMBER} for ${env.JOB_NAME} completed successfully.", to: emailRecipient)
        }
    }
}

def clearWorkspace() {
    return {
        stage('Clear Workspace') {
            cleanWs()
            echo "Workspace deleted!"
        }
    }
}

def postFailure(e) {
    println "Failed because of $e"
    return {
        stage('Email') {
            mail(bcc: '', body: "Build ${env.BUILD_NUMBER} for ${env.JOB_NAME} failed ${e.message}.", cc: '', from: 'jenkins@sydneywater.com.au', replyTo: '', subject: "Build ${env.BUILD_NUMBER} for ${env.JOB_NAME} failed.", to: emailRecipient)
        }
    }
}