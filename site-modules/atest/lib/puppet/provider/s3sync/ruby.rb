Puppet::Type.type(:s3sync).provide(:ruby) do
  commands :aws => 'aws'

  def dry_run(bucket, localpath, connect_timeout, region)
    override = 'empty'
    case override
    when 'sync_needed'
      output = "(dryrun) download: #{bucket}/some.rpm to #{localpath}/some.rpm"
    when 'empty'
      output = ''
    else
      begin
        output = aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region, '--dryrun'])
      rescue Puppet::ExecutionFailure => e
        Puppet.err(e.message)
        return nil
      end
    end
    to_sync = output.split("\n").sort
    # likely need more logic here
    to_sync
  end

  def do_sync(bucket, localpath, connect_timeout, region)
    begin
      aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region])
    rescue Puppet::ExecutionFailure => e
      Puppet.err(e.message)
    end
  end

  def exists?
    # if dry_run returns an empty array, we are in sync
    result = dry_run(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region]).empty?
    Puppet.info(".exists? result: #{result}")
  end

  def create
    Puppet.info('in create')
    do_sync(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region])
  end

  def destroy
    Puppet.info('destroy currently not implemented')
    Puppet.info("Going to cleanup #{resource[:localpath]}")
    FileUtils.remove_dir(resource[:localpath])
  end
end
