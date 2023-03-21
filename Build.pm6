class Build {
    method build($dist-path) {
        
        chdir $*HOME;
        mkdir '.raws-config';
        chdir '.raws-config';
        
my $text1 = q:to/END1/;
instance:
    image: ami-0f540e9f488cfa27d            # <== the standard, clean AWS Ubuntu
    #image: ami-0ebdbe39cf24185c1            # <== AWS Ubuntu plus raws-ec2 setup already applied (use --nsu flag)
    type: t2.micro                          # <== the basic, free tier eligible test machine
    #type: c6a.4xlarge                       # <== my choice of reasonably priced server class machine
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
END1

        qqx`echo \'$text1\' > aws-ec2-launch.yaml`;
        
my $text2 = q:to/END2/;
#!/usr/bin/perl
`sudo apt-get update -y`;

`sudo apt-get install rakudo -y`;
`sudo git clone https://github.com/ugexe/zef.git`;
`sudo raku -I./zef zef/bin/zef install ./zef --/test`;

`sudo apt-get install docker -y`;
`sudo apt-get install docker-compose -y`;

`sudo apt-get install libmime-base64-urlsafe-perl`;
`zef install MIME::Base64 YAMLish JSON::Fast --/test --verbose`;
END2

        qqx`echo \'$text2\' > setup.pl`;
        
        warn 'Build successful';
        
        exit 0
    }
}
