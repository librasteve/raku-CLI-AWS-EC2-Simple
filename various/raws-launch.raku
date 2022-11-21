use Paws:from<Perl5>;
use Paws::Credential::File:from<Perl5>;

# will open $HOME/.aws/credentials
my $paws = Paws.new(config => {
  credentials => Paws::Credential::File.new(
    file_name => 'credentials',
  ),
  region => 'eu-west-2',
  output => 'json',
});

my $ec2 = $paws.service('EC2');

dd $ec2; 

my $result = $ec2.DescribeAddresses.Addresses;
dd $result;

#`[
$result = $ec2->DescribeInstances;
p $result;

$result = $ec2->DescribeAvailabilityZones;
p $result;

$result = $ec2->DescribeRegions;
p $result;

$result = $ec2->DescribeSnapshots;
p $result;
#p $_ for @{ $result->Snapshots };

$result = $ec2->DescribeImages(Owners => [ 'self' ]);
p $result;
#]

