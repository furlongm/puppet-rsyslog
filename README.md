==============
Puppet Rsyslog
==============

Classes
=======

rsyslog
-------
For default local rsyslog setup

rsyslog::client
---------------

Variables:
 * rsyslog::client::server - Server to send logs to

rsyslog::server
---------------
Sets up a rsyslog server

Web Interface
=============

To set up the kibana web interface to view logs created using the format in
this module please use the NeCTAR-RC/puppet-elk module.
