resource "aws_iam_role_policy" "certbot" {
  name   = "certbot"
  role   = module.ec2.instance_role_name
  policy = data.aws_iam_policy_document.certbot.json
}
