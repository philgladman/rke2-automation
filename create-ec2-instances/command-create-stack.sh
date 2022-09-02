#!/bin/bash
#export STACK_NAME=test01
#aws cloudformation create-stack --stack-name $STACK_NAME --template-body file:///Users/Philgladman/Desktop/DevOps/cloudformation/create-cluster.yml --region us-east-1

### Query aws for the bastions private IP address and output into the ansible group_vars/all file
echo bastion_ipaddress: $(aws ec2 describe-instances --region us-east-1 --query "Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddress" --filters Name=tag:Name,Values=bastion-host --output text) >> ~/rke2-automation/ansible-rke2/group_vars/all

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

### create cloudformation  stack
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://~/rke2-automation/create-ec2-instances/create-cluster.yml --region us-east-1

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
aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output text > ~/rke2-automation/create-ec2-instances/tmp-script-output.json

### check to see if outputs file is empty, if so then then run loop until there are outputs and put in file
while true # infinite loop
do
    output=$( cat ~/rke2-automation/create-ec2-instances/tmp-script-output.json )
    if [ -z "$output" ]
    then
        # output is empty - failure - rerun aws command:
        echo "cloudformation stack outputs are empty, waiting for stack to complete..."
        sleep 3s
        aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output text > ~/rke2-automation/create-ec2-instances/tmp-script-output.json
    else
        # file has output - success - leave the loop:
        echo "cloudformation stack creation complete"
        aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[].Outputs[].[OutputKey,OutputValue]" --region us-east-1 --output json > ~/rke2-automation/create-ec2-instances/script-output.json
        rm ~/rke2-automation/create-ec2-instances/tmp-script-output.json
        break
    fi
done

### run python script to take output file and format to ansible variables file
python3 ~/rke2-automation/create-ec2-instances/script-1.py

rm -f ~/rke2-automation/create-ec2-instances/script-output.json

### ansible readiness probe to see if nodes are ready to ssh

while true # infinite loop
do
    ansible -m ping all -i ~/rke2-automation/ansible-rke2/inventory.txt  
    RESULT=$?
    if [ $RESULT -eq 0 ];
    then
        # SUCCESS
        echo "Success, all nodes are ready"
        break
    else
        # FAIL
        echo "FAILURE, one or more nodes are not yet ready... Trying agin"
        sleep 2s
    fi
done

# run ansible playbook on bastion to update hostnames
ansible-playbook -i /home/ubuntu/rke2-automation/ansible-rke2/inventory.txt /home/ubuntu/rke2-automation/ansible-rke2/update-hostnames.yml

# run ansible playbook to install RKE2 on all nodes
ansible-playbook -i /home/ubuntu/rke2-automation/ansible-rke2/inventory.txt /home/ubuntu/rke2-automation/ansible-rke2/install-rke2-bastion.yml