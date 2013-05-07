class rsyslog($port) {

  Package { ensure => present }

  $rsyslog_packages = ['rsyslog', 'rsyslog-relp', 'logrotate']

  package { $rsyslog_packages: }

  service { 'rsyslog':
    ensure  => running,
    enable  => true,
    require => Package[$rsyslog_packages],
  }

  # (temporary)
  file { ['/etc/rsyslog.d/50-default.conf','/etc/rsyslog.d/60-central.conf']:
    ensure  => absent,
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['rsyslog'],
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
}

class rsyslog::client($server) inherits rsyslog {

  # set this to allow the syslog server to be excluded (confusingly)
  if $server != 'False' {

    class { openvpn : }

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

class rsyslog::server inherits rsyslog {

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
        'host'               => '0.0.0.0'
      },
     'path'                  => {
        'conf'               => '/etc/elasticsearch',
        'data'               => '/var/lib/elasticsearch',
        'logs'               => '/var/log/elasticsearch',
      },
    }
  }

  class { 'kibana': }
  class { 'nginx': }

  file { '/etc/nginx/sites-available/syslog-server.conf':
    content => template('rsyslog/rsyslog-nginx.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0644,
    notify  => Service['nginx'],
  }

  file { '/etc/nginx/sites-enabled/syslog-server.conf':
    ensure  => link,
    target  => '/etc/nginx/sites-available/syslog-server.conf',
    owner   => root,
    group   => root,
    notify  => Service['nginx'],
  }
}
