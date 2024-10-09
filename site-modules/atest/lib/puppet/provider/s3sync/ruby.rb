Puppet::Type.type(:s3sync).provide(:ruby) do
  commands :aws => 'aws'

  mk_resource_methods

  # return an array of default arguments to pass to the aws command to perform the s3sync
  def default_s3sync_cmd
    [
      's3', 'sync', resource[:bucket], resource[:localpath], '--cli-connect-timeout', resource[:connect_timeout],
      '--region', resource[:region]
    ]
  end

  def dry_run
    case Facter.value('s3sync_dryrun_override')
    when 'sync_needed'
      output = "(dryrun) download: #{resource[:bucket]}/some.rpm to #{resource[:localpath]}/some.rpm"
    when 'multi_sync'
      output = "(dryrun) download: #{resource[:bucket]}/some.rpm to #{resource[:localpath]}/some.rpm\n(dryrun) download: #{resource[:bucket]}/another.rpm to #{resource[:localpath]}/another.rpm"
    when 'empty'
      output = ''
    else
      output = aws(default_s3sync_cmd.append('--dryrun'))
    end
    to_sync = output.split("\n").sort
    Puppet.info("to_sync: #{to_sync.inspect}")
    # likely need more logic here
    to_sync
  end

  def do_sync
    Puppet.info "cmd: #{default_s3sync_cmd.inspect}"
    # This raises a Puppet::ExecutionFailure Puppet.err unless the command returns an exitcode 0
    begin
      aws(default_s3sync_cmd)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Failed to sync #{resource[:localpath]} to #{resource[:name]}: #{detail}", detail.backtrace
    end
  end

  def exists?
    if File.directory?(resource[:localpath]) || File.exist?(resource[:localpath])
      # If the directory or file exists we need to check if what we have locally is insync with whats in the bucket
      # if dry_run returns an empty array, we are in sync
#      result = dry_run.empty?
#      Puppet.info(".exists? dry_run result: #{result}")
#      result
      true
    else
      Puppet.info('.exists? file/dir not there')
      false
    end
  end

  def create
    Puppet.info('in create')
    do_sync
  end

  def destroy
    Puppet.info("Going to cleanup #{resource[:localpath]}")
    if File.directory?(resource[:localpath])
      FileUtils.remove_dir(resource[:localpath])
    elsif File.exist?(resource[:localpath])
      FileUtils.rm(resource[:localpath])
    else
      Puppet.err("Why was .destroy called when #{resource[:localpath]} does not exist...")
    end
  end
end
