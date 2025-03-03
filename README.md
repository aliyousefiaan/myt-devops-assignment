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
This directory includes Terraform files for deploying infrastructure on AWS. The various AWS services such as VPC, Route53, S3, EKS, IAM, ACM, ASM and etc. are utilized for the infrastructure.

### Features
- kube-prometheus-stack: Provides monitoring, and dashboards (Prometheus, Grafana).
- External Secrets Operator: Syncs secrets from AWS Secrets Manager to Kubernetes.
- External DNS: Manages DNS records for Route 53 dynamically.
- Provisioning of ALB/NLB for EKS Ingress and Services is handled by AWS Load Balancer Controller.
- The infrastructure includes a custom AWS VPC with both public and private subnets for enhanced security and network segmentation.
- NAT Gateway is used to allow private subnets to access the internet while keeping them secure.

### app.tf

#### Kubernetes Namespace
The application is deployed inside a dedicated Kubernetes namespace to ensure isolation from other workloads. This improves security, organization, and resource management.

#### External Secrets for Secure Credential Management
Secrets such as database passwords and application keys are securely stored in AWS Secrets Manager (ASM). The Kubernetes External Secrets Operator automatically retrieves these secrets and maps them into Kubernetes secrets, ensuring that the application can securely access them without hardcoding credentials.

#### Deploying the Application with Helm
The application is deployed using Helm, which simplifies Kubernetes deployments by using templates. The deployment is atomic, meaning it will roll back in case of failure. Configuration values such as CPU and memory limits, domain settings, and AWS region are dynamically passed using a template.

#### Ingress Configuration and Load Balancing
An AWS Application Load Balancer (ALB) is used as the ingress controller, exposing the application securely to the internet. TLS termination is handled using an SSL certificate issued by AWS Certificate Manager (ACM). The External DNS service automatically updates the application’s domain records in Amazon Route 53, ensuring smooth access.

#### Autoscaling Configuration
The application scales dynamically based on CPU and memory utilization using the Horizontal Pod Autoscaler (HPA). This ensures that the system automatically adjusts the number of running pods based on workload demand, improving performance and cost efficiency.

#### Network Policies for Security
Strict network policies control incoming and outgoing traffic. The application allows incoming connections only from a monitoring namespace (such as Prometheus) and specific subnets, while egress (outgoing) traffic is blocked unless explicitly defined. This enhances security by restricting unauthorized access.

#### Pod and Container Security
The deployment enforces strict security settings, ensuring that the application runs with least privilege:

- Runs as a non-root user to reduce security risks.
- Prevents privilege escalation to minimize attack vectors.
- Uses a read-only filesystem, preventing malicious file modifications.
- Drops all unnecessary capabilities for added security.

#### Environment Variables and Application Secrets
The application retrieves necessary configuration values and secrets dynamically:

- The API base URL is set based on the environment.
- Logging levels are adjusted for dev and production environments.
- Sensitive credentials (like SECRET_KEY and DB_PASSWORD) are securely fetched from Kubernetes secrets, which in turn are synced from AWS Secrets Manager.

#### Pod Affinity and Anti-Affinity
The affinity settings define scheduling rules to distribute the application pods efficiently across the cluster.

- Pod Anti-Affinity (Host-Level): Ensures that application pods do not run on the same physical node (kubernetes.io/hostname). This improves fault tolerance by spreading workloads across different nodes.

- Pod Anti-Affinity (Zone-Level): Ensures that application pods are deployed across different availability zones (failure-domain.beta.kubernetes.io/zone). This enhances high availability, reducing the risk of downtime if a zone becomes unavailable.

#### ServiceMonitor for Prometheus Metrics
The ServiceMonitor is enabled to integrate the application with Prometheus for monitoring.

#### Pod Disruption Budget (PDB)
A Pod Disruption Budget (PDB) is defined to maintain application availability during maintenance activities like node upgrades or cluster scaling.

#### Resource Requests and Limits
The application defines resource requests and limits to ensure efficient scheduling and prevent excessive resource consumption.

#### Liveness and Readiness Probes
Kubernetes uses probes to determine if a pod is healthy and ready to serve traffic.

### Potential enhancements
- Use a logging system like ELK (Elasticsearch, Logstash, Kibana) or Loki for collecting logs.
- GitOps Deployment: Utilize FluxCD or ArgoCD to automate Kubernetes deployments by continuously syncing with the Git repository.
- Automatic Secret Rotation: Implement AWS Lambda functions to periodically rotate and update secrets in AWS Secrets Manager.

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
