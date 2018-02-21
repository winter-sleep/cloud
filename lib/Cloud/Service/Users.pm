package Cloud::Service::Users;

use Mojo::JWT;
use strict;
use warnings;
use Encode;
use utf8;


my $storage = 0;

sub new {
  if ($storage == 0) {
    my $class = shift;
    my $self = {
      _message => '',
      _step => 1
    };
    bless $self, $class;
    $storage = $self;
  }
  return $storage;
}

sub getMessage {
  my $self = shift;
  return $self->{_message};
}

sub getStepOfSignupPage {
  my $self = shift;
  return $self->{_step};
}

sub nicknameIsInvalid {
  my ($self, $nickname) = @_;
  my $nickSwap = Encode::decode 'utf8', $nickname;
  my $len = length $nickSwap;
  if ($len == 0 || $len > 16) {
    $self->{_message} = '您的名字不能为空，且不能超过16个字符~';
    $self->{_step} = 1;
    return 1;
  }
  return 0;
}

sub emailIsInvalid {
  my ($self, $email) = @_;
  if (!($email =~ /^([a-zA-Z0-9_-])+@([a-zA-Z0-9_-])+((\.[a-zA-Z0-9_-]{2,4}){1,2})$/)) {
    $self->{_message} = '电子邮件格式错误~';
    $self->{_step} = 1;
    return 1;
  }
  return 0;
}

sub passwordIsInvalid {
  my ($self, $password) = @_;
  if (!($password =~ /^[\d\w]{6,32}$/)) {
    $self->{_message} = '密码格式必须大于6位的英文、下划线或数字, 且不超过32位~';
    $self->{_step} = 2;
    return 1;
  }
  return 0;
}

sub repasswordIsInvalid {
  my ($self, $password, $repassword) = @_;
  if ($self->passwordIsInvalid($repassword)) { return 1; }
  if (!($password eq $repassword)) {
    $self->{_message} = '两次输入的密码不匹配~';
    $self->{_step} = 2;
    return 1;
  }
  return 0;
}

sub genderIsInvalid {
  my ($self, $gender) = @_;
  if (!($gender =~ /^[012]$/)) {
    $self->{_message} = '性别选择错误~';
    $self->{_step} = 3;
    return 1;
  }
  return 0;
}

sub captchaIsInvalid {
  my ($self, $captcha) = @_;
  if (!($captcha =~ /^[a-zA-Z0-9]{6}$/)) {
    $self->{_message} = '验证码错误~';
    $self->{_step} = 3;
    return 1;
  }
  return 0;
}

sub decode_jwt {
  my ($self, $token) = @_;
  my $tokenHash;
  eval {$tokenHash = Mojo::JWT->new->decode($token);};
  if ($@) {
    return {};
  }
  return $tokenHash
}

sub encode_jwt {
  my ($self, $claims) = @_;
  Mojo::JWT->new(claims =>$claims)->encode;
}

sub userImage {
  my ($self, $id) = @_;
  my $image = "userimage/$id/32x32.jpg";
  if (-e $image) {
    return "/static/$image";
  }
  return "/static/userimage/default-user/32x32.png";
}


1;
