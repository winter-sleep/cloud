package Cloud::Controller::Basic;
use strict;
use warnings;

my @EXPORT qw(result);

sub result {
  my ($self, $that, $code, $body) = @_;
  $that->res->code($code);
  return $that->render(json => $body);
}

1;