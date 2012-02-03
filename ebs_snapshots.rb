require "right_aws"
require "chef/encrypted_data_bag_item"

provides "ebs_snapshots"

# Load Chef client configuration
Chef::Config.from_file("/etc/chef/client.rb")

# RightAWS helpers
def aws
  @@aws ||= Chef::EncryptedDataBagItem.load("aws", "main")
end

def find_snapshot_id(volume_id)
  snapshot_id = nil

  ec2.describe_snapshots.sort { |a, b| b[:aws_started_at] <=> a[:aws_started_at] }.reverse_each do |snapshot|
    if snapshot[:aws_volume_id] == volume_id
      Chef::Log.debug("Snapshot for #{volume_id} is #{snapshot[:aws_volume_id]}")
      snapshot_id = snapshot[:aws_id]
    end
  end

  snapshot_id
end

def ec2
  region = instance_availability_zone
  region = region[0, region.length - 1]

  @@ec2 ||= RightAws::Ec2.new(aws["aws_access_key_id"], aws["aws_secret_access_key"], { :logger => Chef::Log, :region => region })
end

def instance_id
  instance_id = open("http://169.254.169.254/latest/meta-data/instance-id") { |f| f.gets }
  Chef::Log.debug("Instance ID is #{instance_id}")

  instance_id
end

def instance_availability_zone
  availability_zone = open("http://169.254.169.254/latest/meta-data/placement/availability-zone") { |f| f.gets }
  Chef::Log.debug("Instance availability zone is #{availability_zone}")

  availability_zone
end

if aws
  Chef::Log.debug("Loading plugin ebs_snapshots")

  # Get snapshot IDs for attached EBS volumes
  mapping = ec2.describe_instances([ instance_id ]).first[:block_device_mappings].map do |block_device_mapping|
    if block_device_mapping[:ebs_status] == "attached"
      recent_snapshot_id = find_snapshot_id(block_device_mapping[:ebs_volume_id])

      Chef::Log.debug("Most recent snapshot ID for #{block_device_mapping[:ebs_volume_id]} is #{recent_snapshot_id || "nil"}")

      {
        :volume_id    => block_device_mapping[:ebs_volume_id],
        :snapshot_id  => recent_snapshot_id
      }
    end
  end

  ebs_snapshots mapping
end
