# install bup, allow unsigned packages since we've backported latest bup to ubuntu precise.
package 'bup' do
  options "--allow-unauthenticated"
  not_if 'which bup'
end

# where do we want to put the backup repo
bupdir = "/backup/bup"

# ensure directory exists with correct permissions
directory bupdir do
  owner "nobody"
  group "nogroup"
  mode "0755"
  action :create
end

# create the bup repository for the first time
execute "bup initialize" do
  command "/usr/bin/bup -d #{bupdir} init"
  creates "/backup/bup/config"
  user "nobody"
  group "nogroup"
  action :run
end

# generate recovery blocks for any packs that don't already have them
cron_d "bup_fsck" do
  hour "08"
  minute "0"
  command "/usr/bin/bup -d #{bupdir} fsck -g"
  user "nobody"
  home bupdir
end

# setup a nfs server 
include_recipe "nfs::server"

# export the backup directory via nfs
nfs_export bupdir do
  network '10.0.0.0/8'
  writeable true 
  sync true
  options ['no_subtree_check', 'all_squash']
end
