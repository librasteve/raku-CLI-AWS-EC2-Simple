class Build {
    method build($dist-path) {
        
        chdir $*HOME;
        mkdir '.racl-config';
        chdir '.racl-config';
        
my $text1 = q:to/END/;
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
END

        qqx`echo \'$text1\' > aws-ec2-launch.yaml`;
        
my $text = q:to/END/;
#!/usr/bin/perl
`sudo apt-get update -y`;

`sudo apt-get install rakudo -y`;
`sudo git clone https://github.com/ugexe/zef.git`;
`sudo raku -I./zef zef/bin/zef install ./zef --/test`;

`sudo apt-get install docker -y`;
`sudo apt-get install docker-compose -y`;
END

        qqx`echo \'$text2\' > setup.pl`;
        
        warn 'Build successful';
        
        exit 0
    }
}
