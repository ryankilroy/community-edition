#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

REGISTRY_SERVER=$(grep server: app-toolkit-values.yaml | awk '{print $2}')
REGISTRY_USER=$(grep kp_default_repository_username: app-toolkit-values.yaml | awk '{print $2}')
REGISTRY_PASS=$(grep kp_default_repository_password: app-toolkit-values.yaml | awk '{print $2}')
tanzu secret registry add registry-credentials --server $REGISTRY_SERVER --username $REGISTRY_USER --password $REGISTRY_PASS --export-to-all-namespaces --yes