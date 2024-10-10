Puppet::Type.newtype(:s3sync) do
  desc 'Puppet type for `aws s3 sync` subcommand'

#  newproperty(:ensure) do
  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto :present
  end

  newparam(:localpath, :namevar => true) do
    desc 'Local path to sync a s3 bucket to'

#    def insync?(is)
#      Puppet.info 'in insync'
#      provider.dry_run.empty?
#      super(is)
#    end
  end

  newparam(:bucket) do
    desc 's3 bucket to sync'
  end

  newparam(:region) do
    desc 'region of the s3 bucket'
    defaultto 'us-east-2'
  end

  newparam(:connect_timeout) do
    desc 'maximum socket connect time in seconds'
    defaultto '0'
  end

  newproperty(:insync) do
    desc 'Whether the bucket contents match the local copy (readonly)'
    newvalue(:true) do
      provider.dry_run.empty?
    end

    newvalue(:false) do
      provider.do_sync
    end

    defaultto :false
  end
end
