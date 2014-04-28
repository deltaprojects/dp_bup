action :backup do
  # create directory where to index backup files.
  restest = directory "/var/cache/bup" do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)
  
  # make sure root has a dot ssh dir
  restest = directory "/root/.ssh/" do
    owner "root"
    group "root"
    mode "0700"
    action :create
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)

  # create private key for backup server
  restest = cookbook_file "/root/.ssh/bup_id_rsa" do
    source "bup_id_rsa"
    owner "root"
    group "root"
    mode "0600"
    cookbook "dp_bup"
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)

  restest = file "/root/.ssh/config" do
    #action :create_if_missing
    owner "root"
    group "root"
    mode "0644"
    content "Host #{new_resource.backupsrv}\n  User bup\n  IdentityFile ~/.ssh/bup_id_rsa\n  StrictHostKeyChecking no\n"
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)

  # had to remove this since it's keeps creating same lines over and over..
  # restest = replace_or_add "add bup ssh config" do
  #   path "/root/.ssh/config"
  #   pattern "Host #{new_resource.backupsrv}"
  #   line "Host #{new_resource.backupsrv}\n  User bup\n  IdentityFile ~/.ssh/bup_id_rsa\n  StrictHostKeyChecking no"
  # end
  # new_resource.updated_by_last_action(restest.updated_by_last_action?)
  
  new_resource.updated_by_last_action(restest.updated_by_last_action?)
  # setting the backup command that cron should run
  bupcmd = "/usr/bin/bup index -f /var/cache/bup/bupindex -ux #{new_resource.name} && /usr/bin/bup save -f /var/cache/bup/bupindex -1 -r #{new_resource.backupsrv}:#{new_resource.backupdst} -n #{new_resource.bupname} #{new_resource.name}"
 
  # add a command to run before backup
  if new_resource.precmd
    bupcmd = "#{new_resource.precmd} && #{bupcmd}"
  end

  # add a command after backup
  if new_resource.postcmd
    bupcmd = "#{bupcmd} && #{new_resource.postcmd}"
  end

  # encapsulate bupcmd inside paranthesis and send output from cron to a log file
  bupcmd = "(#{bupcmd}) &>> /var/log/cron_output.log"
  # now put the command in a cron.d line
  cronline = "#{new_resource.minute} #{new_resource.hour} #{new_resource.day} #{new_resource.month} #{new_resource.weekday} root #{bupcmd}"

  # schedule backup using a cron.d file
  if ::File.zero? '/etc/cron.d/bup' or not ::File.exists? '/etc/cron.d/bup'
    file '/etc/cron.d/bup' do
      content "# crontab managed by chef\n#{cronline}\n"
    end
    new_resource.updated_by_last_action(true)
  else
    restest = replace_or_add "add crontab line to /etc/cron.d/bup" do
      path "/etc/cron.d/bup"
      pattern ".*/usr/bin/bup.*-n #{Regexp.escape(new_resource.bupname)} .*"
      line cronline
    end
    new_resource.updated_by_last_action(restest.updated_by_last_action?)
  end # end if

  restest = file "/etc/logrotate.d/cron_output" do
    action :create
    owner "root"
    group "root"
    mode "0644"
    content "/var/log/cron_output.log {
      missingok
      notifempty
      daily
      rotate 8
      dateext
      compress
      delaycompress
    }\n"
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)

end # end action: backup

action :delete do
  restest = delete_lines "remove crontab line from /etc/cron.d/bup" do
    path "/etc/cron.d/bup"
    pattern ".*/usr/bin/bup.*-n #{Regexp.escape(new_resource.bupname)} .*"
  end
  new_resource.updated_by_last_action(restest.updated_by_last_action?)

end # end action: delete
