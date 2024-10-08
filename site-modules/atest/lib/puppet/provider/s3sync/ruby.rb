Puppet::Type.type(:s3sync).provide(:ruby) do
  commands :aws => 'aws'

  def dry_run(bucket, localpath, connect_timeout, region)
    begin
      output = aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region, '--dryrun'])
    rescue Puppet::ExecutionFailure => e
      Puppet.err(e.inspect)
      return nil
    end
    to_sync = output.split("\n").sort
    # likely need more logic here
    to_sync
  end

  def do_sync(bucket, localpath, connect_timeout, region)
    begin
      aws(['s3', 'sync', bucket, localpath, '--exact-timestamps', '--cli-connect-timeout', connect_timeout, '--region', region])
    rescue Puppet::ExecutionFailure => e
      Puppet.err(e.inspect)
    end
  end

  def exists?
    # if --dryrun returns nothing, we are in sync
    dry_run(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region]) == nil
  end

  def create
    do_sync(resource[:bucket], resource[:localpath], resource[:connect_timeout], resource[:region])
  end

  def destroy
    Puppet.debug('destroy currently not implemented')
  end
end
