#!/bin/bash

# aws-cli install
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /root/awscliv2.zip
unzip /root/awscliv2.zip -d /root/AWS
sudo /root/AWS/aws/install

sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# kubectl install
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
echo 'export PATH=$HOME/bin:$PATH' >> /home/ec2-user/.bashrc
sudo yum install -y bash-completion
echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc # kubectl 명령어를 k 로 사용할 수 있도록 약어 설정
echo 'complete -o default -F __start_kubectl k' >> /home/ec2-user/.bashrc

# eksctl install
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
echo '. <(eksctl completion bash)' >> /home/ec2-user/.bashrc
