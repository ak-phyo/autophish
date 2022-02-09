# autophish
Just teraform code to deploy gophish infra.

# Phishing infra auto deployment with terraform

## Installation

- First , download the terraform binary file from the link below.

  - <https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip>

- Extract the zip file and then place it in bin folder.

```
#wget https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip -O terraform.zip
#unzip terraform.zip
#chmod +x terraform
#cp terraform /usr/bin/
```

- Terraform will interact with the AWS Cloud using valid credentials that we provide. Head to AWS IAM—the user management service—to create a programmatic account and grant it full access to all EC2 operations. EC2 is the AWS service managing machines, networks, load balancers, and more.In the IAM user creation panel, give your newly created user programmatic access. Allow the user full control over EC2 to administer machines by attaching the **AmazonEC2FullAccess** policy. Download the credentials as a .csv file. Note the access key ID and secret access key. Once in possession of an AWS access key and secret access key, download the AWS command line tool and save your credentials.

```
#apt install awscli
#aws configure
AWS Access Key ID [None]: AKIA44E<REDACTED>DF5A0
AWS Secret Access Key [None]: DEqg5dDxDA4uS<REDACTED>7Tzi53...
Default region name [None]: us-east-2
```

## Deployment

First, we need to initialize terraform.

```
terraform init
```

And format the main.tf and plan instructoin to build a list of changes about to happen to the infra.

```
terraform fmt && terraform plan
```

We're now ready to push this into production with simple command.

```
terraform apply
```

## Information

User lists : Gophish default admin and testuser
Password : ``` password```
Default aws region : ohio (us-east-2)

We use the t2.small instance type for phishing campaign. Each node has own smtp relay service with 2 min delay. You can adjust by changing default_destination_rate_delay value.

```
default_destination_rate_delay=2m
```

We can adjust the instance number in main.tf . Default is two.

```
count = 2
```
### need to update

```
vpc_security_group_ids      = [aws_security_group.secgroup.id]
key_name                    = "privatekeyname"
username and hash

sasl_password   (it need to be replaced with your amazon SES creds.)
default_destination_rate_delay (change when you would like to adjust the sending delays.)

you can also adjust ingress egress rules.
```
