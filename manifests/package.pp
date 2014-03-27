class rsyslog::package {

  package { ['rsyslog', 'rsyslog-relp']:
    ensure => present,
  }
}
