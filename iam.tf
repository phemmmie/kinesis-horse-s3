
data "aws_iam_policy_document" "source_stream_read_access" {
  statement {
    actions = [
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesis:SubscribeToShard"
      
    ]
   resources = [
      "${aws_kinesis_stream.eu-source-stream.arn}"
   ]
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}





# Roles
resource "aws_iam_role" "firehose_service" {
  name = "data-ingest-firehose-${var.app_name}"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}


resource "aws_iam_role_policy" "inline-policy" {
  name   = "${var.app_name}_firehose_inline_policy"
  role   = "${aws_iam_role.firehose_service.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.eu-mapped_bucket.arn}",
        "${aws_s3_bucket.eu-mapped_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords"
      ],
      "Resource": "${aws_kinesis_stream.eu-source-stream.arn}"
    }
  ]
}
EOF
}



# stream access policies
# resource "aws_iam_role_policy_attachment" "firehose_from_kinesis" {
#   role = aws_iam_role.firehose_service.name
#   policy_arn = aws_iam_policy.firehose_service.arn
# }
