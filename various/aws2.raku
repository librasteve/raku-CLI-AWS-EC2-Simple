use JSON::Fast;
# uses $HOME/.aws/credentials

my $et = time;    # for unique names

#viz. https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose#step-3-defining-services-with-docker-compose
my $yaml = q:to/END/;

version: '3'

services:
  db:
    image: mysql:8.0
    container_name: db
    restart: unless-stopped
    env_file: .env
    environment:
      - MYSQL_DATABASE=wordpress
    volumes:
      - dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network

  wordpress:
    depends_on: 
      - db
    image: wordpress:5.1.1-fpm-alpine
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=$MYSQL_USER
      - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - app-network

  webserver:
    depends_on:
      - wordpress
    image: nginx:1.15.12-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
    networks:
      - app-network
END

class KeyPair {
    has $.dir = '.';
    has $.name;

    method names-from-aws {
        qqx`aws ec2 describe-key-pairs`
        andthen
            .&from-json<KeyPairs>.map: *<KeyName>
    }

    method names-from-dir {
        dir($!dir).grep(/pem/).map({S/.pem//})
    }

    method create-key-pair {
        qqx`aws ec2 create-key-pair --key-name $!name --query 'KeyMaterial' --output text > $!name.pem`;
        qqx`chmod 400 $!name.pem`
    }

    method TWEAK {
        for self.names-from-dir -> $n {
            if $n ∈ self.names-from-aws.Set {   # is there a matching .pem file in dir 
                $!name := $n;
                last
            }
        }

        if ! $!name {                           # otherwise, make a new one
            $!name := "MyKeyPair$et";
            self.create-key-pair
        }
    }
}

class VPC {
    has $.id;

    method TWEAK {
        qqx`aws ec2 describe-vpcs --filters Name=is-default,Values=true`
        andthen
            $!id := .&from-json<Vpcs>[0]<VpcId> 
    }
}

class SecurityGroup {
    has $.name = 'MySG';
    has $.id;
    has $.vpc-id;
    has $.cidr;

    method ids-from-aws {
        qqx`aws ec2 describe-security-groups`
        andthen
            .&from-json<SecurityGroups>
        andthen
            .map({$_<GroupName> => $_<GroupId>})
    }

    method create-security-group {
        qqx`aws ec2 create-security-group --group-name $!name --description $!name --vpc-id {$!vpc-id}`
        andthen
            $!id = .&from-json<GroupId>;

        # set rules (remember to delete MySG if these change)
        qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp --port 22 --cidr $!cidr`;
    }

    method TWEAK {
        my %h = self.ids-from-aws;

        if %h{$!name} {
            $!id = $^i
        } else {
            self.create-security-group
        }
    }
}

class Session {
    has $.kpn = KeyPair.new.name;
    has $.vpc-id = VPC.new.id;
    has $.sg;

    method ip {
        qqx`curl -s https://checkip.amazonaws.com`
        andthen .chomp
    }

    method cidr {
        "$.ip/0"
    }

    method TWEAK {
        $!sg = SecurityGroup.new(:$!vpc-id, :$.cidr)
    }
}

class Instance {
    has $.id;
    has $.s = Session.new;
    has $.image = 'ami-0f540e9f488cfa27d';  # x86 for now
    has $.type  = 't2.micro';               # free tier

    method TWEAK {
        qqx`aws ec2 run-instances --image-id $!image --instance-type $!type --key-name {$!s.kpn} --security-group-ids {$!s.sg.id}` 
        andthen
            $!id = .&from-json<Instances>[0]<InstanceId>;
    }

    method describe {
        qqx`aws ec2 describe-instances --instance-ids $!id`
        andthen 
            .&from-json
    }

    method public-dns-name {
        self.describe<Reservations>[0]<Instances>[0]<PublicDnsName>
    }

    method public-ip-address {
        self.describe<Reservations>[0]<Instances>[0]<PublicIPAddress>
    }

    method connect {
        my $dns = self.public-dns-name;
        qq`ssh -o "StrictHostKeyChecking no" -i "{$!s.kpn}.pem" ubuntu@$dns`
    }
}

Instance.new.connect.say;
