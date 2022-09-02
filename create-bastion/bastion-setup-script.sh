- create bastion host with cft template with redhat_test key with ROL attached

## USER DATA for ec2 instance
## - download awscli, curl, unzip, and ansible on bastion
sudo apt update
sudo apt install curl unzip ansible git -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
export PATH=/usr/local/bin:$PATH
echo "export PATH=/usr/local/bin:$PATH" >> .bashrc
rm -rf aws
rm -rf awscliv2.zip
git clone https://github.com/philgladman/rke2-automation.git
aws ec2 describe-key-pairs --key-names bastion_key --include-public-key --query "KeyPairs[].PublicKey" --output text --region us-east-1 >  ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

### get BASTION public IP, and both keys into a variable
export BASTION_PUBLIC_IP=$(aws ec2 describe-instances --query "Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp" --filters Name=tag:Name,Values=bastion-host --output text --region us-east-1)
export LOCAl_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/redhat_test.pem
export BASTION_KEY=/Users/Philgladman/Desktop/phils-scripts/phils-scripts/07-07-2022/aws-redhat-test/bastion_key.pem
## run this command on mac to make sure state is ready
## create for loop to keep proping until output is ready
aws ec2 describe-instances --filters Name=tag:Name,Values=bastion-host --query "Reservations[].Instances[].State[].Name" --output text --region us-east-1
## run this command on mac to transfer bastion private key from mac to bastion
scp -i $LOCAl_KEY $BASTION_KEY ubuntu@$BASTION_PUBLIC_IP:/home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=no

### END