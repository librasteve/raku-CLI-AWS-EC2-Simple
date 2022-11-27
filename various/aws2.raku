use JSON::Fast;
#needs $HOME/.aws/credentials

my $et = time;    #for unique names

class VPC {
    has $.id;

    submethod TWEAK {
        qqx`aws ec2 describe-vpcs --filters Name=is-default,Values=true` andthen
        $!id := .&from-json<Vpcs>[0]<VpcId> 
    }
}

class KeyPair {
    has $.name = "MyKeyPair$et";
    has $.file = 'MyKeyPair.pem';

    submethod TWEAK {
        qqx`aws ec2 create-key-pair --key-name $!name --query 'KeyMaterial' --output text > $!file`;
        qqx`chmod 400 $!file`;

    }
}

class SecurityGroup {
    has $.sg-id;
}

class Instance {
    has $.instance-id;
    has $.image-id = 'ami-0f540e9f488cfa27d';   #x86 for now
    has $.instance-type = 't2.micro';
    has $.public-dns-name;
    has $.public-ip-address;

}

class Session {
    has $.vpc;
    has $.key-pair;
    has $.sg;
    has $.client-ip;
}

my $vpc = VPC.new andthen say .id;
my $key-pair = KeyPair.new andthen say .name;
die;

#make key pair
my $key-name = "MyKeyPair$et";
qqx`aws ec2 create-key-pair --key-name $key-name --query 'KeyMaterial' --output text > MyKeyPair.pem`;
qqx`chmod 400 MyKeyPair.pem`;
#`[
#create-security-group
qqx`aws ec2 create-security-group --group-name my-sg$et --description "My security group" --vpc-id $vpc-id` andthen
say my $sg-id = .&from-json<GroupId>;

qqx`curl https://checkip.amazonaws.com` andthen
say my $client-ip = .chomp;
my $client-cidr = "$client-ip/0";

qqx`aws ec2 authorize-security-group-ingress --group-id $sg-id --protocol tcp --port 22 --cidr $client-cidr`;
qqx`aws ec2 describe-security-groups --group-ids $sg-id` andthen
say .&from-json;

my $image-id = 'ami-0f540e9f488cfa27d';
my $instance-type = 't2.micro';
qqx`aws ec2 run-instances --image-id $image-id --count 1 --instance-type $instance-type --key-name $key-name --security-group-ids $sg-id` andthen
say my $instance-id = .&from-json<Instances>[0]<InstanceId>;

qqx`aws ec2 describe-instances --instance-ids $instance-id` andthen
say my $describe-instances = .&from-json;

say my $public-dns-name   = $describe-instances<Reservations>[0]<Instances>[0]<PublicDnsName>;
say my $public-ip-address = $describe-instances<Reservations>[0]<Instances>[0]<PublicIpAddress>;

sleep(5);
say qq`ssh -o "StrictHostKeyChecking no" -i "MyKeyPair.pem" ubuntu@$public-dns-name`; 
#]
