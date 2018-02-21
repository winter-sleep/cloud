package Cloud;
use Mojo::Base 'Mojolicious';
use Cloud::Helper::RestfulApi;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  $self->helper(api => sub {
    return Cloud::Helper::RestfulApi->new($self);
  });

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->post('/api/user')->to('user#create');  # 创建用户
  $r->get('/api/user/emailExist')->to('user#emailExist');  # 判断 email 是否存在
  $r->post('/api/user/signin')->to('user#signin');  # 用户登录接口
  $r->get('/api/user/captcha')->to('user#captcha');
  $r->get('/api/user/signout')->to('user#signout');
  $r->get('/api/user/active')->to('user#active');
  $r->get('/api/user/test')->to('user#test');

}


1;
