package Cloud::Service::Random;

# sub new {
#   my $class = shift;
#   $self = {};
#   bless $self, $class;
#   return $self;
# }

sub randstr {
  my ($self, $len) = @_;
  my @W = ('0' .. '9', 'A' .. 'Z');
  my $str;
  my $i = 0;
  while ($i++ < $len) {
    $str .= $W[rand(@W)];
  }
  return $str;
}

1;
