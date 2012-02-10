class rsyslog {

	package { 'stunnel':
		ensure => present,
		before => [Package['rsyslog'],File['/etc/stunnel/stunnel.conf'],File['/etc/default/stunnel4']],
	}

	file { '/etc/default/stunnel4':
		ensure => file,
		require => Package['stunnel'],
		source => 'puppet:///rsyslog/stunnel-default',
	}

	file { '/etc/stunnel/stunnel.conf':
		ensure => file,
		require => Package['stunnel'],
		source => 'puppet:///rsyslog/stunnel.conf',
	}

	service { 'stunnel4':
		ensure => running,
		enable => true,
		hasrestart => true,
		hasstatus => false,
		status => "true",
		subscribe => [File['/etc/stunnel/stunnel.conf'],File['/etc/default/stunnel4']],
	}

	package { 'rsyslog':
		ensure => present,
		before => File['/etc/rsyslog.d/60-centrallogging.conf'],
	}

	file { '/etc/rsyslog.d/60-centrallogging.conf':
		ensure => file,
		require => Package['rsyslog'],
		source => 'puppet:///rsyslog/centrallogging.conf',
	}

	service { 'rsyslog':
		ensure => running,
		enable => true,
		hasrestart => true,
		hasstatus => true,
		subscribe => File['/etc/rsyslog.d/60-centrallogging.conf'],
	}
}
