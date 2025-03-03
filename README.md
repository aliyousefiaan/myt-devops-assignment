# myt-devops-assignment
This repository is based on the DevOps assignment outlined in ASSIGNMENT.md. Below, I will explain each part of the repository.

## Application (/app)
The application is a simple Flask-based web service.

### Features
- Prometheus metrics: Implemented using the Prometheus SDK to track the number of requests and their response times. Metrics are exposed via the /metrics endpoint.
- Health check path (/health): Provides a simple endpoint to check the application's health, used for liveness and readiness probes in Kubernetes.

### Dockerfile
The application is containerized using a lightweight Alpine-based Python image to ensure a minimal and secure runtime environment. Below is a summary of the Dockerfile:

- Runs as a non-root user (UID 1000) for better security.
- Installs dependencies without caching to keep the image minimal.
- Prevents Python from writing .pyc files.
- Waitress WSGI server is used for production deployment instead of Flask’s built-in server.

### Potential enhancements
- Improve the health check to verify database connectivity and other dependencies (If applicable).
- Integrate OpenTelemetry SDK to Provide distributed tracing capabilities to monitor request flow across services (If applicable).

## GitHub Actions (.github)

### Build and publish App Docker Image
This GitHub Actions workflow automates the process of building and pushing a Docker image for the application whenever changes are made to the main branch or when a new tag is pushed. It specifically triggers when changes occur in the app/ directory.

### Pylint Code Analysis
This GitHub Actions workflow automates static code analysis using Pylint to ensure Python code quality in the app/ directory. It runs whenever changes are pushed to the main branch.

### Potential enhancements
- Automated infrastructure deployment: Use terraform in GitHub Actions to provision, update, and destroy cloud resources automatically, ensuring infrastructure is always in the desired state.
- Use GitHub Actions caching to speed up Python package installation and Docker builds.
- Add security scanner tools like Trivy, tfsec, and etc.

## Helm chart (/helm)
The helm chart of the application. The Helm chart uses a values.yml file to configure the deployment. By default, these values are set for a basic deployment. However, when deploying through Terraform, we override these values dynamically to optimize resource allocation, autoscaling, networking and etc. based on the target environment (dev or production).

### Features
- Support for podSecurityContext, securityContext, livenessProbe, ReadinessProbe, affinity, tolerations, volumes, envs and etc. 
- Ingress
- HorizontalPodAutoscaler
- PodDisruptionBudget
- ServiceMonitor
- NetworkPolicy
- Service
- Deployment

## Terraform (/terraform)

## Deploy

### Pre-requirements
- AWS access & secret key (name: myt-devops-assignment-terraform | Minimum AWS permissions necessary for a Terraform run)
- Private bucket to store terraform state (name: myt-devops-assignment-iac-terraform-state)

### Requirements packages
- terraform
- awscli
- kubectl
- helm

### Set the AWS credential
```bash
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

### Use Terraform to build infrastructure on AWS
```bash
cd terraform
terraform init
terraform workspace new dev / terraform workspace select dev
terraform apply --var-file=dev.tfvars
```

## Screenshots
Relevant screenshots related to the application, monitoring, deployments, and infrastructure setup can be found in the /assets/screenshots directory.
