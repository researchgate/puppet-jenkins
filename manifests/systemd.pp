# This class should be considered private
#
# This type handles setting up a systemd service
define jenkins::systemd(
  Any $user,
  Any $libdir,
) {
  assert_private()
  $service = $name

  include systemd

  $sysv_init = "/etc/init.d/${service}"

  file { "${libdir}/${service}-run":
    content => template("${module_name}/${service}-run.erb"),
    owner   => $user,
    mode    => '0700',
    notify  => Service[$service],
  }

  systemd::unit_file { "${service}.service":
    content => template("${module_name}/${service}.service.erb"),
    notify  => Service[$service],
    require => File[$sysv_init],
  }
}
