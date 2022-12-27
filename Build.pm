class Build {
    method build($dist-path) {
        
        chdir $*HOME;
        mkdir '.racl-config';
        chdir '.racl-config';
        
my $text = q:to/END/;
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
        qqx`echo \'$text\' > aws-ec2-launch.yaml`;
        
        warn 'Build successful';
        
        exit 0
    }
}
