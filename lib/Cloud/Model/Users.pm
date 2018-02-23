package Cloud::Model::Users;
use Cloud::Model::Basic;

use strict;
use warnings;
use Mojo::Util qw(sha1_sum);

BEGIN {
  use vars qw(@ISA);
  @ISA = qw(Cloud::Model::Basic);
}

sub new {
  my $class = shift;
  my $self = Cloud::Model::Basic->new;
  bless $self, $class;
  return $self;
}

sub create {
  my ($self, $nickname, $email, $password, $gender) = @_;
  my $db = $self->getDbi();
  my $result = $db->do(
    "INSERT INTO
        `users` (`nickname`, `email`, `password`, `gender`)
    VALUES
        (?,?,?,?)",
    undef,
    $nickname,
    $email,
    $self->makePasswordHash($password),
    $gender
  );
  if ($result == 0) {
    $db->disconnect();
    return 0;
  }
  my $lastId = $db->last_insert_id(undef, 'fragment', 'users', undef);
  $db->disconnect();
  return $lastId;
}

sub hasEmail {
  my ($self, $email) = @_;
  my $db = $self->getDbi();
  my $sth = $db->prepare(
    "SELECT 1 AS number FROM `users` WHERE `email` = ?"
  );
  $sth->execute($email);
  my $result = ($sth->rows > 0) ? 1 : 0;
  $sth->finish();
  $db->disconnect();
  return $result;
}

sub matchPassword {
  my ($self, $email, $password) = @_;
  my $db = $self->getDbi();
  my $sth = $db->prepare(
    'SELECT
      `id`, `nickname`, `email`, `gender`, `master`, `active`
    FROM
      `users` WHERE `email` = ? AND `password` = ? AND `active` = 1'
  );
  my $passwordHash = $self->makePasswordHash($password);
  $sth->execute($email, $passwordHash);
  if ($sth->rows == 0) {
    $sth->finish();
    $db->disconnect();
    return 0;
  }
  my $data = $sth->fetchrow_hashref();
  $sth->finish();
  $db->disconnect();
  return $data;
}

sub makePasswordHash {
    my ($self, $password) = @_;
    return sha1_sum $password;
}

sub activeNomal {
  my ($self, $id, $email) = @_;
  my $db = $self->getDbi();
  my $result = $db->do(
    "UPDATE `users` SET `active`=1 WHERE `id`=? AND `email`=?",
    undef, $id, $email
  );
  $db->disconnect();
  return $result eq "0E0" ? 0 : 1;
}

sub isActived {
  my ($self, $email) = @_;
  my $db = $self->getDbi();
  my $sth = $db->prepare(
    "SELECT 1 AS number FROM `users` WHERE `email` = ? AND `active` = 1"
  );
  $sth->execute($email);
  my $result = ($sth->rows > 0) ? 1 : 0;
  $sth->finish();
  $db->disconnect();
  return $result;
}

1;
