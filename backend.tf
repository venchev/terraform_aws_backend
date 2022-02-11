# This module will create S3 bucket and will use it as TF backend.
# ----------------------------------------------------------------

# Creation of S3 bucket encryption key
resource "aws_kms_key" "terraform-bucket-key" {
 description             = "This key is used to encrypt bucket objects"
 deletion_window_in_days = 10
 enable_key_rotation     = true
}

resource "aws_kms_alias" "key-alias" {
 name          = "alias/terraform-bucket-key"
 target_key_id = aws_kms_key.terraform-bucket-key.key_id
}


# Creation of S3 bucket with versioning enabled.

resource "aws_s3_bucket" "radi-tf-state" {
  bucket = var.bucket
  acl    = var.acl

versioning {
    enabled = true
  }

# Activation of the encryption.

  server_side_encryption_configuration {
   rule {
     apply_server_side_encryption_by_default {
       kms_master_key_id = aws_kms_key.terraform-bucket-key.arn
       sse_algorithm     = "aws:kms"
     }
   }
 }


}
# Public access block.
resource "aws_s3_bucket_public_access_block" "block" {
 bucket = aws_s3_bucket.radi-tf-state.id

 block_public_acls       = true
 block_public_policy     = true
 ignore_public_acls      = true
 restrict_public_buckets = true
}

# Preventing two team members to write in the state file 
# at the same time, using locks.

resource "aws_dynamodb_table" "terraform-state" {
 name           = "terraform-state"
 read_capacity  = 20
 write_capacity = 20
 hash_key       = "LockID"

 attribute {
   name = "LockID"
   type = "S"
 }
}


# Initializing the backend.
# The name of the bucket must be hardcoded.
# Once created, there will be initialized backend
# with versioning and locks of tfstat files.
# In order to be deleted, must be emptied first
# from the AWS console.

terraform {
 backend "s3" {
   bucket         = "radi-tf-state"
   key            = "state/terraform.tfstate"
   region         = "eu-west-3"
   encrypt        = true
   kms_key_id     = "alias/terraform-bucket-key"
   dynamodb_table = "terraform-state"
 }
}

