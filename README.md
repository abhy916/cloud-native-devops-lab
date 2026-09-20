# Cloud-Native DevOps Lab

An end-to-end DevOps portfolio project demonstrating CI/CD, Infrastructure as Code, containerization, AWS deployment, Kubernetes, Helm, GitOps, and monitoring.

The project uses a simple Spring Boot application as the workload while focusing on the engineering practices and tooling required to build, deploy, operate, and monitor it.

## Project Goals

- Build and test a Java Spring Boot application using Maven.
- Containerize the application using Docker.
- Automate CI/CD using Jenkins.
- Store versioned container images in Amazon ECR.
- Provision AWS infrastructure using Terraform.
- Deploy containers to Amazon EC2 through AWS Systems Manager (SSM).
- Expose the AWS deployment through an Application Load Balancer.
- Deploy the application to Kubernetes.
- Package Kubernetes resources using Helm.
- Implement GitOps deployment using Argo CD.
- Demonstrate Argo CD self-healing and configuration drift reconciliation.
- Monitor Kubernetes using Prometheus and Grafana.
## Application

The workload is a Spring Boot application running on port `8080`.

Health endpoint:

```text
GET /health
```

Expected response:

```text
Application is healthy
```

## Architecture

The project demonstrates two deployment approaches.

### 1. AWS CI/CD Deployment

```text
Developer
   |
   v
GitHub
   |
   v
Jenkins
   |
   +--> Maven Build & Test
   |
   +--> Docker Build
   |
   v
Amazon ECR
   |
   v
AWS Systems Manager (SSM)
   |
   v
Amazon EC2
   |
   v
Docker Container :8080
   |
   v
Application Load Balancer
   |
   v
/health
```

Terraform provisions the AWS infrastructure, including EC2, security groups, IAM instance profile, Application Load Balancer, target group, listener, and health checks.

Jenkins builds and tests the application, creates a Docker image tagged with the Jenkins build number, pushes the image to Amazon ECR, and deploys the new image to EC2 using AWS Systems Manager.

### 2. Kubernetes GitOps Deployment

```text
GitHub
   |
   v
Helm Chart
   |
   v
Argo CD
   |
   v
Docker Desktop Kubernetes
   |
   v
NGINX Ingress
   |
   v
ClusterIP Service :80
   |
   v
Spring Boot Pod :8080
   |
   v
/health
```

Argo CD continuously reconciles the Kubernetes deployment with the desired state stored in Git.

A deliberate configuration drift test was performed by manually scaling the application from one replica to two replicas. Argo CD detected the `OutOfSync` state and automatically restored the deployment to the Git-defined replica count using self-healing.

### Monitoring

```text
Kubernetes
   |
   v
Prometheus
   |
   v
Grafana
```

The `kube-prometheus-stack` Helm chart provides Prometheus, Grafana, Alertmanager, kube-state-metrics, and the Prometheus Operator.

Prometheus metric collection was validated using PromQL, and the Prometheus data source was verified from Grafana Explore.

The node-exporter component was disabled for the local Docker Desktop environment because the host root filesystem does not support the mount propagation required by node-exporter. This limitation is specific to the local lab environment.

## Technology Stack

| Area | Technology |
|---|---|
| Application | Java 17, Spring Boot 3 |
| Build | Maven |
| Source Control | Git, GitHub |
| CI/CD | Jenkins |
| Containerization | Docker |
| Container Registry | Amazon ECR |
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| AWS Deployment | EC2, Systems Manager (SSM), Application Load Balancer |
| Kubernetes | Docker Desktop Kubernetes |
| Package Management | Helm |
| GitOps | Argo CD |
| Ingress | NGINX Ingress Controller |
| Monitoring | Prometheus, Grafana |
| Kubernetes Metrics | kube-state-metrics |
| Alerting Component | Alertmanager |

## Repository Structure

```text
cloud-native-devops-lab/
├── app/          # Spring Boot application and tests
├── docker/       # Dockerfile
├── terraform/    # AWS infrastructure as code
├── jenkins/      # Jenkins CI/CD pipeline
├── kubernetes/   # Original Kubernetes manifests
├── helm/         # Helm chart for Kubernetes deployment
├── argocd/       # Argo CD Application definition
├── scripts/      # Supporting scripts
├── docs/         # Project documentation
└── README.md
```

## CI/CD Pipeline

The Jenkins pipeline performs the following stages:

1. Checkout source code from GitHub.
2. Run Maven tests.
3. Package the Spring Boot application.
4. Build a Docker image.
5. Tag the image using the Jenkins build number.
6. Authenticate to Amazon ECR.
7. Push the versioned image to ECR.
8. Discover the running application EC2 instance.
9. Deploy the new image remotely using AWS Systems Manager.
10. Verify that the SSM deployment command completed successfully.

AWS Systems Manager is used instead of SSH for deployment to the EC2 instance.

The deployment process pulls the new image before stopping the existing application container, then starts the new container on port `8080`.

## Infrastructure as Code

Terraform manages the AWS application infrastructure.

The configuration includes:

- Amazon Linux 2023 EC2 instance
- Security groups
- EC2 IAM role and instance profile
- ECR read permissions for EC2
- AWS Systems Manager permissions
- Application Load Balancer
- Target group
- HTTP listener
- `/health` target health check
- EC2 target registration

