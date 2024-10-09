Puppet::Type.type(:s3sync).provide(:ruby) do
  commands :aws => 'aws'

  mk_resource_methods

  def dry_run(bucket, localpath, connect_timeout, region)
    case Facter.value('s3sync_dryrun_override')
    when 'sync_needed'
      output = "(dryrun) download: #{bucket}/some.rpm to #{localpath}/some.rpm"
    when 'multi_sync'
      output = "(dryrun) download: #{bucket}/some.rpm to #{localpath}/some.rpm\n(dryrun) download: #{bucket}/another.rpm to #{localpath}/another.rpm"
    when 'empty'
      output = ''
    else
      output = aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region, '--dryrun'])
    end
    to_sync = output.split("\n").sort
    Puppet.info("to_sync: #{to_sync.inspect}")
    # likely need more logic here
    to_sync
  end

  def do_sync(bucket, localpath, connect_timeout, region)
    # This raises a Puppet::ExecutionFailure Puppet.err unless the command returns an exitcode 0
    begin
      aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region])
    rescue Puppet::ExecutionFailure => detail
      Puppet.info "backtrace: #{detail.backtrace}"
      raise Puppet::Error, "Failed to s3sync on #{resource[:name]}: #{detail}", detail.backtrace
    end
  end

  def exists?
    if File.directory?(resource[:localpath]) || File.exist?(resource[:localpath])
      # If the directory or file exists we need to check if what we have locally is insync with whats in the bucket
      # if dry_run returns an empty array, we are in sync
      result = dry_run(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region]).empty?
      Puppet.info(".exists? dry_run result: #{result}")
      result
    else
      Puppet.info('.exists? file/dir not there')
      false
    end
  end

  def create
    Puppet.info('in create')
    do_sync(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region])
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
