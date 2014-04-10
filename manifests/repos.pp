class rsyslog::repos {

  apt::ppa { 'ppa:adiscon/v7-stable':
    release => "${::lsbdistcodename}",
  }

  apt::pin { 'rsyslog':
    packages => 'rsyslog rsyslog-relp libestr0 librelp0 libgt0 liblogging-stdlog1',
    origin   => 'ppa.launchpad.net',
    priority => 2200,
  }
}
