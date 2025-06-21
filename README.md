[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

### _PLEASE EXERCISE CAUTION USING AWSCLI SINCE IT WILL CREATE BILLABLE AWS SERVICES IN YOUR ACCOUNT AND MAY NOT TERMINATE THEM AUTOMATICALLY_

# Raku CLI::AWS::EC2-Simple

This module provide a simple abstraction of the AWS command line interface, aka [awscli](https://aws.amazon.com/cli/), for Amazon's EC2 compute web service.

If you encounter a feature of EC2 you want that's not implemented by this module (and there are many), please consider sending a pull request.

## Getting Started

- apt-get update && apt-get install awscli [macOS brew update && brew install awscli]
- aws configure _[enter your config here]_  (output format 'json')
- zef install CLI::AWS::EC2-Simple
- raws-ec2 _[enter your commands here]_

## Usage

```
./raws-ec2 [--id=<Str>] [--nsu] [--eip] [-y] <cmd>
  
    <cmd>         One of <list launch setup connect state stop start terminate nuke>
    --id=<Str>    Running InstanceId of form 'i-0785d8bd98b5f458b'
    --nsu         No setup (suppress launch from running setup)
    --eip         Allocates (if needed) and Associates Elastic IP
    -y            Silence confirmation <nuke> cmd only
```

Will make an (e.g.) ```MyKeyPair1672164025.pem``` from your credentials in your $*HOME dir

## Config

```launch``` reads ```aws-ec2-launch.yaml``` which is preloaded with the standard AWS Canonical, Ubuntu, 24.04 LTS, amd64 jammy image build on 2022-12-01.
Edit this yaml file to meet your needs...
... since AMI are specific to region/account you will need to do "manual" setup once and then save your own "already applied" AMI

- cat .raws-config/aws-ec2-launch.yaml 

```
instance:
    image: ami-044415bb13eee2391            # <== the standard, clean AWS Ubuntu
    #image: ami-0c1163e529aeb9b20            # <== AWS Ubuntu plus raws-ec2 setup already applied (use --nsu flag)
    #type: t2.micro                          # <== the basic, free tier eligible machine (12 credits/hr)
    type: t3.medium                         # <== a step above t2.micro for more beefy server needs
    #type: c6a.4xlarge                       # <== a mega machine for benchmarking
    storage: 30                             # <== EBS size for launch
    security-group:
        name: MySG
        rules:
            - inbound:
                port: 22
                cidr: 0.0.0.0/0
            - inbound:
                port: 80
                cidr: 0.0.0.0/0
            - inbound:
                port: 443
                cidr: 0.0.0.0/0
            - inbound:
                port: 8080
                cidr: 0.0.0.0/0
            - inbound:
                port: 8888
                cidr: 0.0.0.0/0
```

### _PLEASE REVIEW SECURITY GROUP RULES AND ADAPT TO YOUR NEEDS - SPECIFICALLY REMOVE THE PORT:22 RULE UNLESS YOU WANT ALL IPS TO HAVE ACCESS_

## Setup

```setup``` deploys docker, docker-compose, raku and zef to the launchee...

- cat .raws-config/launch.pl

```
#!/usr/bin/perl
`sudo apt update -y`;
`sudo apt upgrade -y`;
`sudo apt install tree -y`;

#`sudo apt install rakudo -y`;
`curl https://rakubrew.org/install-on-perl.sh | sh`;
`eval "$(/home/ubuntu/.rakubrew/bin/rakubrew init Bash)"`;
`echo 'eval "$(/home/ubuntu/.rakubrew/bin/rakubrew init Bash)"' >> ~/.bashrc`;
`export PATH=/home/ubuntu/.rakubrew/bin/:$PATH`;
`rakubrew mode shim`;
`rakubrew download`;

`sudo apt install docker-compose -y`;

`sudo apt install libssl-dev -y`;
`sudo apt install build-essential -y`;
`sudo apt install libmime-base64-urlsafe-perl`;
`zef install MIME::Base64 YAMLish JSON::Fast --/test --verbose`;
```

## NOTES

- unassigned Elastic IPs are chargeable ($5 per month ish), may be better to run one free tier instance
- rules about rules
  - will always open port 22 (SSH) inbound from this client IP
  - will re-use the existing named Security Group (or create if not present)
  - only inbound are supported for now 
  -  if you want to keep the name and change the rules, then delete via the aws console

### Copyright
copyright(c) 2022-2023 Henley Cloud Consulting Ltd.
