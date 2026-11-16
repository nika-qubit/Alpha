locals {
  stage_directory = "${path.module}/.generated"
  app_home        = "${var.home_dir}/immich-app"
  immich_version  = trimspace(file("${path.module}/../../immich-app/immich-version.txt"))
  host_environment = templatefile("${path.module}/templates/immich-host.env.tftpl", {
    app_home                = local.app_home
    immich_version          = local.immich_version
    media_volume_path       = var.media_volume_path
    media_volume_uuid       = var.media_volume_uuid
    media_sentinel_path     = var.media_sentinel_path
    media_sentinel_content  = var.media_sentinel_content
    backup_volume_path      = var.backup_volume_path
    backup_volume_uuid      = var.backup_volume_uuid
    backup_sentinel_path    = var.backup_sentinel_path
    backup_sentinel_content = var.backup_sentinel_content
    upload_location         = var.upload_location
    external_location       = var.external_location
    backup_location         = var.backup_location
    database_location       = var.database_location
    cache_location          = var.cache_location
    config_location         = var.config_location
  })
  launch_agent = templatefile("${path.module}/templates/com.ningk.immich-safe-start.plist.tftpl", {
    home_dir = var.home_dir
    app_home = local.app_home
  })
}

resource "local_sensitive_file" "host_environment" {
  filename             = "${local.stage_directory}/.immich-host.env"
  content              = local.host_environment
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "safe_start" {
  filename             = "${local.stage_directory}/immich-safe-start.sh"
  source               = "${path.module}/../../immich-app/immich-safe-start.sh"
  file_permission      = "0700"
  directory_permission = "0700"
}

resource "local_file" "storage_check" {
  filename             = "${local.stage_directory}/immich-storage-check.sh"
  source               = "${path.module}/../../immich-app/immich-storage-check.sh"
  file_permission      = "0700"
  directory_permission = "0700"
}

resource "local_file" "volume_monitor" {
  filename             = "${local.stage_directory}/immich-volume-monitor.sh"
  source               = "${path.module}/../../immich-app/immich-volume-monitor.sh"
  file_permission      = "0700"
  directory_permission = "0700"
}

resource "local_file" "launch_agent" {
  filename             = "${local.stage_directory}/com.ningk.immich-safe-start.plist"
  content              = local.launch_agent
  file_permission      = "0600"
  directory_permission = "0700"
}

output "stage_directory" {
  description = "Private, ignored staging directory to inspect before installing anything."
  value       = local.stage_directory
}
