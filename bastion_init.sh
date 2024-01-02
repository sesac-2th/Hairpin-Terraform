#!/bin/bash
# aws-cli install
if which aws >/dev/null; then
	echo "aws cli already installed"
else
	curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /root/awscliv2.zip
    unzip /root/awscliv2.zip -d /root/AWS
    sudo /root/AWS/aws/install
fi

# kubectl install
if which kubectl >/dev/null; then
	echo "kubectl already installed"
else
	curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
    echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    sudo yum install -y bash-completion-extras
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'alias k=kubectl' >> ~/.bashrc # kubectl 명령어를 k 로 사용할 수 있도록 약어 설정
    echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
    exec bash
    echo 'source ~/.bashrc' >> /etc/bash.bashrc
fi

# eksctl install
if which eksctl >/dev/null; then
	echo "eksctl already installed"
else
	ARCH=amd64
    PLATFORM=$(uname -s)_$ARCH
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
    sudo mv /tmp/eksctl /usr/local/bin
    . <(eksctl completion bash)
fi

