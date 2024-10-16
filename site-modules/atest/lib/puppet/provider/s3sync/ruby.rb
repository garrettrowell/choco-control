Puppet::Type.type(:s3sync).provide(:ruby) do
  commands aws: 'aws'

  #
  # NOTE: In practice all of the calls to 'Puppet.info' should be replaced with 'Puppet.debug'
  #       They are here solely for ease of demonstration.
  #
  #       Additionally, the dry_run and do_sync methods allow you to set a fact to bypass
  #       executing the aws command. While good for validating behavior, it should be removed for actual use.
  #

  mk_resource_methods

  # return an array of default arguments to pass to the aws command to perform the s3sync
  def default_s3sync_cmd
    [
      's3', 'sync', @resource[:bucket], @resource[:localpath], '--cli-connect-timeout', @resource[:connect_timeout],
      '--region', @resource[:region]
    ]
  end

  def dry_run
    begin
      output = case Facter.value('s3sync_dryrun_override')
               when 'sync'
                 # one file was found to either not exist or be out of sync
                 "(dryrun) download: #{@resource[:bucket]}/some.rpm to #{@resource[:localpath]}/some.rpm"
               when 'multi_sync'
                 # same as 'sync' just with two
                 <<~END_OF_OUTPUT
                 (dryrun) download: #{@resource[:bucket]}/some.rpm to #{@resource[:localpath]}/some.rpm
                 (dryrun) download: #{@resource[:bucket]}/another.rpm to #{@resource[:localpath]}/another.rpm
                 END_OF_OUTPUT
               when 'empty'
                 # the dryrun command returns no output if the localfilepath is in sync
                 ''
               else
                 # actually run the command instead of stubbing out scenarios
                 aws(default_s3sync_cmd.append('--dryrun'))
               end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Failed to check if #{@resource[:localpath]} is in-sync with  #{@resource[:bucket]}: #{detail}", detail.backtrace
    end

    to_sync = output.split("\n").sort
    Puppet.info("#{self} - .dry_run to_sync: #{to_sync}")
    to_sync
  end

  def do_sync
    # This raises a Puppet::ExecutionFailure Puppet.err unless the command returns an exitcode 0
    aws(default_s3sync_cmd) unless !Facter.value('s3sync_override').nil?
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Failed to sync #{@resource[:localpath]} to #{@resource[:name]}: #{detail}", detail.backtrace
  end

  def exists?
    Puppet.info "#{self} - ensure => #{@resource[:ensure]}"
    if File.directory?(@resource[:localpath]) || File.exist?(@resource[:localpath])
      # Only run the dry_run when ensuring present. If we're ensuring absent... we've already determined it's here
      # If the directory or file exists we need to check if what we have locally is insync with whats in the bucket
      # if dry_run returns an empty array, we are in sync
      result = (@resource[:ensure] == :present) ? dry_run.empty? : true
      Puppet.info("#{self} - .exists? result: #{result}")
      result
    else
      Puppet.info("#{self} - .exists? file/dir not there")
      false
    end
  end

  def create
    do_sync
  end

  def destroy
    Puppet.info("#{self} - Cleaning up: #{@resource[:localpath]}")
    if File.directory?(@resource[:localpath])
      Dir[ File.join(@resource[:localpath], '**', '*') ].each { |f| Puppet.info("#{self} - Removing: #{f}") }
      FileUtils.remove_dir(@resource[:localpath])
    elsif File.exist?(@resource[:localpath])
      FileUtils.rm(@resource[:localpath])
    else
      Puppet.err("#{self} - Why was .destroy called when #{@resource[:localpath]} does not exist...")
    end
  end
end
