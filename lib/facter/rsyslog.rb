if FileTest.exists?("/usr/sbin/rsyslogd")
  Facter.add('rsyslog_majversion') do
    setcode do
      %x{rsyslogd -v | head -n 1 | awk {'print $2'} | cut -d . -f 1}
    end
  end
end
