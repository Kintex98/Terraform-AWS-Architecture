- [**terraform-aws-architecture**](#terraform-aws-architecture)
  - [**Introduction**](#introduction)
  - [**aws-stig-hardened-amis**](#aws-stig-hardened-amis)
    - [**STIG Component Naming Scheme**](#stig-component-naming-scheme)
    - [**Parent Image Naming Scheme**](#parent-image-naming-scheme)
    - [**Expanding the Automation**](#expanding-the-automation)
      - [**Exact AMI Build Invocation**](#exact-ami-build-invocation)
      - [**Clean Up Old AMIs**](#clean-up-old-amis)

# **terraform-aws-architecture**

AWS Architecture Solutions written in HCL to be deployed with Terraform

## **Introduction**
The goal of this repository is to provide solutions for key AWS architecture needs and/or Terraform dynamic coding challenges. I will try to keep the cost, dependencies, deployed resources, and maintenance succinct in that general order of importance. I may discuss ways in which you can further expand on the automation and I may also provide those solutions if asked.

## **aws-stig-hardened-amis**

Used to dynamically deploy "n" amis where "n" = # of objects defined in var.ami_specs

**Depends On**
- VPC  - Default VPC should exist, though not recommended
- Security Group - Default SG should exist, though not recommended

**Deploys**
- IAM Role - EC2ImageBuilderInstanceRole
- Image Builder Pipeline - <parent_image>-pipeline*n
  - Image Builder Recipe - <parent_image>-recipe*n
  - Image Builder Infrastructure Configuration - <parent_image>-infra-config*n
  - Image Builder Distribution Configuration - <parent_image>-distrib-config*n

### **STIG Component Naming Scheme**
```
stig-build-<platform>-<severity>
e.g. stig-build-windows-medium
```
| **Severity** | **Platform** |
| ------------ | ------------ |
| low          | linux        |
| medium       | windows      |
high

### **Parent Image Naming Scheme**
```
<base platform>-<type>-<CPU architecture>
e.g. windows-server-2019-english-full-sql-2019-enterprise-x86 or amazon-linux-2023-ecs-optimized-arm64
```
| **Base Name**       | **Type**                         | **CPU Architecture** |
| ------------------- | -------------------------------- | -------------------- |
| amazon-linux-2      | ecs-optimized                    | x86                  |
| amazon-linux-2023   | ecs-optimized-kernel-5           | arm64                |
| windows-server-2016 | english-full-base                |
| windows-server-2019 | english-full-sql-2019-enterprise |
| windows-server 2022 | english-core-base                |

### **Expanding the Automation**

#### **Exact AMI Build Invocation**

If all you care about are AWS AMIs, then for a small/non-existent uptick in costs, you can build about the latest AMI immediately rather than utilizing Image Builder cron jobs/image publishing schedule (which lags 0-4 days behind the AMI release schedule).
1. Create an EventBridge rule which can trigger the Image Builder Pipeline
2. Create a Lambda function which PutEvents when triggered
3. Create a SNS Subscription to one of these SNS Topics and to invoke the lambda function
    
    | Platform              | Topic ARN                                                          |
    | --------------------- | ------------------------------------------------------------------ |
    | **Windows**           | "arn:aws:sns:us-east-1:801119661308:ec2-windows-ami-update"        |
    | **Amazon Linux 2**    | "arn:aws:sns:us-east-1:137112412989:amazon-linux-2-ami-updates"    |
    | **Amazon Linux 2023** | "arn:aws:sns:us-east-1:137112412989:amazon-linux-2023-ami-updates" |

#### **Clean Up Old AMIs**

Amazon deprecates their AMIs every 4 build cycles. This is a good habit to have as it'll clean up used EBS storage, remove clutter from AMI list and prevent careless mistakes from using an old AMI.

1. EventBridge rule triggers on Image Builder completion
2. Sends event to Lambda function which will parse for name of <parent_image> in pipeline finished event
3. If pipeline images >4, Lambda will deregister the oldest AMI, delete its snapshot, and delete the corresponding Image Builder Image version.