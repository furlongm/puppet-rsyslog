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
    hasrestart => true,
    hasstatus  => true,
    require    => Package["rsyslog-relp"],
  }
}

class rsyslog::server inherits rsyslog {
  
  file { '/etc/rsyslog.conf':
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package["rsyslog-relp"],
    content => template("rsyslog/rsyslog.server.erb"),
    notify  => Service['rsyslog'],
  }
  
  file { '/etc/rsyslog.d/60-central.conf':
      path    => "/etc/rsyslog.d/60-centtelnet ral.conf",
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package["rsyslog-relp"],
      content => template("rsyslog/60-central.server.erb");
    notify  => Service['rsyslog'],
  }
  
  service { 'rsyslog':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    status     => "true",
    require    => Package["rsyslog-relp"],
    subscribe  => [ File[server-conf],File[server-central-conf],Package["rsyslog-relp"]]
  }

  file { 'logrotate-remote-syslog':
    path    => "/etc/logrotate.d/remote-rsyslog",
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package[ logrotate ],
    content => template("rsyslog/logrotate.conf")
  }
 
}
