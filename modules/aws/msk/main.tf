data "aws_caller_identity" "current" {}

resource "aws_kms_key" "kms" {
  description         = "Key for ${var.msk_cluster_name}-${var.cluster_name}"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# Create MSK configuration with proper naming to avoid conflicts
resource "aws_msk_configuration" "msk_config" {
  kafka_versions = [var.kafka_version]
  name           = "${var.msk_cluster_name}-config"
  
  server_properties = <<PROPERTIES
log.retention.hours=${var.msk_log_retention_hours}
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.partitions=3
PROPERTIES

  description = "MSK configuration for ${var.msk_cluster_name} with ${var.msk_log_retention_hours}h retention"
}

module "msk_cluster" {
  source = "terraform-aws-modules/msk-kafka-cluster/aws"

  # Ensure configuration is created before cluster
  depends_on = [aws_msk_configuration.msk_config]

  name                   = "${var.msk_cluster_name}-${var.cluster_name}"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.msk_number_of_broker_nodes

  broker_node_client_subnets = var.private_subnets
  broker_node_storage_info = {
    ebs_storage_info = { volume_size = var.msk_node_volume_size }
  }
  broker_node_instance_type      = var.broker_node_instance_type
  broker_node_security_groups    = [var.msk_sg_id]
  encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn

  encryption_in_transit_client_broker = "TLS"
  encryption_in_transit_in_cluster    = true

  client_authentication = {
    sasl = {
      scram = false
    }
    unauthenticated = true
  }

  # Use the configuration we created above
  configuration_arn      = aws_msk_configuration.msk_config.arn
  configuration_revision = aws_msk_configuration.msk_config.latest_revision

  tags = var.tags
}