package Cloud::Helper::RestfulApi;
use Cloud::Service::Random;
use Mojo::UserAgent;
use Net::AMQP::RabbitMQ;
use Mojo::JSON qw(encode_json);

sub new {
  my ($class, $app) = @_;
  my $self = {
    app => $app
  };
  bless $self, $class;
  return $self;
}

sub captcha {
  my ($self, $randCode, $w, $h) = @_;

  my $ua = Mojo::UserAgent->new;
  my $result = $ua->get(
    'http://localhost:30000?code='. $randCode .'&w='. $w .'&h='. $h => {
      'Accept-Type' => 'image/png'
    }
  )->success;
  $image = 0;
  if ($result) {
    $image = $result->body;
  }
  return $image;
};

sub matchCaptcha {
  my ($self, $identify) = @_;
  my $captcha = $self->{app}->session->{'captcha'} || '';
  if ($captcha eq $identify) {
    return 1;
  }
  return 0;
}

sub sendmail {
  my ($self, $to, $subject, $content) = @_;
  my $sendBody = encode_json {
    to => $to,
    subject => $subject,
    content => $content
  };

  my $mq = Net::AMQP::RabbitMQ->new();
  $mq->connect("localhost", { user => "guest", password => "guest" });
  $mq->channel_open(1);
  $mq->queue_declare(1, "sendmail", {
    passive => 0,     #default 0
    durable => 0,     #default 0
    exclusive => 0,   #default 0
    auto_delete => 0, #default 1
  });
  $mq->publish(1, "sendmail", $sendBody);
  $mq->disconnect();
}


1;
