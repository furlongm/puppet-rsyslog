class rsyslog::logstash (
) inherits rsyslog::server {

  file { '/etc/rsyslog.d/30-logstash.conf':
    source  => 'puppet:///modules/rsyslog/30-logstash.conf',
    notify  => Service['rsyslog'],
    require => File['/etc/rsyslog.d'],
  }
}
