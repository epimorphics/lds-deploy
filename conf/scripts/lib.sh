#!/bin/bash
# Library of utilities used in DMS automation

## Note for ssh operations the SSH flags are specified externally in config.sh

# Wait until an aws operation reaches a target state
# WaitFor $command $jqpattern $target
WaitFor() {
	[[ $# = 3 ]] || { echo "Internal error calling wait-for" 1>&2 ; exit 99 ; }
	local cmd=$1
	local pattern=$2
	local target=$3
	local loop=1
	while [[ $loop -le 300 ]]
	do
		STATE=`$cmd | jq -r $pattern`
		echo "State is: $STATE"
		if [[ $STATE == $target ]]; then
			return 0
		fi
		sleep 3
		loop=$(( $loop + 1 ))
	done
	return 1
}

# Check required programs are installed
CheckInstalls() {
	command -v aws >/dev/null 2>&1 || { echo >&2 "Need aws installed: http://aws.amazon.com/cli/.  Aborting."; exit 1; }
	command -v jq >/dev/null 2>&1 || { echo >&2 "Need jq installed: http://stedolan.github.io/jq/download/.  Aborting."; exit 1; }
}

# Pick a random availability zone - not used in a VPC setting, pick subnet instead
PickZone() {
	aws ec2 describe-availability-zones --filters Name=state,Values=available | jq -r ".AvailabilityZones[$(( $RANDOM % 3 ))].ZoneName"
}

# Shell based provisioning, syncs source area then roots bootstrap.sh script
# ShellProvision $serverDir $sourceDir
ShellProvision() {
	[[ $# = 2 ]] || { echo "Internal error calling ShellProvision" 1>&2 ; exit 99 ; }
	local server=$1
	local source=$2
	local IP=$(jq -r ".Instances[0].PublicDnsName" < $server/aws-instance.json)

	echo " - syncing provisioning data"
	rsync -avz -e "ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"  --rsync-path="sudo rsync" $source "ubuntu@$IP:/dmsprovision/"
	echo " - running provisioning script"
	ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP "sudo sh /dmsprovision/bootstrap.sh"
}

# Wait for ssh connection to become available on the aws instance
#    WaitForSsh  $serverDir
WaitForSsh() {
	[[ $# = 1 ]] || { echo "Internal error calling WaitForSsh" 1>&2 ; exit 99 ; }
	local server=$1
	local IP=$(jq -r ".Instances[0].PublicDnsName" < $server/aws-instance.json)
	local loop=1
	while [[ $loop -le 10 ]]
	do
		if ssh $SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem -l ubuntu $IP  "echo ssh up"; then
			return 0
		fi
		sleep 8
		loop=$(( $loop + 1 ))
	done
	echo "ssh access to instance failed" 1>&2
	return 1
}

# Compute AWS block-device-mappings from environment variables 
#     AWS_INSTANCE_STORE (yes or missing)
#     AWS_EBS (size in Gb)
BlockDeviceMappings() {
	local MAPPING=""
	if [[ $AWS_INSTANCE_STORE == "yes" ]] ; then
		MAPPING='{"DeviceName":"/dev/sdg","VirtualName":"ephemeral0"}'
	fi
	if [[ $AWS_EBS ]] ; then
		local EBS_MAPPING="{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":$AWS_EBS,\"DeleteOnTermination\":false,\"VolumeType\":\"gp2\"}}"
		if [[ -z $MAPPING ]] ; then
			MAPPING="--block-device-mappings [$EBS_MAPPING]"
		else
			MAPPING="--block-device-mappings [$MAPPING,$EBS_MAPPING]"
		fi
	fi
	echo $MAPPING
}

# Allocate and AWS server and bootstrap it
# Arguments:
#    AllocateServer infoDir
# Environment settings:
#    NAME                     short name for the server
#    FULL_NAME                full, unique name for the server
#    AWS_INSTANCE_TYPE        instance type to create
#    AWS_AMI                  AMI to use
#    AWS_SG                   security group(s)
#    AWS_INSTANCE_STORE=yes   allocate an instance store to ephemeral0
#    AWS_EBS=10               allocate an EBS of the given size 
#    AWS_IAM_ROLE_ARN         optional IAM role
#    AWS_IAM_ROLE_NAME        optional IAM role


AllocateServer() {
	[[ $# = 1 ]] || { echo "Internal error calling AllocateServer" 1>&2 ; exit 1 ; }
    local serverDir=$1

	# Check if there is already an allocated server here
	if [[ -f $serverDir/aws-instance.json ]]; then
		echo "Server already exists, assuming this is a retry and continuing to wait for server to be ready"
		instanceID=$( jq -r '.Instances[0].InstanceId' < $serverDir/aws-instance.json )
	else
        # Start the instance
        local VPC="${VPC_PUBLIC[ $RANDOM % 2 ]}"

        local BD=$(BlockDeviceMappings)

        [[ $BD ]] && echo "Using block device mappings: $BD"

        local iamRole=""
        if [[ -n $AWS_IAM_ROLE_ARN ]] ; then
#        	iamRole="--iam-instance-profile Arn=$AWS_IAM_ROLE_ARN,Name=$AWS_IAM_ROLE_NAME"
        	iamRole="--iam-instance-profile Arn=$AWS_IAM_ROLE_ARN"
        	echo "Assigning IAM role $iamRole"
        fi

        aws ec2 run-instances --count 1 \
        --image-id "$AWS_AMI" \
        --instance-type "$AWS_INSTANCE_TYPE" \
        --security-group-ids $AWS_SG \
        --key-name "lds" \
        --associate-public-ip-address \
        --subnet-id "$VPC" \
        $iamRole \
        $BD > $serverDir/aws-instance.json

        instanceID=$( jq -r '.Instances[0].InstanceId' < $serverDir/aws-instance.json )
        echo "Creating instance $instanceID"
    fi

	# Wait for the instance to be up
	WaitFor "aws ec2 describe-instances --instance-ids $instanceID" ".Reservations[0].Instances[0].State.Name" "running" || { echo "Instance startup failed"; exit 1; }

	# Name it
	aws ec2 create-tags --resources $instanceID --tags "Key=Name,Value=$FULL_NAME" > /dev/null

	# Record up state of server and extract IP address for DMS use
	aws ec2 describe-instances --instance-ids $instanceID | jq .Reservations[0] > $serverDir/aws-instance.json

	#jq  "{ address: .Instances[0].PrivateIpAddress, private: .Instances[0].PrivateIpAddress, public: .Instances[0].PublicDnsName }" < $serverDir/aws-instance.json > $serverDir/config.json
	# WARNING: This is a temporary hack to allow test access to machines in public
	jq  "{ address: .Instances[0].PublicDnsName, private: .Instances[0].PrivateIpAddress, public: .Instances[0].PublicDnsName, name: \"$FULL_NAME\" }" < $serverDir/aws-instance.json > $serverDir/config.json

	# Label the attached storage - if any
	jq -r '.Instances[0].BlockDeviceMappings[].Ebs.VolumeId' < $serverDir/aws-instance.json | xargs aws ec2 create-tags --tags "Key=Name,Value=disk-$FULL_NAME"  --resources > /dev/null

	# Format the disk if necessary
	WaitForSsh $serverDir
	ShellProvision $serverDir provision/base/	
}

# Configure Chef on a newly allocated machines
# Arguments:
#    InstallChef infoDir
# Environment settings:
#    NAME                     short name for the server
#    FULL_NAME                full, unique name for the server
#    CHEF_ROLE  name of the top level role for this instance
InstallChef() {
	[[ $# = 1 ]] || { echo "Internal error calling AllocateServer" 1>&2 ; exit 1 ; }
    local serverDir=$1

	IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)
	knife bootstrap -c /var/opt/dms/.chef/knife.rb -i /var/opt/dms/.ssh/lds.pem -x ubuntu --sudo \
                -E dms-test -r "$CHEF_ROLE" \
                -j "{\"epi_server_base\":{\"system_name\":\"$FULL_NAME\"}}" \
                -N $FULL_NAME "$IP" -F min --no-color
}

# Configure Chef Solo on a newly allocated machine
# Arguments:
#    InstallChefSolo infoDir chefDir
# Environment settings:
#    NAME                     short name for the server
#    FULL_NAME                full, unique name for the server
#    CHEF_ROLE  name of the top level role for this instance
InstallChefSolo() {
	[[ $# = 2 ]] || { echo "Internal error calling AllocateServer" 1>&2 ; exit 1 ; }
    local serverDir=$1
    local chefDir=$2

    IP=$(jq -r ".Instances[0].PublicDnsName" < $serverDir/aws-instance.json)
    knife solo prepare "ubuntu@$IP" -N "$FULL_NAME" --identity-file /var/opt/dms/.ssh/lds.pem --yes  --no-color
    mv nodes/$FULL_NAME.json $serverDir/node-orig.json

	# Set up node file to correspond to a single top level role
	cat > $serverDir/node.json <<!!
{
    "run_list" : [ "role[$CHEF_ROLE]" ],
    "automatic" : { "ipaddress" : "$IP" },
    "epi_server_base": {
        "system_name": "$FULL_NAME"
    }
}
!!
}
