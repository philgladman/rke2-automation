#!/bin/bash
## This script is to be run on local mac
## need local key to ssh into bastion
## need bastion key used for bastion to ssh into cluster nodes
## need to update rke2-automation/create-bastion/create-bastion-user-data.yml with your AWS accounts data

## get stack file location
echo "Enter file path for the stack to create bastion host: "
echo "default = /Users/Philgladman/Desktop/DevOps/rke2-automation/create-bastion/create-bastion-user-data.yml"
read -p "file location [press enter for default] : " STACK_FILE_LOCATION
STACK_FILE_LOCATION=${STACK_FILE_LOCATION:-/Users/Philgladman/Desktop/DevOps/rke2-automation/create-bastion/create-bastion-user-data.yml}

## Get stack name
while true # infinite loop
do
    read -p "Enter stack name: " STACK_NAME
    if [ -z "$STACK_NAME" ]
    then
        echo "Forgot to provide stack name" # output is empty - failure
    else
        break # file has output - success
    fi
done

### create cloudformation stack
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$STACK_FILE_LOCATION --region us-east-1

### show progress bar that takes 30 seconds
{
    echo -n "["
    for ((i = 0 ; i <= 60; i+=2)); do
        sleep .5
        echo -n "###"
    done
    echo -n "]"
    echo
}

### check to see if outputs are available and put into file
aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output text > ~/tmp-script-output.json

### check to see if outputs file is empty, if so then then run loop until there are outputs and put in file
while true # infinite loop
do
    output=$( cat ~/tmp-script-output.json )
    if [ -z "$output" ]
    then
        # output is empty - failure - rerun aws command:
        echo "cloudformation stack outputs are empty, waiting for stack to complete..."
        sleep 3s
        aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output text > ~/tmp-script-output.json
    else
        # file has output - success - leave the loop:
        echo "cloudformation stack creation complete"
        rm ~/tmp-script-output.json
        break
    fi
done

### get BASTION public IP, and both keys into a variable
export BASTION_PUBLIC_IP=$(aws ec2 describe-instances --query "Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp" --filters Name=tag:Name,Values=bastion-host --output text --region us-east-1)
# export LOCAL_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/redhat_test.pem
# export BASTION_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/bastion_key.pem

## Get location of local key
echo "Enter file path for the local SSH key: "
echo "default = /Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/redhat_test.pem"
read -p "file location [press enter for default] : " LOCAL_KEY
LOCAL_KEY=${LOCAL_KEY:-/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/redhat_test.pem}

## Get location of local key
echo "Enter file path bastion key to be copied over to bastion: "
echo "default = /Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/bastion_key.pem"
read -p "file location [press enter for default] : " BASTION_KEY
BASTION_KEY=${BASTION_KEY:-/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/bastion_key.pem}

## run this command on mac to transfer bastion private key from mac to bastion
while true # infinite loop
do
    scp -i $LOCAL_KEY -o StrictHostKeyChecking=no $BASTION_KEY ubuntu@$BASTION_PUBLIC_IP:~/.ssh/id_rsa 
    RESULT=$?
    if [ $RESULT -eq 0 ];
    then
        # SUCCESS
        echo " "
        echo "bastion key transfer Success"
        break
    else
        # FAIL
        echo "ERROR ! key transfer FAILED... trying again"
        sleep 2s
    fi
done

## Command to ssh into bastion
echo " "
echo "#### Copy and past command below to ssh into bastion ####"
echo " "
echo "ssh -i $LOCAL_KEY ubuntu@$BASTION_PUBLIC_IP"
echo " "
### END