class rsyslog::client($server,
                      $transport='relp',
                      $logrotation='weekly')
  inherits rsyslog {

  include logrotate

  if (is_ip_address($server) and has_interface_with("ipaddress", $server)) or $::fqdn == $server {
    $is_server = true
  }

  if $is_server != true {

    file { '/etc/rsyslog.d/60-remote-server.conf':
      content => template("rsyslog/60-remote-server.conf.erb"),
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
  logrotate::rule { 'syslog':
    ensure     => present,
    path       => '/var/log/syslog',
    options    => [ 'rotate 7', 'daily', 'missingok', 'notifempty', 'delaycompress', 'compress' ],
    postrotate => 'reload rsyslog >/dev/null 2>&1 || true'
  }
  logrotate::rule { 'rsyslog':
    ensure     => present,
    path       => [ '/var/log/mail.info', '/var/log/mail.err', '/var/log/mail.warn', '/var/log/mail.log',
                    '/var/log/daemon.log', '/var/log/kern.log', '/var/log/auth.log',
                    '/var/log/user.log', '/var/log/lpr.log', '/var/log/cron.log', '/var/log/rsyslog.log',
                    '/var/log/debug', '/var/log/messages' ],
    options    => [ 'rotate 4', $logrotation, 'missingok', 'notifempty', 'delaycompress', 'compress', 'sharedscripts' ],
    postrotate => 'reload rsyslog >/dev/null 2>&1 || true'
  }
}
