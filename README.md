[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

### THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE
### PLEASE EXERCISE CAUTION USING AWSCLI SINCE IT WILL CREATE BILLABLE AWS SERVICES IN YOUR ACCOUNT AND MAY NOT TERMINATE THEM AUTOMATICALLY

# Raku CLI::AWS::EC2-Simple

## Getting Started

- apt-get update && apt-get install aws-cli
- aws configure _[enter your config here]_
- git clone https://github.com/p6steve/raku-CLI-AWS-EC2-SImple.git
- cd raku-CLI-AWS-EC2-Simple/.racl-config
- cat .racl-config/aws-ec2-launch.yaml 
- cd ../raku-CLI-AWS-EC2-Simple/bin
- ./racl-aws-ec2 _[enter your commands here]_

## Config

This launches the standard AWS Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2022-12-01.
Edit this yaml file to meet your needs...

```
instance:
    image: 'ami-0f540e9f488cfa27d'
    type: 't2.micro'
    security-group:
        name: 'MySG'
        rules:
            - inbound:
                port: 80
                cidr: '0.0.0.0/0'
            - inbound:
                port: 443 
                cidr: '0.0.0.0/0'
```

## Usage

```
./racl-aws-ec2 [--id=<Str>] [--nsu] [--eip] [-y] <cmd>
  
    <cmd>         One of <list launch setup connect state terminate nuke>
    --id=<Str>    Running InstanceId of form 'i-0785d8bd98b5f458b'
    --nsu         No setup (suppress launch from running setup)
    --eip         Allocates (if needed) and Associates Elastic IP
    -y            Silence confirmation <nuke> cmd only
```

## Wordpress Deploy & Control

[This section will probably go into raku-CLI-WP-Simple]

viz. [digital ocean howto](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose#step-3-defining-services-with-docker-compose)

- client script 'raku-wp --launch'


## NOTES

- unassigned Elastic IPs are chargeable ($5 per month ish), may be better to run one free tier instance
- rules about rules
  - will always open port 22 (SSH) inbound from this client IP
  - will re-use the existing named Security Group (or create if not present)
  - only inbound are supported for now 
  -  if you want to keep the name and change the rules, then delete via the aws console

### Copyright
copyright(c) 2022 Henley Cloud Consulting Ltd.
