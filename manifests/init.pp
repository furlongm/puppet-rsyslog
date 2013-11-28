class rsyslog {

  Package { ensure => present }

  $rsyslog_packages = ['rsyslog', 'rsyslog-relp']

  package { $rsyslog_packages: }

  service { 'rsyslog':
    ensure  => running,
    enable  => true,
    require => Package[$rsyslog_packages],
  }

  file { '/etc/rsyslog.d':
    ensure  => directory,
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['rsyslog'],
    require => Package['rsyslog'],
  }

  file { '/etc/rsyslog.conf':
    source  => 'puppet:///modules/rsyslog/rsyslog.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
  }

  file { '/etc/rsyslog.d/01-default-input-modules.conf':
    source  => 'puppet:///modules/rsyslog/01-default-input-modules.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/10-global-directives.conf':
    source  => 'puppet:///modules/rsyslog/10-global-directives.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/50-default-rules.conf':
    content => template('rsyslog/50-default-rules.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/usr/local/lib/nagios/plugins/check_syslog_spool':
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///modules/rsyslog/check_syslog_spool',
  }

  nagios::nrpe::service { 'check_syslog_spool':
     check_command => '/usr/local/lib/nagios/plugins/check_syslog_spool';
  }
}

class rsyslog::client($server, $transport='relp') inherits rsyslog {

  if (is_ip_address($server) and has_interface_with("ipaddress", $server)) or $::fqdn == $server {
    $is_server = true
  }

  if $is_server != true {

    file { '/etc/rsyslog.d/60-remote-server.conf':
      content => template("rsyslog/60-remote-server.conf.erb"),
      owner   => root,
      group   => root,
      mode    => 0644,
      notify  => Service['rsyslog'],
      require => File['/etc/rsyslog.d'],
    }

    file { '/var/spool/rsyslog':
      ensure => directory,
      owner  => syslog,
      group  => adm,
      mode   => '0775',
    }
  }
}

class rsyslog::server ($raw_log=undef, $enable_tcp=undef, $enable_udp=undef, $enable_relp=undef) {

  include rsyslog

  if $raw_log != undef {

    file { '/etc/rsyslog.d/35-raw.conf':
      source  => 'puppet:///modules/rsyslog/35-raw.conf',
      owner   => root,
      group   => root,
      mode    => 0644,
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
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  $admin_hosts = hiera('firewall::admin_hosts', [])

  file { '/etc/rsyslog.d/02-input-modules.conf':
    content => template("rsyslog/02-input-modules.conf.erb"),
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/51-server-rules.conf':
    source  => 'puppet:///modules/rsyslog/51-server-rules.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/rsyslog.d/75-input-server.conf':
    content => template('rsyslog/75-input-server.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  file { '/etc/logrotate.d/remote-rsyslogs':
    require => Package['logrotate'],
    source  => 'puppet:///modules/rsyslog/logrotate.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
  }

  file { '/var/log/remote-syslogs':
    ensure  => directory,
    owner   => syslog,
    group   => adm,
    mode    => 0770,
    notify  => Service['rsyslog'],
  }

  $infra_hosts = hiera('firewall::infra_hosts', [])

  if $enable_tcp != undef {

    firewall::multisource {[ prefix($infra_hosts, '101 rsyslog-tcp,') ]:
      action => 'accept',
      proto  => 'tcp',
      dport  => 514,
    }
  }

  if $enable_udp != undef {

    firewall::multisource {[ prefix($infra_hosts, '101 rsyslog-udp,') ]:
      action => 'accept',
      proto  => 'udp',
      dport  => 514,
    }
  }

  if $enable_relp != undef {

    firewall::multisource {[ prefix($infra_hosts, '101 rsyslog-relp,') ]:
      action => 'accept',
      proto  => 'tcp',
      dport  => 20514,
    }
  }

}

class rsyslog::server::ui inherits rsyslog::server {

  file { '/etc/rsyslog.d/30-logstash.conf':
    source  => 'puppet:///modules/rsyslog/30-logstash.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }

  include logstash

  class { 'elasticsearch':
    config                   => {
      'cluster'              => {
        'name'               => 'logstash'
      },
      'index'                        => {
        'number_of_replicas'         => '0',
        'number_of_shards'           => '5',
      },
      'network'              => {
        'host'               => '127.0.0.1'
      },
      'discovery'            => {
        'ping'               => {
          'zen'              => {
            'multicast'      => {
              'enabled'      => 'false'
            },
            'unicast'        => {
              'hosts'        => '127.0.0.1:9301'
            },
          },
        },
      },
     'path'                  => {
        'conf'               => '/etc/elasticsearch',
        'data'               => '/var/lib/elasticsearch',
        'logs'               => '/var/log/elasticsearch',
      },
    }
  }

  class { 'kibana': }
}
