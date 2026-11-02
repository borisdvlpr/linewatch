locals {
  prefix              = "studies/${var.study_id}/"
  bucket_name         = element(split(":", var.bucket_arn), 5)
  data_classification = coalesce(var.data_classification, var.classification)
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.analyst_arns
    }
  }
}

resource "aws_iam_role" "workspace" {
  name               = "${var.name_prefix}-study-${var.study_id}"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    Study              = var.study_id
    DataClassification = local.data_classification
  }
}

# The study's analysts see and change only objects under its own prefix.
data "aws_iam_policy_document" "workspace" {
  statement {
    sid       = "ListStudyPrefix"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.prefix}*"]
    }
  }

  statement {
    sid       = "ReadWriteStudyObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.bucket_arn}/${local.prefix}*"]
  }
}

resource "aws_iam_role_policy" "workspace" {
  name   = "study-workspace"
  role   = aws_iam_role.workspace.id
  policy = data.aws_iam_policy_document.workspace.json
}
