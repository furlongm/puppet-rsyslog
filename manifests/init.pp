class rsyslog {

  package { 'rsyslog':
    ensure => installed,
    require => Package['openvpn'],
  }

  package { 'rsyslog-relp':
    ensure => installed,
    require => Package['rsyslog'],
    notify  => Service['rsyslog'],
  }
}

class rsyslog::client inherits rsyslog {

  file { '/etc/rsyslog.conf':
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    content => template("rsyslog/rsyslog.client.erb"),
  }

  file { 'client-default-conf':
    path    => "/etc/rsyslog.d/50-default.conf",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    source  => 'puppet:///modules/rsyslog/50-default.conf',
    notify  => Service['rsyslog'],
  }

  file { 'client-central-conf':
    path    => "/etc/rsyslog.d/60-central.conf",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    content => template("rsyslog/60-central.client.erb"),
    notify  => Service['rsyslog'],
  }

  service { 'rsyslog':
    ensure     => running,
    enable     => true,
    require    => Package["rsyslog-relp"],
  }

  file { '/var/spool/rsyslog':
    ensure => directory,
    owner  => syslog,
    group  => adm,
    mode   => '0755',
  }

}

class rsyslog::server inherits rsyslog {

  file { 'rsyslog-server-conf':
    path    => '/etc/rsyslog.conf',
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    content => template("rsyslog/rsyslog.server.erb"),
    notify  => Service['rsyslog'],
  }

  file { 'rsyslog-central-conf':
    path    => "/etc/rsyslog.d/60-central.conf",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    content => template("rsyslog/60-central.server.erb"),
    notify  => Service['rsyslog'],
  }

  service { 'rsyslog':
    ensure     => running,
    enable     => true,
    require    => Package["rsyslog-relp"],
    subscribe  => [ File['rsyslog-server-conf'],
                    File['rsyslog-central-conf'],
                    Package["rsyslog-relp"]],
  }

  file { 'logrotate-remote-syslog':
    path    => "/etc/logrotate.d/remote-rsyslog",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package[logrotate],
    content => template("rsyslog/logrotate.conf"),
  }

}
