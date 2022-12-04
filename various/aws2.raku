use YAMLish;
use JSON::Fast;
# uses $HOME/.aws/credentials

## design
# xxx.yaml
#
# session start
#   new (launch based on yaml)
#   nuke (terminate all instances)
#   status (warn if > one running instance)
#   stop     ( " )
#   start    ( " )
#   reboot   ( " )
#   terminate( " )
#   yaml
#   freeze / thaw

#viz. https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-docker-compose#step-3-defining-services-with-docker-compose

my $et = time;    # for unique names

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

class Config {
    has $.image;
    has $.type;

    method TWEAK {
        my %y := load-yaml('../.racl-config/aws-ec2-launch.yaml'.IO.slurp);
        $!image := %y<instance><image>;
        $!type  := %y<instance><type>;
    }
}

class Instance {
    has $.id;
    has $.c = Config.new;
    has $.s = Session.new;

    method TWEAK {
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
