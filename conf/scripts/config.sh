#!/bin/bash

export AWS_DEFAULT_REGION=eu-west-1

readonly AMI_UBUNTU_EBS=ami-cda130ba        # ubuntu 14.04, 64bit, ebs root
readonly AMI_UBUNTU_INSTANCE=ami-3b69b84c   # ubuntu 14.04, 64bit, instance root
readonly AMI_UBUNTU_HVM=ami-c5bf2eb2        # ubuntu 14.04, 64bit, HVM (for use with t2)
readonly SG_BACK_END=sg-761ac813            # security group for lds-back-end
readonly SG_FRONT_END=sg-b815c7dd           # security group for lds-front-end
readonly VPC_PUBLIC_B=subnet-5b73601d       # public subnet for LDS VPC
readonly VPC_PUBLIC_C=subnet-345c8d51       # public subnet for LDS VPC
readonly VPC_PUBLIC=( $VPC_PUBLIC_B $VPC_PUBLIC_C )

readonly NRC_HOST=127.0.0.1                 # Nagrestconf, normally on DMS controller machine

export SSH_FLAGS="-q -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

readonly S3_STATE="s3://dms-deploy/dms-state"
