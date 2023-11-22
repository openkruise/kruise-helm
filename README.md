# Kruise-Helm

## Overview

The Kruise-Helm repository is a collection of Helm charts that provides a post-upgrade hook for Kubernetes applications. This post-upgrade hook leverages a command-line tool to check the health of OpenKruise workloads after an upgrade. This README will help you understand what Kruise-Helm is and how to use it effectively.

## Prerequisites

Before you can start using Kruise-Helm, you need to ensure you have the following prerequisites:

Kubernetes Cluster: You should have a running Kubernetes cluster. If you don't have one, you can set up a local cluster using tools like Minikube or use a cloud-based solution.

Helm: Make sure you have Helm installed. You can install Helm by following the instructions on the official Helm website.

OpenKruise: Kruise-Helm's post-upgrade hook depends on OpenKruise. Ensure that OpenKruise is installed and configured in your Kubernetes cluster.

## Installation

To install Kruise-Helm and its post-upgrade hook, follow these steps:

Clone the Kruise-Helm repository:

```
git clone https://github.com/openkruise/kruise-helm
```

Change the directory to example_helm_repos :

```
cd kruise-helm/example_helm_repos
```
Here is the example template of postupgrade hook which will perform all openkruise checks inside the cluster and the specified namespace,

```
apiVersion: batch/v1
kind: Job
metadata:
   name: postupgrade-hook
   annotations:
       "helm.sh/hook": "post-upgrade"
       "helm.sh/hook-delete-policy": "hook-succeeded"
spec:
  template:
    spec:
      containers:
      - name: health-check-container
        image: openkruise/hook:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
            lua healthcheck.lua cloneset default -t 5
      restartPolicy: Never
      serviceAccountName: default
```
You can paste the following postupgrade hook inside your helm chart's templates folder with the following rbac roles and the helm chart will perform the specified neccessary health checks.

```
---
---
#Post-upgrade Job Role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: post-install-role
  namespace: default
rules:
- apiGroups: ["apps.kruise.io"]
  resources: ["clonesets","statefulsets","daemonsets","broadcastjobs","advancedcronjobs"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: post-install-rolebinding
  namespace: default
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
roleRef:
  kind: ClusterRole
  name: post-install-role
```

Install & upgrade Kruise-Helm and the post-upgrade hook to your Kubernetes cluster:

```
helm upgrade kruise

OR

helm upgarde kruise-rollout
```

## Usage

Kruise-Helm provides a post-upgrade hook that automatically checks the health of your OpenKruise workloads after a Helm chart upgrade. This is achieved through a command-line tool that is executed as part of the Helm upgrade process.

To use Kruise-Helm effectively, follow these steps:

1. Modify your existing Helm chart to include the Kruise-Helm post-upgrade hook. This can typically be done in the templates/ directory of your Helm chart. Refer to the example templates provided in this repository for guidance.

2. When you perform a Helm upgrade, the post-upgrade hook will be executed automatically. It will use the command-line tool to check the health of your OpenKruise workloads and determine whether the upgrade was successful.

3. Review the post-upgrade hook's output to ensure that your OpenKruise workloads are healthy. If there are issues, you can take appropriate actions to address them.

## The command line tool 

### Overview 

Kubernetes applications often consist of various workload types such as CloneSets, DaemonSets, StatefulSets, AdvancedCronJobs, and BroadcastJobs. Monitoring the health of these workloads is crucial for ensuring the stability and reliability of your applications. The Kubernetes Workload Health Check Tool simplifies this process by allowing you to check the health of multiple workload types in a specified namespace.

### Usage 

The Kubernetes Workload Health Check Tool is a command-line script written in Lua. To use the tool, follow these steps:

Clone this repository or download the healthcheck.lua script to your local environment.

Open your terminal and run the script using the Lua interpreter:

```
lua healthcheck.lua [workload types] [namespace] -t 20
```

Replace [workload types] with a comma-separated list of the workload types you want to check, and [namespace] with the Kubernetes namespace where your workloads are deployed.

For example, to check the health of CloneSets, DaemonSets, and StatefulSets in the my-app namespace, you can run:

```
lua healthcheck.lua cloneset default -w guestbook-clone,guestbook-clone2 -t 10
```

The script will execute health checks for the specified workload types and provide detailed information about the health status of each workload. If any workload is found to be in a "Degraded" state, the script will exit with a non-zero exit code.

Supported Workload Types: 

The Kubernetes Workload Health Check Tool currently supports the following workload types:

 - CloneSet
 - DaemonSet
 - StatefulSet
 - AdvancedCronJob (acj)
 - BroadcastJob (bcj)
 - Rollout

You can specify one or more of these workload types when using the tool.

## Contributing

We welcome contributions to the Kruise-Helm repository. If you'd like to contribute, please follow these steps:

Fork this repository.

Create a new branch for your feature or bug fix.

Make your changes and commit them to your branch.

Create a pull request to merge your changes into the main repository.

Please refer to our CONTRIBUTING.md file for more details.