==============
Puppet Rsyslog
==============

Classes
=======

rsyslog
-------
For default local rsyslog setup

Variables:
 * rsyslog::port - Port when using remote logging

rsyslog::client
---------------
For remote logging on client
 - depends on openvpn class

Variables:
 * rsyslog::client::server - Server to send logs to

Example usage for client:
```puppet
  node 'host.rc.nectar.org.au' inherits base {
    $openvpn_hosts = [ 'admin.rc.nectar.org.au 1194' ]
    include openvpn::client
    include rsyslog::client
  }
```
rsyslog::server
---------------
Sets up a rsyslog server
 - depends on openvpn class


rsyslog::server::ui
-------------------
Sets up web interface to view logs

Depends on the following modules and classes
 * garethr-kibana (v0.0.1)
 * ispavailability-elasticsearch (v0.0.2)
 * ispavailability-logstash (v0.0.4)
 * nginx
