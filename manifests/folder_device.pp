define syncthing::folder_device
(
  $home_path,

  $folder_id,
  $device_id,

  $ensure           = 'present',
)
{
  if ! defined(Class['syncthing']) {
    fail('You must include the syncthing base class before using any syncthing defined resources')
  }

  $instance_config_xml_path = "${home_path}/config.xml"

  Augeas {
    incl    => $instance_config_xml_path,
    lens    => 'Xml.lns',
    context => "/files${instance_config_xml_path}/configuration",
    notify  => [
      Service['syncthing'],
    ],

    require => [
      Class['syncthing'],
    ],
  }

  if $ensure == 'present' {

    # Add first element with top padding
    augeas { "share ${folder_id} with device ${device_id} in instance ${home_path}":
      changes => [
        "set folder[#attribute/id='${folder_id}']/#text[1] '\n        '",
        "ins device after folder[#attribute/id='${folder_id}']/#text[last()]",
        "set folder[#attribute/id='${folder_id}']/device[last()]/#attribute/id '${device_id}'",
        "ins #text after folder[#attribute/id='${folder_id}']/device[last()]",
        "set folder[#attribute/id='${folder_id}']/device[last()]/following-sibling::#text[1] '\n        '",
      ],
      onlyif => "match folder[#attribute/id='${folder_id}']/device size == 0",
    }

    # Add additional element
    augeas { "share ${folder_id} additionally with device ${device_id} in instance ${home_path}":
      changes => [
        "ins device after folder[#attribute/id='${folder_id}']/device[last()]",
        "set folder[#attribute/id='${folder_id}']/device[last()]/#attribute/id '${device_id}'",
        "ins #text before folder[#attribute/id='${folder_id}']/device[last()]",
        "set folder[#attribute/id='${folder_id}']/device[last()]/preceding-sibling::#text[1] '        '",
      ],
      onlyif => "match folder[#attribute/id='${folder_id}']/device[#attribute/id='${device_id}'] size == 0",
      require => Augeas["share ${folder_id} with device ${device_id} in instance ${home_path}"],
    }

    # Set up proper bottom padding
    augeas { "create bottom padding for share ${folder_id} for device ${device_id} in instance ${home_path}":
      changes => [
        "set folder[#attribute/id='${folder_id}']/#text[last()] '    '",
      ],
      onlyif => "match folder[#attribute/id='${folder_id}']/device size > 0",
      require => Augeas["share ${folder_id} additionally with device ${device_id} in instance ${home_path}"],
    }

  } else {

    # Remove element
    augeas { "unshare ${folder_id} with device ${device_id} in instance ${home_path}":
      changes => [
      "rm folder[#attribute/id='${folder_id}']/device[#attribute/id='${device_id}']/following-sibling::#text[1]",
      "rm folder[#attribute/id='${folder_id}']/device[#attribute/id='${device_id}']",
      ],
    }

    # Remove all paddings if there is no more address element
    augeas { "remove padding for device ${device_id} in instance ${home_path}":
      changes => "rm device[#attribute/id='${device_id}']/#text",
      onlyif  => "match device[#attribute/id='${device_id}']/address size == 0",
      require => Augeas["create bottom padding for sharing ${folder_id} for device ${device_id} in instance ${home_path}"],
    }

    # Set up prosper bottom padding after removing element
    augeas { "create bottom padding for sharing ${folder_id} for device ${device_id} in instance ${home_path}":
      changes => [
        "set folder[#attribute/id='${folder_id}']/#text[last()] '    '",
      ],
      onlyif => "match device[#attribute/id='${device_id}']/address size > 0",
      require => Augeas["unshare ${folder_id} with device ${device_id} in instance ${home_path}"],
    }

  }

}
