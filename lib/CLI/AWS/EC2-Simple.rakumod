unit module CLI::AWS::EC2-Simple:ver<0.0.9>:auth<Steve Roe (librasteve@furnival.net)>;

use YAMLish;
use JSON::Fast;
# first go `aws configure` to populate $HOME/.aws/credentials

my $et = time;      # for unique names

my %config-yaml := load-yaml("$*HOME/.raws-config/aws-ec2-launch.yaml".IO.slurp);   # only once
my $setup-text := "$*HOME/.raws-config/setup.pl".IO.slurp;

class Config is export {
    has %.y; 
    has $.image;
    has $.type;
    has $.storage;
    has $.sg-name = 'MySG';
    has @.sg-rules;

    method TWEAK {
        %!y        := %config-yaml; 
        $!image    := %!y<instance><image>;
        $!type     := %!y<instance><type>;
        $!storage  := %!y<instance><storage>;
        $!sg-name  := %!y<instance><security-group><name>;
        @!sg-rules := %!y<instance><security-group><rules>;
    }
}

class Image {
    has $.c;

    method describe {
        qqx`aws ec2 describe-images --image-id {$!c.image}` 
        andthen
            .&from-json<Images>[0]
    }

    method block-device-mapping {
        self.describe<BlockDeviceMappings>[0]
    }

    method device-name {
        self.describe<BlockDeviceMappings>[0]<DeviceName>
    }
}

class KeyPair {
    has $.dir = "$*HOME";
    has $.name;

    method names-from-aws {
        qqx`aws ec2 describe-key-pairs`
        andthen
            .&from-json<KeyPairs>.map: *<KeyName>
    }

    method names-from-dir {
        chdir($!dir);
        dir.grep(/pem/).map({S/.pem//})
    }

    method create-key-pair {
        say 'creating kp...';
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

class ElasticIP {
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
    has $.id;
    has Config $.c;
    has $.vpc-id;

    method names2ids {
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

    method apply-rules {
        # set rules (remember to delete MySG if these change)
        # will always open port 22 (SSH) inbound from this client IP
        qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp --port 22  --cidr $.cidr`;

        for $!c.sg-rules.map(*<inbound>) -> $ib {
            my $port = "--port {$ib<port>}";
            my $cidr = "--cidr {$ib<cidr>}";

            qqx`aws ec2 authorize-security-group-ingress --group-id $!id --protocol tcp $port $cidr`;
        }

        # outbound not implemented
    }

    method create {
        say 'creating sg...';

        qqx`aws ec2 create-security-group --group-name {$!c.sg-name} --description {$!c.sg-name} --vpc-id {$!vpc-id}`
        andthen
            $!id = .&from-json<GroupId>;

        self.apply-rules
    }

    method TWEAK {
        my %h = self.names2ids;

        if %h{$!c.sg-name} {
            $!id = $^i
        } else {
            self.create
        }
    }
}

class Session is export {
    has $.c = Config.new;
    has $.kpn = KeyPair.new.name;
    has $.vpc-id = VPC.new.id;
    has $.eip = ElasticIP.new;
    has $.sg;
    has $.q;

    method TWEAK {
        $!sg = SecurityGroup.new(:$!vpc-id, :$!c)
    }

    method instance-ids {
        qx`aws ec2 describe-instances --query "Reservations[*].Instances[*].{Instance:InstanceId}"`
        andthen 
            .&from-json.map(*.first).map(*<Instance>);
    }

    method instance-kps {
        qx`aws ec2 describe-instances --query "Reservations[*].Instances[*].{KeyName:KeyName}"`
        andthen 
            .&from-json.map(*.first).map(*<KeyName>);
    }
}

class Instance is export {
    has $.id;
    has $.vol-id;
    has $.c = Config.new;
    has $.i = Image.new( :$!c );
    has $.s = Session.new;

    method launch {
        say 'launching...';

        my $cmd =
            "aws ec2 run-instances " ~
            "--image-id {$!c.image} " ~
            "--instance-type {$!c.type} " ~
            "--key-name {$!s.kpn} " ~
            "--security-group-ids {$!s.sg.id}";

        # viz. https://stackoverflow.com/questions/53369224/how-to-launch-ec2-instance-with-custom-root-volume-ebs-size-more-than-8gb-usin
        my $den = 'DeviceName=' ~ $!i.device-name; 
        my $ebs = 'Ebs={VolumeSize=' ~ $!c.storage ~ '}'; 
        $cmd ~= " --block-device-mapping $den,$ebs" if $!c.storage;

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

    method availability-zone {
        self.describe<Placement><AvailabilityZone>
    }

    method state {
        self.describe<State><Name>
    }

    method nametag {
        self.describe<Tags>[0]<Value> // '-'
    }

    method wait-until-running {
        until self.state eq 'running' { 
            say self.state, '...' unless $!s.q; 
            sleep 5 
        }
        say self.state, '...' unless $!s.q;
    }

    method eip-associate {
        self.wait-until-running;
        
        say 'associating eip...'; 
        $!s.eip.associate( :$!id );     # always associate Elastic IP
    }

    method connect {
        self.wait-until-running;
        
        my $dns = self.public-dns-name;
        qq`ssh -o "StrictHostKeyChecking no" -i "{$!s.kpn}.pem" ubuntu@$dns`
    }

    method terminate {
        say 'terminating...';
        qqx`aws ec2 terminate-instances --instance-ids $!id`
    }
    
    method stop {
        say 'stopping...';
        qqx`aws ec2 stop-instances --instance-ids $!id`
    }
    
    method start {
        say 'starting...';
        qqx`aws ec2 start-instances --instance-ids $!id`
    }  

    method setup {
        say "setting up, this can take some minutes (longer if on a t2.micro) please be patient...";
        self.wait-until-running;
        sleep 20;       # let instance mellow

        my $dns = self.public-dns-name;

        # since we are changing the host, but keeping the eip, we flush known_hosts
        qqx`ssh-keygen -f ~/.ssh/known_hosts -R $dns`;

        my $proc = Proc::Async.new(:w, 'ssh', '-tt', '-o', "StrictHostKeyChecking no", '-i', "{$!s.kpn}.pem", "ubuntu@$dns");
        $proc.stdout.tap({ print "stdout: $^s" });
        $proc.stderr.tap({ print "stderr: $^s" });

        my $promise = $proc.start;

        $proc.say("echo 'Hello, World'");
        $proc.say("id");

        $proc.say('export PATH=$PATH:/usr/lib/perl6/site/bin:/home/ubuntu/.raku/bin');
        $proc.say('echo PATH=$PATH:/usr/lib/perl6/site/bin:/home/ubuntu/.raku/bin >> ~/.bashrc');

        $proc.say("echo \'$setup-text\' > setup.pl");
        $proc.say('cat setup.pl | perl');

        sleep 5;

        $proc.say("exit");
        await $promise;
        say "done!";
    }
}


