## iam group 정책
data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"  ## 우선 팀원이 모든 작업 할 수 있도록 AdministratorAccess
}

## iam group 정책을 그룹에 부여
resource "aws_iam_group_policy_attachment" "administrators01" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

resource "aws_iam_group_policy_attachment" "administrators02" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.amazon_eks_worker_node_policy.arn
}

resource "aws_iam_group_policy_attachment" "administrators03" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.aws_load_balancer_controller_iam_policy.arn
}

resource "aws_iam_group_policy_attachment" "administrators04" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.eks_all_access.arn
}

resource "aws_iam_group_policy_attachment" "administrators05" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.iam_full_access.arn
}

resource "aws_iam_group_policy_attachment" "administrators06" {
  group      = aws_iam_group.hairpin_admin.name
  policy_arn = data.aws_iam_policy.iam_user_change_password.arn
}