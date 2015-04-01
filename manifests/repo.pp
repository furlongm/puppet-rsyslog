# Sets up repo for adiscon rsyslog
class rsyslog::repo(
  $major_version=7
) {

  apt::ppa { "ppa:adiscon/v${major_version}-stable":
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
    key         => '1362E120FE08D280780169DC894ECF17AEF0CF8E',
    key_options => $key_options,
  }
}
