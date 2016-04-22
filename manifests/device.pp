# Resource: syncthing::device
#
# This resource adds device entry to config.xml
define syncthing::device
(
  $home_path,
  $id,

  $ensure         = 'present',

  $device_name    = $name,
  $compression    = $::syncthing::device_compression,
  $introducer     = $::syncthing::device_introducer,
  $address        = 'dynamic',

  $options        = $::syncthing::device_options,
)
{
  if ! defined(Class['syncthing']) {
    fail('You must include the syncthing base class before using any syncthing defined resources')
  }

  validate_re($compression, '^(metadata|always|never)$')

  $instance_config_xml_path = "${home_path}/config.xml"

  if $ensure == 'present' {
    $changes = [
      # Insert new #text node after last device
      "ins #text after device[last()]",
      # Set content of added #text node to '\t'
      "set device[last()]/following-sibling::#text[1] '\t'",
      # Insert new device node after last added #text node
      "ins device after device[last()]/following-sibling::#text[1]",
      # Set newly added device id to ${id}
      "set device[last()]/#attribute/id '${id}'",
      "set device[#attribute/id='${id}']/#attribute/name '${device_name}'",
      "set device[#attribute/id='${id}']/#attribute/compression '${compression}'",
      "set device[#attribute/id='${id}']/#attribute/introducer '${introducer}'",
    ]
  } else {
    $changes = [
      "rm device[#attribute/id='2']/preceding-sibling::#text[1]",
      "rm device[#attribute/id='2']",
    ]
  }

  augeas { "configure instance ${home_path} device ${id}":
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

  if ! defined(Syncthing::Address[$address]) {
    ::syncthing::address{ $address:
      home_path => $home_path,
      device_id => $id,
      require   => Augeas["configure instance ${home_path} device ${id}"],
    }
  }

}
