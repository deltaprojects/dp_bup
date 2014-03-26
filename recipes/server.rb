# install bup, allow unsigned packages since we've backported latest bup to ubuntu precise.
package 'bup' do
  options "--allow-unauthenticated"
  not_if 'which bup'
end

# where do we want to put the backup repo
bupdir = "/backup/bup"

# create group and user for backups
group "bup" do
  action :create
  gid 789
end

user "bup" do
  action :create
  comment "Backup user"
  uid 789
  gid "bup"
  home bupdir
  shell "/bin/sh"
  system true
end

# ensure directory exists with correct permissions
directory bupdir do
  owner "bup"
  group "bup"
  mode "0755"
  action :create
end

directory "#{bupdir}/.ssh" do
  owner "bup"
  group "bup"
  mode "0755"
  action :create
end

cookbook_file "#{bupdir}/.ssh/authorized_keys" do
  source "authorized_keys"
  owner "root"
  group "root"
  mode "0644"
end

# create the bup repository for the first time
execute "bup initialize" do
  command "/usr/bin/bup -d #{bupdir} init"
  creates "/backup/bup/config"
  user "bup"
  group "bup"
  action :run
end

# generate recovery blocks for any packs that don't already have them
cron_d "bup_fsck" do
  hour "08"
  minute "0"
  command "/usr/bin/bup -d #{bupdir} fsck -g"
  user "bup"
  home bupdir
end
