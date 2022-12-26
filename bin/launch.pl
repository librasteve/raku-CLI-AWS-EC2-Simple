#!/usr/bin/perl

#viz. https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

### git clone

`git clone https://github.com/p6steve/raku-CLI-AWS-EC2-Simple.git';

### repo

`sudo apt-get update`;

`sudo apt-get install ca-certificates curl gnupg lsb-release`;
    
`sudo mkdir -p /etc/apt/keyrings`;
`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg`;

`echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" 
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`;
  
### engine
  
`sudo apt-get update`;
`sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y`;
#`sudo service docker start`;
#`sudo docker run hello-world`;

#viz. https://docs.docker.com/compose/install/linux/#install-using-the-repository

### compose

`sudo apt-get update`;
`sudo apt-get install docker-compose-plugin`;
`docker compose version`;


### start
#`cd raku-CLI-AWS-EC2-Simple`;
#`docker compose up`;

### stop
#`docker compose down`;
