#!/bin/bash

# Copyright 2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

workloadURL="http://tanzu-simple-web-app.test-namespace.127-0-0-1.sslip.io/"
registryServer=$(grep 'server:' app-toolkit-values.yaml | awk '{print $2}')
registryUser=$(grep 'kp_default_repository_username:' app-toolkit-values.yaml | awk '{print $2}')
registryPass=$(grep 'kp_default_repository_password:' app-toolkit-values.yaml | awk '{print $2}')
developerNamespace=$(grep 'developer_namespace:' app-toolkit-values.yaml | awk '{print $2}')

function main() {
	echo "=== APP TOOLKIT TEST - START ==="

	deleteExistingCluster
	createCluster
	checkExecutables
	updatePackageRepository
	setupSecrets
	installPackage
	createWorkload
	checkWorkload

	echo "=== APP TOOLKIT TEST - PASSED! ==="
}

function deleteExistingCluster {
	validateCommand "tanzu uc" "unmanaged-cluster"
	if $(tanzu uc list | grep -q app-toolkit-test); then
		echo "Existing 'app-toolkit-test' cluster found"
		tanzu uc delete app-toolkit-test
		echo "'app-toolkit-test' cluster deleted"
	fi
}

function createCluster {
	tanzu uc create app-toolkit-test -p 80:80 -p 443:443
}

function checkExecutables() {
	echo "--- Executables Check : Start ---"

	validateCommand "tanzu" "Tanzu CLI"
	validateCommand "tanzu apps" "Applications on Kubernetes"
	validateCommand "tanzu secret" "Tanzu secret management"
	validateCommand "tanzu package" "Tanzu package management"
	validateCommand "kubectl" "kubectl controls the Kubernetes cluster manager"
	validateCommand "docker" "A self-sufficient runtime for containers"

	echo "--- Executables Check : OK! ---"
}

function updatePackageRepository() {
	existingPackageRepo='projects.registry.vmware.com-tce-main-v0.11.0'
	packageRepoUrl='index.docker.io/ryanmattcollins/main@sha256:0bfca475ef9fb8bd4cc503811371a491fcf72c44a039831e9c29fb44567d4257'
	echo "Updating '$existingPackageRepo' to use '$packageRepoUrl'"
	tanzu package repository update $existingPackageRepo -n tanzu-package-repo-global --url $packageRepoUrl
}

function setupSecrets() {
	echo "--- Setting Up Secrets : Start ---"

	tanzu package install secretgen-controller --package-name secretgen-controller.community.tanzu.vmware.com --version 0.8.0
	tanzu secret registry add registry-credentials --server $registryServer --username $registryUser --password $registryPass --export-to-all-namespaces --yes

	validateCommand "tanzu secret registry list" "registry-credentials"

	echo "--- Setting Up Secrets : OK! ---"
}

function installPackage() {
	echo "--- Installing App Toolkit : Start ---"

	tanzu package install app-toolkit -p app-toolkit.community.tanzu.vmware.com -v 0.2.0 -n tanzu-package-repo-global -f app-toolkit-values.yaml
	validateCommand "tanzu package installed get app-toolkit -n tanzu-package-repo-global" "ReconcileSucceeded"

	echo "--- Installing App Toolkit : OK! ---"
}

function createWorkload(){
	echo "--- Creating the Workload : Start ---"

	tanzu apps workload create tanzu-simple-web-app --git-repo https://github.com/vmware-tanzu/application-toolkit-sample-app --git-branch main --type=web --app tanzu-simple-web-app --yes -n $developerNamespace
	watchCommand "tanzu apps workload tail tanzu-simple-web-app" "Build successful" 5

	echo "--- Creating the Workload : OK! ---"
}

function checkWorkload(){
	echo "--- Checking the Workload : Start ---"
	
	pollCommand "curl $workloadURL" "Hello World" 5

	echo "--- Checking the Workload : OK! ---"
}

function validateCommand() {
	cmd=$1
	match=$2
	echo "Validating '$cmd'"
	output=$($cmd 2>&1)
	echo "$output" | grep -q "${match}"
	
	if [ $? -ne 0 ]; then
		fail "'$match' not found after executing '$cmd'"
	fi
}

function watchCommand() {
	cmd=$1
	match=$2
	timeout=$3
	duration=5
	count=0
	echo "Waiting for '$cmd' to match '$match'"
	until $($cmd 2&>1) | grep -q "${match}"; do
		minutes=$(( $count / 60 ))
		if [[ "$minutes" -gt "$timeout" ]]; then
			fail "Timeout exceeded waiting for '$cmd' to return expected result"
		fi
		sleep $duration
		count=$((count+duration))
	done
}

function pollCommand() {
	cmd=$1
	match=$2
	timeout=$3
	duration=5
	count=0
	flag=1
	echo "Polling '$cmd' until it contains '$match'"
	while [ $flag -ne 0] ; do
		output=$($cmd 2>&1)
		echo "$output" | grep -q "${match}"
		flag=$?
		minutes=$(( $count / 60 ))
		if [[ "$minutes" -gt "$timeout" ]]; then
			fail "Timeout exceeded polling for '$cmd' to return expected result"
		fi
		sleep $duration
		count=$((count+duration))
	done
}

function fail() {
	echo "=== APP TOOLKIT TEST - FAILED! ==="
	echo "$1"
	exit 1
}

main
exit 0