The EC2 application security group permits application traffic on port `8080` only from the ALB security group rather than exposing the application port directly to the internet.

To minimize lab costs, infrastructure is created for testing and destroyed afterward using Terraform. The Terraform configuration remains in Git as the reproducible infrastructure definition.
## Kubernetes and Helm

The application was initially deployed using standard Kubernetes manifests containing:

- Deployment
- ClusterIP Service
- NGINX Ingress

The application container listens on port `8080`. The Kubernetes Service exposes port `80` and forwards traffic to the Pod on `targetPort: 8080`.

The Kubernetes resources were subsequently converted into a reusable Helm chart. Application settings such as image repository, image tag, replica count, service ports, and ingress configuration are managed through `values.yaml`.

The Helm chart was validated using:

```bash
helm lint helm/devops-app/
helm template devops-app helm/devops-app
```

## GitOps with Argo CD

Argo CD manages the application deployment using the Helm chart stored in this Git repository.

The Argo CD Application is configured with:

- GitHub repository as the source
- `master` as the target revision
- `helm/devops-app` as the deployment path
- Local Kubernetes cluster as the destination
- Automated synchronization
- Pruning enabled
- Self-healing enabled

GitOps reconciliation was validated by deliberately changing the live Deployment replica count from `1` to `2`.

Argo CD detected the configuration drift, reported the application as `OutOfSync`, and automatically restored the Deployment to the Git-defined state.

The reconciliation was confirmed through the Argo CD Application status and events, including an automated self-heal attempt.

Final validation:

```text
SYNC STATUS:   Synced
HEALTH STATUS: Healthy
```

## Monitoring

Kubernetes monitoring is provided using `kube-prometheus-stack`.

The monitoring namespace contains:

- Prometheus
- Grafana
- Alertmanager
- Prometheus Operator
- kube-state-metrics

Prometheus scraping was validated using the PromQL query:

```promql
up
```

The query returned active Kubernetes monitoring targets.

Grafana was connected to Prometheus and the same query was successfully executed through Grafana Explore, confirming the monitoring flow:

```text
Kubernetes metrics -> Prometheus -> Grafana
```

Some Docker Desktop-specific scrape targets may not be available in the local development environment.

Prometheus node-exporter was disabled because Docker Desktop does not provide the root filesystem mount propagation expected by node-exporter. Prometheus, Grafana, kube-state-metrics, Alertmanager, and the Prometheus Operator remain operational.

## Troubleshooting and Key Learnings

Several real-world issues were encountered and resolved while building the project.

### AWS Load Balancer Health Checks

The application initially required validation of the ALB target health configuration.

The target group was configured to use the Spring Boot `/health` endpoint, and security groups were configured so that port `8080` on the EC2 instance accepts application traffic only from the ALB security group.

### Jenkins Deployment through AWS Systems Manager

Instead of exposing SSH for deployments, Jenkins uses AWS Systems Manager Run Command.

The EC2 instance uses an IAM role with Systems Manager and ECR permissions, while Jenkins has permissions to discover the target EC2 instance and submit and check SSM commands.

This demonstrated IAM-based remote deployment without managing SSH keys.

### Git Authentication from WSL

Git push operations from WSL occasionally failed because VS Code Git AskPass environment variables referenced an unavailable VS Code socket.

The issue was resolved by clearing the stale AskPass environment variables and allowing Git to use normal HTTPS authentication.

### Argo CD Configuration Drift

A manual Kubernetes scaling change intentionally created configuration drift.

Argo CD detected the difference between the live cluster and Git, transitioned the application to `OutOfSync`, and automatically reconciled it back to the desired state because self-healing was enabled.

### Prometheus Node Exporter on Docker Desktop

The node-exporter Pod entered `CrashLoopBackOff` with:

```text
path / is mounted on / but it is not a shared or slave mount
```

Inspection of the Pod state and Kubernetes events identified a host filesystem mount-propagation incompatibility with the Docker Desktop Kubernetes environment.

The chart configuration was inspected and node-exporter was disabled using:

```text
nodeExporter.enabled=false
```

The remaining monitoring components subsequently reached a healthy running state.

## Cost Management

AWS infrastructure is intentionally temporary for this lab.

Terraform-managed EC2 and ALB resources are destroyed after validation to prevent unnecessary ongoing charges. Amazon ECR is retained as the container image registry for the project.

This approach keeps the infrastructure reproducible while minimizing cloud costs.

## Current Project Status

The following capabilities have been successfully demonstrated:

- Spring Boot application build and testing
- Docker containerization
- Jenkins CI/CD
- Amazon ECR image publishing
- Terraform-based AWS infrastructure
- EC2 deployment using AWS Systems Manager
- Application Load Balancer routing and health checks
- Kubernetes Deployment, Service, and Ingress
- Helm packaging
- Argo CD automated GitOps synchronization
- Argo CD self-healing
- Prometheus monitoring
- Grafana visualization and Prometheus integration
- Troubleshooting across AWS, Kubernetes, GitOps, and monitoring

## Future Enhancements

Potential extensions include:

- Spring Boot Actuator and Micrometer application metrics
- Prometheus ServiceMonitor for application-specific metrics
- Kubernetes readiness and liveness probes
- Resource requests and limits
- Automated image-tag updates in the GitOps workflow
- Deployment to Amazon EKS
- HTTPS/TLS and DNS automation
- Alerting rules and notification integrations
- Centralized application logging
