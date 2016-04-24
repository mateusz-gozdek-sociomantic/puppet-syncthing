define syncthing::folder
(
  $home_path,
  $path,
  
  $ensure                = 'present',
  
  $id                    = $name,
  
  $ro                    = false,
  $rescanIntervalS       = '60',
  $ignorePerms           = false,

  $minDiskFreePct        = 1,
  $versioning            = '',
  $copiers               = 0,
  $pullers               = 0,
  $hashers               = 0,
  $order                 = 'random',
  $ignoreDelete          = false,
  $scanProgressIntervalS = 0,
  $pullerSleepS          = 0,
  $pullerPauseS          = 0,
  $maxConflicts          = -1,
  $disableSparseFiles    = false,

  # This is a hash containing pairs such as 'id' => 'absent/present'
  $devices          = {},
)
{
  if ! defined(Class['syncthing']) {
    fail('You must include the syncthing base class before using any syncthing defined resources')
  }
  
  $instance_config_xml_path = "${home_path}/config.xml"
  
  if $ensure == 'present' {
    $changes = [
      "set folder[#attribute/id='${id}']/#attribute/id '${id}'",
      "set folder[#attribute/id='${id}']/#attribute/path '${path}'",
      "set folder[#attribute/id='${id}']/#attribute/ro '${ro}'",
      "set folder[#attribute/id='${id}']/#attribute/rescanIntervalS '${rescanIntervalS}'",
      "set folder[#attribute/id='${id}']/#attribute/ignorePerms '${ignorePerms}'",
      "set folder[#attribute/id='${id}']/minDiskFreePct/#text '${minDiskFreePct}'",
      "set folder[#attribute/id='${id}']/versioning/#text '${versioning}'",
      "set folder[#attribute/id='${id}']/copiers/#text '${copiers}'",
      "set folder[#attribute/id='${id}']/pullers/#text '${pullers}'",
      "set folder[#attribute/id='${id}']/hashers/#text '${hashers}'",
      "set folder[#attribute/id='${id}']/order/#text '${order}'",
      "set folder[#attribute/id='${id}']/ignoreDelete/#text '${ignoreDelete}'",
      "set folder[#attribute/id='${id}']/scanProgressIntervalS/#text '${scanProgressIntervalS}'",
      "set folder[#attribute/id='${id}']/pullerSleepS/#text '${pullerSleepS}'",
      "set folder[#attribute/id='${id}']/pullerPauseS/#text '${pullerPauseS}'",
      "set folder[#attribute/id='${id}']/maxConflicts/#text '${maxConflicts}'",
      "set folder[#attribute/id='${id}']/disableSparseFIles/#text '${disableSparseFiles}'",
    ]
  } else {
    $changes = "rm folder[#attribute/id='${id}']"
  }

  augeas { "configure instance ${home_path} folder ${id}":
    incl    => $instance_config_xml_path,
    lens    => 'Xml.lns',
    context => "/files${instance_config_xml_path}/configuration",
    changes => $changes,
    
    notify  => [
      Service['syncthing'],
    ],
    
    require => [
      Class['syncthing'],
    ],
  }
}
