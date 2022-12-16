[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

### THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOOUT NOTICE
### PLEASE EXERCISE CAUTION USING AWSCLI SINCE IT WILL CREATE BILLABLE AWS SERVICES IN YOUR ACCOUNT AND MAY NOT TERMINATE THEM AUTOMATICALLY

# Simple AWS Session & Launch Control

## Getting Started [FIXME]

- apt-get update && apt-get install aws-cli
- aws configure _[enter your config here]_
- cd raku-WP/various
- raku aws2.raku
- ssh -i "MyKeyPair.pem" ubuntu@ec2-13-41-185-87.eu-west-2.compute.amazonaws.com  <= use the public dns 

# Wordpress Deploy & Control

viz. [digital ocean howto](https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose#step-3-defining-services-with-docker-compose)

- client script 'raku-wp --launch'
- read client yml config file
- read .env credentials
- launch AWS EC2 instance
- install / use perl AWS CLI tools

# TODOs

- [x] new (launch based on yaml)
- [x] eip associate (auto allocates)
- [x] list (list all instances)
- [ ] nuke (terminate all instances)
- [ ] eip drop (eip release)
- [x] state
- [ ] stop
- [ ] start
- [ ] reboot
- [x] terminate
- [ ] yaml (ie. return yaml with id, etc.)
- [ ] freeze / thaw

# NOTES

- unassigned Elastic IPs are chargeable ($5 per month ish), may be better to run one free tier instance

### Copyright
copyright(c) 2022 Henley Cloud Consulting Ltd.
