use JSON::Fast;
# uses $HOME/.aws/credentials

my $et = time;    # for unique names

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
