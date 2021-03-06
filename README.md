# dp_bup - a bup lwrp cookbook for chef.

## Overview
This cookbook allows you to install bup on client and server and then schedule backups.
It depends the cookbooks [cron](https://github.com/opscode-cookbooks/cron) and [line](https://github.com/someara/line-cookbook).

### usage
**Clients:**

To setup backup clients first you need to put `depends "dp_bup"` in metadata.rb in your cookbook.

Then in your recipe you should use the dp_bup provider like this.

```ruby
dp_bup "/opt/application/data /etc /home" do
  backupsrv "backupsrv01.local.corp"
end
```

To remove a backup run this:

```ruby
dp_bup "/opt/applications/data /etc" do
  action :delete
end
```

You also need to generate a ssh key pair and create a file *files/default/bup_id_rsa*

**Servers:**

To setup a bup server. Have a look in *dp_bup::server* or just apply that recipe.

Currently it will install bup, create bup user, add bup public RSA key with limited use to only bup server, initialize bup repository and schedule `bup fsck -g`.

Don't forget to change the *files/default/authorized_keys* to match your public key used for backups.

#### Available options
* **bupname** - name in bup of the backup(defaults to ${HOSTNAME} so you might want to set this if one node is running multiple backups) - You might also want to backup several applications in different recipes. Then this could be something like "${HOSTNAME}_app01".
* **precmd** - command to run before backup(defaults to false).
* **postcmd** - command to run after backup(defaults to false).
* **backupsrv** - destination backup server(this option is required).
* **backupdst** - destination directory(defaults to /backup/bup).
* **minute** - (defaults to 0).
* **hour** - (defaults to 4).
* **day** - (defaults to *).
* **month** - (defaults to *).
* **weekday** - (defaults to *).

Examples:

```ruby
dp_bup "/opt/application/data /etc" do
  bupname "${HOSTNAME}"
  backupsrv "backupsrv01.local.corp"
  backupdst "/backup/bup"
  minute "10"
  hour "*/3"
  day "*"
  month "*"
  weekday "1-5"
end
```

```ruby
	dp_bup "/etc/bind /var/cache/bind" do
	  bupname "${HOSTNAME}_bind"
	  backupsrv "backupsrv01.local.corp"
	  hour "7"
	  precmd "/usr/sbin/rndc freeze && /usr/sbin/rndc thaw && sleep 1"
	end
```

```ruby
	dp_bup "/etc/dhcp /var/lib/dhcp/dhcpd.*" do
	  bupname "${HOSTNAME}_dhcp"
	  backupsrv "backupsrv01.local.corp"
	  hour "7"
	  minute "15"
	end
```

#### How it works
By default you only need to specify the directories to be backed up and the backup server.

What the provider does is that it creates a bup cron job under */etc/cron.d/* which runs bup according to what is set in the declaration. If no time is specified the backup runs at 04:00 every day.
