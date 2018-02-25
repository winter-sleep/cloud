package Cloud::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
use Cloud::Model::Users;
use Cloud::Service::Users;
use Cloud::Service::Random;
use Mojo::UserAgent;
use Encode;
use utf8;


my $usersModel = Cloud::Model::Users->new;
my $userService = Cloud::Service::Users->new;

# 新建用户 (signup)
sub create {
  my $self = shift;
  my $request = $self->req->json;

  my $nickname = $request->{'nickname'} || '';
  my $email = $request->{'email'} || '';
  my $password = $request->{'password'} || '';
  my $repassword = $request->{'repassword'} || '';
  my $gender = $request->{'gender'};
  my $identify = $request->{'identify'} || '';

  my $invCode = 409;

  # 逐一检查输入参数格式，并返回错误
  if (
    $userService->nicknameIsInvalid($nickname) ||
    $userService->emailIsInvalid($email) ||
    $userService->passwordIsInvalid($password) ||
    $userService->repasswordIsInvalid($password, $repassword) ||
    $userService->genderIsInvalid($gender) ||
    $userService->captchaIsInvalid($identify)
  ) {
    return $self->render(json => {
      step => $userService->getStepOfSignupPage,
      mess => $userService->getMessage
    }, status => $invCode);
  }

  if (!($self->session->{captcha} eq $identify)) {
    delete $self->session->{captcha};
    return $self->render(json => {
      step => 3, mess => '验证码错误~'
    }, status => $invCode);
  }

  if (!$usersModel->hasEmail($email)) {
    if (my $id = $usersModel->create($nickname, $email, $password, $gender)) {
      my $token = $userService->encode_jwt({
        'id' => $id, 'email' => $email
      });
      # 发送激活邮件模板
      my $output = $self->render_to_string('mail/active', token => $token);
      $self->api->sendmail($email, '欢迎入住 Fragment.top!', $output);
      return $self->render(json => {
        step => 3, mess => 'Created'
      }, status => 201);
    }
    return $self->render(json => {step => 3, mess => '抱歉，您的信息保存失败了~'}, status => 503);
  }
  return $self->render(json => {
    step => 1, mess => '抱歉，您输入的电子邮件已经存在了～'
  }, status => $invCode);
}

# 检测 email 是否已存在(200/404)
sub emailExist {
  my $self = shift;
  my $email = $self->param('email') || '';
  if ($userService->emailIsInvalid($email)) {
    return $self->render(json => {mess => $userService->getMessage}, status => 404);
  }
  if ($usersModel->hasEmail($email)) {
    return $self->render(json => {mess => 'email is exist'}, status => 200);
  }
  return $self->render(json => {mess => $email}, status => 404);
}

# 用户登录 (signin)
sub signin {
  my $self = shift;
  my $request = $self->req->json;

  my $email = $request->{'email'} || '';
  my $password = $request->{'password'} || '';

  my $invCode = 409;
  if (
    $userService->emailIsInvalid($email) ||
    $userService->passwordIsInvalid($password)
  ) {
    return $self->render(json => {
      mess => $userService->getMessage
    }, status => $invCode);
  }
  if (!$usersModel->hasEmail($email)) {
    return $self->render(json => {
      mess => 'email 尚未注册~'
    }, status => $invCode);
  }
  if (!$usersModel->isActived($email)) {
    return $self->render(json => {
      mess => '账户尚未激活，请前往邮箱查收激活邮件，点击确认后可以重新发送激活邮件～'
    }, status => 403);
  }
  my $result = $usersModel->matchPassword($email, $password);
  if (!$result) {
    return $self->render(json => {
      mess => '用户名或密码错误~'
    }, status => $invCode);
  }

  my $jwtToken = $userService->encode_jwt($result);
  my $userImage = $userService->userImage($result->{'id'});
  $self->cookie(
    token => $jwtToken,
    { domain => ".fragment.top", path => '/' }
  );
  $self->cookie(
    userImage => $userImage,
    { domain => ".fragment.top", path => '/' }
  );

  return $self->render(json => {
    mess => 'success'
  }, status => 200);
}

# 激活账户，赋予账户写入权限
sub active {
  my $self = shift;
  my $token = $self->param('token') || '';
  my $resultMessage = '您提供的账户信息不正确，您可以重新获取激活邮件并再次尝试～';
  my $resultCode = 409;
  if (!($token eq '')) {
    my $info = $userService->decode_jwt($token);
    if ((exists $info->{email}) && (exists $info->{id})) {
      if ($usersModel->activeNomal($info->{id}, $info->{email})) {
        $resultMessage = 'success';
        $resultCode = 200;
      }
    }
  }
  return $self->render(json => {
    mess => $resultMessage
  }, status => $resultCode);
}

# 获取验证码图片，设置验证码 session
sub captcha {
  my $self = shift;
  my $randCode = Cloud::Service::Random->randstr(6);
  my $image = $self->api->captcha($randCode, 130, 42);
  if (!$image) {
    return $self->render(text => '', status => 520);
  }
  $self->session->{captcha} = $randCode;
  return $self->render(data => $image, format => 'png', status => 200);
}

sub signout {
  my $self = shift;
  my $delOption = {
    max_age => -1,
    expires => time -1,
    domain => ".fragment.top",
    path => '/'
  };
  # cookie
  $self->cookie(token => '', $delOption);
  $self->cookie(userImage => '', $delOption);
  # session
  if (exists $self->session->{captcha}) {
    delete $self->session->{captcha};
  }
  return $self->render(text => '', status => 200);
}

# 测试
sub test {
  my $self = shift;
  # my $captcha = $self->session->{captcha} || '';
  my $output = $self->render_to_string('mail/active', token => 'world');
  $self->render(text => $output);
}


1;
