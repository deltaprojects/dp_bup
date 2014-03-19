actions :backup, :delete
default_action :backup

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :cookbook, :kind_of => String, :default => "db_bup"
attribute :bupname, :kind_of => String, :default => "${HOSTNAME}"
attribute :precmd, :kind_of => [String, FalseClass], :default => false
attribute :postcmd, :kind_of => [String, FalseClass], :default => false
# where to backup
attribute :backupsrv, :kind_of => String, :required => true
attribute :backupdst, :kind_of => String, :default => "/backup/bup"
attribute :backupdir, :kind_of => String, :default => "/mnt/bup"
# when to backup
attribute :minute, :kind_of => [Integer, String], :default => "0"
attribute :hour, :kind_of => [Integer, String], :default => "4"
attribute :day, :kind_of => [Integer, String], :default => "*"
attribute :month, :kind_of => [Integer, String], :default => "*"
attribute :weekday, :kind_of => [Integer, String], :default => "*"

def initialize(*args)
  super
  @action = :backup

  @run_context.include_recipe "dp_bup"
  @run_context.include_recipe "nfs"
  @run_context.include_recipe "cron"
end
