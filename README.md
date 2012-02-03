# Ohai Plugins for Chef #

This repository contains custom Ohai plugins for use with Opscode Chef.

## Distribution ##

It is recommended that you add custom Ohai plugins to the Ohai
[cookbook](https://github.com/opscode/cookbooks/tree/master/ohai)
in `cookbooks/ohai/files/default/plugins`.

## Plugins ##

### EBS Snapshots ###

The purpose of this plugin is to populate node attributes with the most
recent snapshot IDs of currently attached EBS volumes.

This plugin makes use of the `right_aws` gem &mdash; similar to the AWS
[cookbook](https://github.com/opscode/cookbooks/tree/master/aws).  In
order to ensure that `right_aws` is installed before the plugin, the
following should be added to the default recipe of the Ohai cookbook:

    r = gem_package "right_aws" do
      version "2.1.0"
      action :nothing
    end

    r.run_action(:install)

Example output:

    "ebs_snapshots": [
      {
        "volume_id": "vol-a59e6fc9",
        "snapshot_id": null
      },
      {
        "volume_id": "vol-2d8c7d41",
        "snapshot_id": "snap-f62edc91"
      },
      {
        "volume_id": "vol-358c7d59",
        "snapshot_id": "snap-102edc77"
      },
      {
        "volume_id": "vol-ed8c7d81",
        "snapshot_id": "snap-0e2edc69"
      },
      {
        "volume_id": "vol-b38e7fdf",
        "snapshot_id": "snap-382edc5f"
      }
    ]
