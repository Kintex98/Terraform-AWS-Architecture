data "archive_file" "codedeploy_files" {
  for_each = toset(distinct([for k in fileset("${path.module}/codedeploy/", "**") : split("/", k)[0]])) # For each directory, create a zip file.

  output_path = "${path.module}/staging/${each.key}.zip"
  type        = "zip"

  dynamic "source" { # For each directory, add every file/subdirectory into a zip.
    for_each = fileset("${path.module}/codedeploy/${each.key}", "**")

    content {
      content = templatefile("${path.module}/codedeploy/${each.key}/${source.key}", {
      }) # We use templatefile under a dynamic call so that we only have to define variables used in every codedeploy file once
      filename = source.key
    }
  }
}

# aws_s3_object.codedeploy_zips
resource "aws_s3_object" "codedeploy_zips" {
  for_each = data.archive_file.codedeploy_files

  bucket = var.bucket
  etag   = data.archive_file.codedeploy_files[each.key].output_md5
  key    = "codedeploy/${basename(data.archive_file.codedeploy_files[each.key].output_path)}"
  source = data.archive_file.codedeploy_files[each.key].output_path
}
