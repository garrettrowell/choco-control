# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   atest::s3get_archive { 'namevar': }
define atest::s3get_archive (
  Enum['absent','present'] $ensure = 'present',
  String[1] $bucket_name = undef,
  String[1] $bucket_file = undef,
  Stdlib::Absolutepath $local_file_location = undef,
) {
  archive { $title:
    ensure => $ensure,
    source => "s3://${bucket_name}/${bucket_file}",
    path   => $local_file_location,
  }
}
