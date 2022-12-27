#!/usr/bin/perl

`git clone https://github.com/p6steve/raku-CLI-AWS-EC2-Simple.git`;

`sudo apt-get update -y`;

`sudo apt-get install rakudo -y`;
`sudo git clone https://github.com/ugexe/zef.git`;
`sleep 5`;
`sudo raku -I./zef zef/bin/zef install ./zef --/text`;
`sudo env PATH=$PATH:/usr/lib/perl6/site/bin`;


`sudo apt-get install docker -y`;
`sudo apt-get install docker-compose -y`;

`sudo docker-compose version`;
