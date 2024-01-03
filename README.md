# Hairpin-Terraform

eks cluster 에 public access 불가로 같은 VPC 내에 bastion host 를 생성하여 접속해야 함

</br>

## 1. aws network 생성
`cd base`

`terrafrom init`

`terraform apply [--auto-approve]` # [optional] -> _yes_ 자동 승인

</br>

## 2. aws bastion ec2 생성
`cd bastion`

`terraform init`

`terraform plan`

`terraform apply [--auto-approve]` # [optional] -> _yes_ 자동 승인

</br>

## 3. aws eks, eks addon, efs, s3, acm 생성

### bastion host 접속

`cd /bastion/keypair`

`ssh -i [keyname].pem ec2-user@[ec2-dns]`

</br>

### terraform 코드 다운

`git clone https://github.com/sesac-2th/Hairpin-Terraform.git`

`cd Hairpin-Terraform`

`git switch dev`

_main.tf 에는 bastion host 가 eks 에 접근하기 위해 eks 관련 보안 그룹을 붙여주는 리소스 블록도 존재함_


`terraform init`

`terraform plan`

`terraform apply [--auto-approve]` # [optional] -> _yes_ 자동 승인