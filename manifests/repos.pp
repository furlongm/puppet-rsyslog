class rsyslog::repos {

  apt::source { 'rsyslog':
    location     => 'http://ppa.launchpad.net/adiscon/v7-stable/ubuntu/',
    release      => "$::lsbdistcodename",
    repos        => 'main',
    pin          => '2200',
    key          => '5234BF2B',
    include_src  => false,
 }
}
