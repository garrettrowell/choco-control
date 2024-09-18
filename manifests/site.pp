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

# Set chocolatey as default package provider on windows
if $facts['os']['family'] == 'windows' {
  Package {
    provider         => chocolatey,
    package_settings => {
      'verbose'    => true,
      'log_output' => true,
    },
    require          => Class['chocolatey'],
  }
}

## Node Definitions ##

node default {
  if $facts['os']['family'] == 'windows' {
    class { 'chocolatey':
      log_output             => true,
      choco_install_location => 'C:\Program Files\chocolatey',
      install_proxy          => 'http://172.31.64.151:3128',
      proxy_user             => 'atest',
      proxy_password         => Sensitive('testing'),
      #      ignore_proxy    => true,
    }

    package { ['notepadplusplus', 'firefox']:
      ensure => installed,
    }
  }
}
