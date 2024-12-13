class Build {
    method build($dist-path) {
        
        chdir $*HOME;
        mkdir '.raws-config';
        chdir '.raws-config';
        
my $text1 = q:to/END1/;
instance:
    nametag: amitest
    #image: ami-0e8d228ad90af673b            # <== the standard, clean AWS Ubuntu 24.04LTS
    image: ami-04bc7403c36ed1222            # <== AWS Ubuntu 24.04LTS plus raws-ec2 setup already applied (use --nsu flag)
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

`sudo apt-get install rakudo -y`;
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
