
# Launching a Trading Robot on the Cloud

## Background
This guide provides step-by-step instructions for launching a Trading Robot in the cloud. Specifically, it's designed to connect TradingView with Interactive Brokers swiftly (in approximately 5 minutes) using Terraform.

## Prerequisites
Before you begin, ensure the following:
- **Terraform and AWS CLI**: Installed and configured on your local machine.
- **AWS Credentials**: Necessary credentials (Access Key ID and Secret Access Key) are set up for Terraform usage.
- **Familiarity with TradingBoat's Docker Setup**: It's assumed you're acquainted with the chapters from the book "Converting TradingView PineScript Alerts into Interactive Brokers Orders".
- **GitHub Repository Familiarity**: Have an understanding of the [PlusGenie/ib-gateway-docker](https://github.com/PlusGenie/ib-gateway-docker) repository, which focuses on converting TradingView PineScript Alerts into Interactive Brokers Orders.

## Step-by-Step Guide

### Step 1: Initialize Terraform
Clone the TradingBoat Terraform repository:
```bash
git clone https://github.com/PlusGenie/tradingboat-terraform.git
cd tradingboat-terraform/src/docker
```
Run `terraform init` to initialize Terraform, download the AWS provider, and prepare your environment for deployment.

### Step 2: Terraform Configuration Files
Create a file named `terraform.tfvars` in the TradingBoat Terraform directory.
Define necessary variables such as AWS region, instance type, AMI ID, and TradingBoat credentials. Here's an example to guide you:
```hcl
TWS_USERID="yourPaperAccountID"
TWS_PASSWORD="yourPaperAccountPassword"
NGROK_AUTH="2a60uMoemV6LGtDOcGWVH5HYFHv_YOUR_NGROM_AUTH"
aws_ALLOWED_IPS = ["90.192.XXX.1/32"]
aws_instance_type="t2.medium"
aws_region="eu-west-2"
aws_ssh_key_name="Terraform_TBOT" # SSH PEM File
```

### Step 3: Plan Your Deployment
Run `terraform plan` to review the actions Terraform will perform. This is a crucial step to verify your configurations and understand the resources that will be created on AWS.

### Step 4: Deploy TradingBoat
Execute `terraform apply` to start the deployment process. Confirm the action by typing 'yes' when prompted.

### Step 5: Accessing TradingBoat
Find the Public IP: Terraform will provide the public IP address of the EC2 instance upon completion.
Access TBOT Interface: Navigate to `http://[YourInstancePublicIP]:5000` in your web browser.
Access via VNC Viewer: Connect to `[YourInstancePublicIP]:5900` to interact with the IB Gateway through the VNC server.

### Step 6: Managing Your Infrastructure
Monitor: Keep an eye on the AWS Console and Terraform logs to ensure your resources are running smoothly.
Update: Modify your Terraform configuration files as needed and re-run `terraform apply` for any changes.
Destroy: Use `terraform destroy` to dismantle all resources when they're no longer needed, preventing ongoing AWS costs.

## Additional Information

### Accessing TBOT on TradingBoat
SSH into your AWS cloud instance using:
```bash
ssh -i Terraform_TBOT.pem ubuntu@YourInstancePublicIP
```

### Accessing Docker Containers
Once connected to AWS EC2 via SSH, verify that containers are running using `tail -f /var/log/terraform-tbot.log`.
Access a specific container with `docker exec -it tbot-on-tradingboat bash`.

### Debugging Tbot Terraform Logging
To view real-time logging messages, execute `tail -f /var/log/cloud-init-output.log`.

## Warning
- **Educational Purposes**: This guide is for educational purposes only. Do not share your SSH key or use real Interactive Broker usernames and passwords.
- **Cost Awareness**: Ensure you destroy your Terraform setup when not in use to avoid continuous AWS costs.
- **Performance Considerations**: Note that running Docker Containers may be slower than running the native TradingBoat application. For native application setup, refer to the course book: "Converting TradingView PineScript alerts into Interactive Brokers orders".


## Reference

* [The extensive instructions and invaluable insights, enabling you to effectively leverage TBOT for your trading activities](https://www.udemy.com/course/simple-and-fast-trading-robot-setup-with-docker-tradingview/)

* [Book: Converting TradingView PineScript Alerts into Interactive Brokers Orders](https://tbot.plusgenie.com/book-converting-tradingview-pinescript-alerts-into-interactive-brokers-orders/)
