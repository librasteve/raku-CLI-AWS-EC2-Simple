class Build {
    method build($dist-path) {
        
        chdir $*HOME;
        mkdir '.raws-config';
        chdir '.raws-config';
        
my $text1 = q:to/END1/;
instance:
    nametag: amitest
    image: ami-044415bb13eee2391             # <== the standard, clean AWS Ubuntu 24.04LTS
    #image: ami-0e3457f66f5acc7a0            # <== AWS Ubuntu 24.04LTS plus raws-ec2 setup already applied (use --nsu flag)
    type: t2.micro                          # <== the basic, free tier eligible machine (12 credits/hr)
    #type: t3.small                          # <== $0.0209/hr viable static WP
    #type: t3.medium                         # <== a step above t2.micro for more beefy server needs
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
END1

        qqx`echo \'$text1\' > aws-ec2-launch.yaml`;
        
my $text2 = q:to/END2/;
#!/usr/bin/perl
`sudo apt-get update -y`;
`sudo apt-get upgrade -y`;
`sudo apt-get install tree -y`;

#`sudo apt install rakudo -y`;
`curl https://rakubrew.org/install-on-perl.sh | sh`;
`eval "$(/home/ubuntu/.rakubrew/bin/rakubrew init Bash)"`;
`echo 'eval "$(/home/ubuntu/.rakubrew/bin/rakubrew init Bash)"' >> ~/.bashrc`;
`export PATH=/home/ubuntu/.rakubrew/bin/:$PATH`;
`rakubrew mode shim`;
`rakubrew download`;

`sudo apt-get install docker-compose -y`;

`sudo apt-get install libssl-dev -y`;
`sudo apt-get install build-essential -y`;
`sudo apt-get install libmime-base64-urlsafe-perl`;
`zef install MIME::Base64 YAMLish JSON::Fast --/test --verbose`;
END2

        qqx`echo \'$text2\' > setup.pl`;
        
        warn 'Build successful';
        
        exit 0
    }
}
