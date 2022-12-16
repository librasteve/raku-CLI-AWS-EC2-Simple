use YAMLish;
use JSON::Fast;
# first go `aws configure` to populate $HOME/.aws/credentials

my $et = time;    # for unique names

class Config {
    has $.image;
    has $.type;

    method TWEAK {
        my %y := load-yaml('../.racl-config/aws-ec2-launch.yaml'.IO.slurp);
        $!image := %y<instance><image>;
        $!type  := %y<instance><type>;
    }
}

class Session {
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

    class Address {
        has $.ip;
        has $.eipalloc;

        method allocate {
            qqx`aws ec2 allocate-address`
            andthen
                my $r = .&from-json; 

            $!ip := $r<PublicIp>;
            $!eipalloc := $r<AllocationId>;
        }

        method associate( :$id ) {
            qqx`aws ec2 associate-address --instance-id $id --allocation-id $!eipalloc`
        }

        method TWEAK {
            qqx`aws ec2 describe-addresses`
            andthen
                my $a := .&from-json<Addresses>[0]; 

            if $!ip := $a<PublicIp> {
                $!eipalloc := $a<AllocationId>;
            } else {
                self.allocate;
            }
        }
    }
    
    class SecurityGroup {
        has $.name = 'MySG';
        has $.id;
        has $.vpc-id;

        method ids {
            qqx`aws ec2 describe-security-groups`
            andthen
                .&from-json<SecurityGroups>
            andthen
                .map({$_<GroupName> => $_<GroupId>})
        }

        method client-ip {
            qqx`curl -s https://checkip.amazonaws.com`
            andthen .chomp
        }

        method cidr {
            "$.client-ip/32"
        }

        method create-security-group {
            ##die $.cidr;
            qqx`aws ec2 create-security-group --group-name $!name --description $!name --vpc-id {$!vpc-id}`
            andthen
                $!id = .&from-json<GroupId>;

            # set rules (remember to delete MySG if these change)
            qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp --port 22  --cidr $.cidr`;
            qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp --port 80  --cidr 0.0.0.0/0`;
            qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp --port 443 --cidr 0.0.0.0/0`;
        }

        method TWEAK {
            my %h = self.ids;

            if %h{$!name} {
                $!id = $^i
            } else {
                self.create-security-group
            }
        }
    }

    has $.kpn = KeyPair.new.name;
    has $.vpc-id = VPC.new.id;
    has $.eip = Address.new;
    has $.sg;

    method TWEAK {
        $!sg = SecurityGroup.new(:$!vpc-id)
    }

    method instance-ids {
        qqx`aws ec2 describe-instances`
        andthen 
            .&from-json<Reservations>[0]<Instances>.map(*<InstanceId>);
    }
}

class Instance {
    has $.id;
    has $.c = Config.new;
    has $.s = Session.new;

    method TWEAK {
        say 'launching...';

        my $cmd :=
            "aws ec2 run-instances " ~
            "--image-id {$!c.image} " ~
            "--instance-type {$!c.type} " ~
            "--key-name {$!s.kpn} " ~
            "--security-group-ids {$!s.sg.id}";
            
        qqx`$cmd` andthen
            $!id = .&from-json<Instances>[0]<InstanceId>;
    }

    method describe {
        qqx`aws ec2 describe-instances --instance-ids $!id`
        andthen 
            .&from-json<Reservations>[0]<Instances>[0]
    }

    method public-dns-name {
        self.describe<PublicDnsName>
    }

    method public-ip-address {
        self.describe<PublicIpAddress>
    }

    method state {
        self.describe<State><Name>
    }

    method wait-until-running {
        until self.state eq 'running' { 
            say self.state, '...'; 
            sleep 5 
        }
        say self.state, '...';
    }

    method eip-associate {
        self.wait-until-running;
        $!s.eip.associate( :$!id );     # always associate Elastic IP
    }

    method connect {
        my $dns = self.public-dns-name;
        qq`ssh -o "StrictHostKeyChecking no" -i "{$!s.kpn}.pem" ubuntu@$dns`
    }

    method terminate {
        say 'terminating...';
        qqx`aws ec2 terminate-instances --instance-ids $!id`
    }
}

## for cmds list & nuke
#my $s = Session.new;
#$s.instance-ids;

my $i = Instance.new;
$i.eip-associate;

$i.connect.say;
$i.public-ip-address.say;

#$i.terminate;
say $i.state;

