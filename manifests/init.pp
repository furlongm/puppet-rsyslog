class rsyslog($port) {

  Package { ensure => present }

  $rsyslog_packages = ['rsyslog', 'rsyslog-relp']

  package { $rsyslog_packages: }

  service { 'rsyslog':
    ensure  => running,
    enable  => true,
    require => Package[$rsyslog_packages],
  }

  file {'/etc/rsyslog.d':
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
  }

  file { '/etc/rsyslog.d/10-global-directives.conf':
    source  => 'puppet:///modules/rsyslog/10-global-directives.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
  }

  file { '/etc/rsyslog.d/50-default-rules.conf':
    source  => 'puppet:///modules/rsyslog/50-default-rules.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
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

class rsyslog::client($server) inherits rsyslog {

  if (is_ip_address($server) and has_interface_with("ipaddress", $server)) or $::fqdn == $server {
    $is_server = true
  }

  if $is_server != true {

    file { '/etc/rsyslog.d/03-relp-output-modules.conf':
      source  => 'puppet:///modules/rsyslog/03-relp-output-modules.conf',
      owner   => root,
      group   => root,
      mode    => 0644,
      notify  => Service['rsyslog'],
    }

    file { '/etc/rsyslog.d/60-remote-server.conf':
      content => template("rsyslog/60-remote-server.conf.erb"),
      owner   => root,
      group   => root,
      mode    => 0644,
      notify  => Service['rsyslog'],
    }

    file { '/var/spool/rsyslog':
      ensure => directory,
      owner  => syslog,
      group  => adm,
      mode   => '0775',
    }
  }
}

class rsyslog::server ($raw_log=undef) inherits rsyslog {

  if $raw_log != undef {

    file { '/etc/rsyslog.d/35-raw.conf':
      source  => 'puppet:///modules/rsyslog/35-raw.conf',
      owner   => root,
      group   => root,
      mode    => 0644,
      notify  => Service['rsyslog'],
    }

  } else {

    file { '/etc/rsyslog.d/35-raw.conf':
      ensure => absent,
      notify => Service['rsyslog'],
    }

  }

  $admin_hosts = hiera('iptables_templates::admin_hosts', [])

  file { '/etc/rsyslog.d/02-relp-input-modules.conf':
    source  => 'puppet:///modules/rsyslog/02-relp-input-modules.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
  }

  file { '/etc/rsyslog.d/51-server-rules.conf':
    source  => 'puppet:///modules/rsyslog/51-server-rules.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
  }

  file { '/etc/rsyslog.d/75-relp-server.conf':
    content => template('rsyslog/75-relp-server.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
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

  firewall::multisource {[ prefix($infra_hosts, '100 rsyslog tcp,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => [$rsyslog::port, 514],
  }

  firewall::multisource {[ prefix($infra_hosts, '100 rsyslog udp,') ]:
    action => 'accept',
    proto  => 'udp',
    dport  => [514],
  }
}

class rsyslog::server::ui inherits rsyslog::server {

  file { '/etc/rsyslog.d/30-logstash.conf':
    source  => 'puppet:///modules/rsyslog/30-logstash.conf',
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
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
