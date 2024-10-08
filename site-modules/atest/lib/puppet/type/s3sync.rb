Puppet::Type.newtype(:s3sync) do
  desc "Puppet type for awscli 's3 sync' command"

  ensurable

  newparam(:localpath, :namevar => true) do
    desc "Local path to sync a s3 bucket to"
  end

  newparam(:bucket) do
    desc "s3 bucket to sync"
  end

  newparam(:region) do
    desc "region of the s3 bucket"
    defaultto 'us-east-2'
  end

  newparam(:connect_timeout) do
    desc "maximum socket connect time in seconds"
    defaultto '0'
  end
end
