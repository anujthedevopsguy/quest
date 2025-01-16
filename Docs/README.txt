Architecture and CI/CD pipeline

Please find quest.png file in the same folder (Docs).

CI/CD --> Flow is very simple. When a user merge the PR to the main branch, a codebuild job will be triggered which will build the app and make
docker file which will be pushed to the ECR image. next step in the same job is to trigger the ECS deployment using rolling update. Please refer to Dockerfile
and buildspace.yml file to understand how build and deploy is working.

future Improvement: This could be a full fledge CI/CD which would contain source --> build -> test -> deploy stage . ECS support Blue/Green deployment
stretagy. we can follow the same in our pipeline.

Terraform:
Please have a look into terraform folder.All infrasturcuture is build using terraform. following infra pieces are managed by terraform.
Network stack: vpc, public and private subnet, NAT, routing table etc.
COnfig level: IAM roles and polcies 
CI/CD: codebuild.tf having code for codebuild job and corresponding IAM role and policy. main.tf also contains code to create ECS cluster and
service along with seurity group.

Improvement: terraofrm code could be moduler and arrange in a better way. Due to shortage of time, I am skipping this. Note that last minute, I made 
some changes to make this task run. so terraform code is little out of sync.

Architecture:
It simple. ECS cluster is deployed in the private subnets and load balancer in public subnet. user hits the ALB url and get the page load. please find
homepage.png.
Improvements: can make it better by adding autoscaling and adding security from ALB front side.
