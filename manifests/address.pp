# Resource: syncthing::address
#
# This resource adds address entry to specified device in config.xml
define syncthing::address
(
  $home_path,
  $device_id,

  $ensure = 'present',
)
{
  if ! defined(Class['syncthing']) {
    fail('You must include the syncthing base class before using any syncthing defined resources')
  }

  $instance_config_xml_path = "${home_path}/config.xml"

  if $ensure == 'present' {
    $changes = [
      # Make sure, that first element is '\n\t\t'
      "set device[#attribute/id='${device_id}']/#text[1] '\n\t\t'",
      # Create new address
      "set device[#attribute/id='${device_id}']/address[last()+1]/#text '${title}'",
      # Insert new #text element after last address
      "ins #text after device[#attribute/id='${device_id}']/address[last()]",
      # For every #text after address, set value to '\t\t'
      "set device[#attribute/id='${device_id}']/address/following-sibling::#text[1] '\t\t'",
      # Make sure, that last element is '\t'
      "set device[#attribute/id='${device_id}']/#text[last()] '\t'",
    ]
  } else {
   $changes = [
      # This line currently does not work. It should remove first text entry when there is no more address syblings
      #"rm /files/tmp/config.xml/configuration/device[#attribute/id='2']/address[#text='foo']/following-sibling::#text[1]",
      "rm device[#attribute/id='${device_id}']/address[#text='${title}']/preceding-sibling::#text[last()]",
      "rm device[#attribute/id='${device_id}']/address[#text='${title}']",
   ]
  }

  augeas { "configure address ${title} for device ${device_id}":
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
