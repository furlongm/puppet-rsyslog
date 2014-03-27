class rsyslog (
  $manage_repo = false,
) {

  class { 'rsyslog::package': }

  validate_bool($manage_repo)
  if ($manage_repo == true) {
    # Set up repositories
    class { 'rsyslog::repo':
      stage => setup,
    }
  }

  File {
    owner   => root,
    group   => root,
    mode    => 0644,
  }

  service { 'rsyslog':
    ensure  => running,
    enable  => true,
    require => Class['rsyslog::package'],
  }

  file { '/etc/rsyslog.d':
    ensure  => directory,
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['rsyslog'],
    require => Class['rsyslog::package'],
  }

  file { '/etc/rsyslog.conf':
    source  => 'puppet:///modules/rsyslog/rsyslog.conf',
    notify  => Service['rsyslog'],
  }

  file { '/etc/rsyslog.d/01-default-input-modules.conf':
    source  => 'puppet:///modules/rsyslog/01-default-input-modules.conf',
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/10-global-directives.conf':
    source  => 'puppet:///modules/rsyslog/10-global-directives.conf',
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/50-default-rules.conf':
    content => template('rsyslog/50-default-rules.conf.erb'),
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  if defined(Package['postfix']) {
    file { '/etc/rsyslog.d/postfix.conf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => '0644',
      source  => 'puppet:///modules/rsyslog/postfix.conf',
      notify  => Service['rsyslog'],
    }
  }

  file { '/usr/local/lib/nagios/plugins/check_syslog_spool':
    mode   => '0755',
    source => 'puppet:///modules/rsyslog/check_syslog_spool',
  }

  nagios::nrpe::service { 'check_syslog_spool':
     check_command => '/usr/local/lib/nagios/plugins/check_syslog_spool';
  }
}
