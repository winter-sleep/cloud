package Cloud::Model::Basic;

use DBI;
use strict;
use warnings;

our $db = DBI->connect(
  "DBI:mysql:database=fragment;host=localhost",
  "root", "blldxt",
  {
    'RaiseError' => 1,
    mysql_auto_reconnect => 1,
    mysql_enable_utf8mb4 => 1
  }
);

sub new {
  my $class = shift;
  my $self = {
    _db => $db
  };
  bless $self, $class;
  return $self;
}

sub getDbi {
  my $self = shift;
  return $self->{_db};
}


1;
