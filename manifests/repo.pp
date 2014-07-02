class rsyslog::repo {

  apt::ppa { 'ppa:adiscon/v7-stable':
    release => "${::lsbdistcodename}",
  }

  apt::pin { 'rsyslog':
    packages => 'rsyslog rsyslog-relp libestr0 librelp0 libgt0 liblogging-stdlog1',
    origin   => 'ppa.launchpad.net',
    priority => 2200,
  }

  if $::http_proxy and $::rfc1918_gateway == 'true' {
    $key_options = "http-proxy=${::http_proxy}"
  } else {
    $key_options = false
  }

  apt::key { 'adiscon':
    key         => 'AEF0CF8E',
    key_options => $key_options,
  }
}
