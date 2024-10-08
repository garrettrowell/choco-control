## site.pp ##

# This file (./manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
# https://puppet.com/docs/puppet/latest/dirs_manifest.html
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition if you want to use it.

## Active Configurations ##

# Disable filebucket by default for all File resources:
# https://github.com/puppetlabs/docs-archive/blob/master/pe/2015.3/release_notes.markdown#filebucket-resource-no-longer-created-by-default
File { backup => false }

if $facts['os']['family'] == 'windows' {
  # Set chocolatey as default package provider on windows
  Package {
    provider         => chocolatey,
    package_settings => {
      'verbose'    => true,
      'log_output' => true,
    },
    require          => Class['chocolatey'],
  }

  # Ensure any config happens after installing chocolatey
  Class['chocolatey'] -> Chocolateyconfig <||>
  # Ensure any sources get configured after installing
  Class['chocolatey'] -> Chocolateysource <||>
  # Ensure any features get configured after installing
  Class['chocolatey'] -> Chocolateyfeature <||>
  # Ensure any chocolatey config happens before any packages using chocolatey
  Chocolateyconfig <||> -> Package <| provider == 'chocolatey' |>
  # Ensure any sources get configured before any packages using chocolatey
  Chocolateysource <||> -> Package <| provider == 'chocolatey' |>
  # Ensure any features get configured before any packages using chocolatey
  Chocolateyfeature <||> -> Package <| provider == 'chocolatey' |>
}

## Node Definitions ##

node default {
  #include awss3
  if $facts['os']['family'] == 'windows' {

    $proxy          = 'http://172.31.64.151:3128'
    $proxy_user     = 'atest'
    $proxy_password = 'testing'
    $tempdir        = 'C:\tmp'

    class { 'chocolatey':
      log_output                     => true,
      choco_install_location         => 'C:\Program Files\chocolatey',
      install_proxy                  => $proxy,
      install_proxy_user             => $proxy_user,
      install_proxy_password         => Sensitive($proxy_password),
      #install_tempdir               => $tempdir,
      #      use_7zip                => true,
      #      seven_zip_download_url  => 'https://chocolatey.org/7za.exe',
      #      chocolatey_download_url => 'https://chocolatey.org/api/v2/package/chocolatey/',
      #      chocolatey_version      => '2.0.0',
      #      ignore_proxy            => true,
    }

    chocolateyconfig {
      'proxy':
        value => $proxy,
      ;
      'proxyUser':
        value => $proxy_user,
      ;
      'proxyPassword':
        value => $proxy_password,
      ;
    #      'cacheLocation':
    #        value => $tempdir,
    #      ;
    }

    package { ['notepadplusplus', 'firefox']:
      ensure  => installed,
    }
  } else {
    s3sync { 'atest':
      localpath => '/tmp/imatest',
      bucket    => 's3://somebucket/someobject',
    }
    #  s3_get_object { '/tmp/imatest':
    #    ensure      => present,
    #    bucket_name => 'somebucket',
    #    object_key  => 'some_object'
    #  }
    #    $tree = dirtree('/tmp/does/not/exist')
    #    notify { "${tree}": }
    #
    #    include dropsonde
    #
    #    class { 'archive':
    #      aws_cli_install => true,
    #    }
    #
    #    atest::s3get { 'atest':
    #      bucket_name         => 'somebucket',
    #      bucket_file         => 'somedir/somefile',
    #      local_file_location => '/tmp/imatest'
    #    }
    #    archive { '/tmp/imatest':
    #      ensure          => present,
    #      source          => 's3://somebucket/somefile',
    #    }
  }
}
