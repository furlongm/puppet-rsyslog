class rsyslog::server ($raw_log=undef, $enable_tcp=undef, $enable_udp=undef, $enable_relp=true) {

  include rsyslog
  include logrotate

  if $raw_log {

    file { '/etc/rsyslog.d/35-raw.conf':
      source  => 'puppet:///modules/rsyslog/35-raw.conf',
      notify  => Service['rsyslog'],
      require => File['/etc/rsyslog.d'],
    }

  } else {

  file { '/etc/rsyslog.d/35-raw.conf':
    ensure => absent,
    notify => Service['rsyslog'],
  }

  }
  file { '/etc/rsyslog.d/25-raw-format.conf':
    source  => 'puppet:///modules/rsyslog/25-raw-format.conf',
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  $admin_hosts = hiera('firewall::admin_hosts', [])

  file { '/etc/rsyslog.d/02-input-modules.conf':
    content => template("rsyslog/02-input-modules.conf.erb"),
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/51-server-rules.conf':
    source  => 'puppet:///modules/rsyslog/51-server-rules.conf',
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/75-input-server.conf':
    content => template('rsyslog/75-input-server.conf.erb'),
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/var/log/remote-syslogs':
    ensure  => directory,
    owner   => syslog,
    group   => adm,
    mode    => 0770,
    notify  => Service['rsyslog'],
  }

  logrotate::rule { 'remote-syslogs':
    ensure  => present,
    path    => '/var/log/remote-syslogs/*/*.log',
    options => [ 'rotate 52', 'weekly', 'missingok', 'notifempty', 'delaycompress', 'compress' ],
  }

  $infra_hosts = hiera('firewall::infra_hosts', [])

  if $enable_tcp {

    firewall::multisource {[ prefix($infra_hosts, '100 rsyslog-tcp,') ]:
      action => 'accept',
      proto  => 'tcp',
      dport  => 514,
    }
    nagios::service { 'rsyslog_tcp':
      check_command => "check_tcp!514";
    }
  }

  if $enable_udp {

    firewall::multisource {[ prefix($infra_hosts, '101 rsyslog-udp,') ]:
      action => 'accept',
      proto  => 'udp',
      dport  => 514,
    }
    file { '/usr/local/lib/nagios/plugins/check_udp_port':
      owner  => root,
      group  => root,
      mode   => '0755',
      source => 'puppet:///modules/rsyslog/check_udp_port',
    }
    nagios::nrpe::service { 'rsyslog_udp':
      check_command => '/usr/local/lib/nagios/plugins/check_udp_port 514';
    }
  }

  if $enable_relp {

    firewall::multisource {[ prefix($infra_hosts, '101 rsyslog-relp,') ]:
      action => 'accept',
      proto  => 'tcp',
      dport  => 20514,
    }
    nagios::service { 'rsyslog_relp':
      check_command => "check_tcp!20514";
    }
  }
}
