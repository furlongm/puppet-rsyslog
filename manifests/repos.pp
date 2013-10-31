class rsyslog::repos {

  if $::rfc1918_gateway == 'true' {
    exec { 'rsyslog-apt-key':
     path        => '/usr/bin:/bin:/usr/sbin:/sbin',
     command     => "apt-key adv --keyserver pgp.mit.edu --keyserver-options http-proxy=\"${::http_proxy}\" --recv-keys AEF0CF8E",
     unless      => 'apt-key list | grep AEF0CF8E >/dev/null 2>&1',
    }

  } else {
    apt::key { 'rsyslog':
      key         => 'AEF0CF8E',
      key_server => 'pgp.mit.edu',
    }
  }

  apt::source { 'rsyslog':
    location     => 'http://ubuntu.adiscon.com/v7-stable',
    release      => 'precise/',
    repos        => ' ',
    key          => 'AEF0CF8E',
    pin          => '2200',
    include_src  => false,
  }
}
