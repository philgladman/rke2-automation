#!/bin/bash
## This script is to be run on local mac
### put file location of stack into variable
export STACK_FILE_LOCATION=/Users/Philgladman/Desktop/DevOps/rke2-automation/create-ec2-instances/create-bastion-user-data.yml

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
    if ["$output" -ne "running"]
    then
        # ec2 instance is not yet running - failure - rerun aws command:
        echo "bastion instance is not yet running, waiting for stack to complete..."
        sleep 3s
        aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output text > ~/tmp-script-output.json
    else
        # file has output - success - leave the loop:
        echo "cloudformation stack creation complete and bastion is running"
        # aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output json > ~/script-output.json
        rm ~/tmp-script-output.json
        break
    fi
done

### get BASTION public IP, and both keys into a variable
export BASTION_PUBLIC_IP=$(aws ec2 describe-instances --query "Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp" --filters Name=tag:Name,Values=bastion-host --output text --region us-east-1)
export LOCAL_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/redhat_test.pem
export BASTION_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/bastion_key.pem

## run this command on mac to transfer bastion private key from mac to bastion
scp -i $LOCAL_KEY $BASTION_KEY ubuntu@$BASTION_PUBLIC_IP:~/.ssh/id_rsa -o StrictHostKeyChecking=no

### END