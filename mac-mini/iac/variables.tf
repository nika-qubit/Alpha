variable "home_dir" {
  description = "Absolute home directory of the Mac mini account that owns the Immich LaunchAgent."
  type        = string
  sensitive   = true

  validation {
    condition     = startswith(var.home_dir, "/Users/") && !strcontains(var.home_dir, " ")
    error_message = "home_dir must be a macOS user home path without spaces."
  }
}

variable "media_volume_path" {
  description = "Mounted APFS media volume path."
  type        = string
  sensitive   = true
  validation {
    condition     = startswith(var.media_volume_path, "/Volumes/") && !strcontains(var.media_volume_path, " ")
    error_message = "media_volume_path must be an absolute /Volumes path without spaces."
  }
}

variable "media_volume_uuid" {
  description = "Expected APFS media volume UUID."
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.media_volume_uuid))
    error_message = "media_volume_uuid must be a UUID."
  }
}

variable "media_sentinel_path" {
  description = "Path to the existing media-volume sentinel."
  type        = string
  sensitive   = true
}

variable "media_sentinel_content" {
  description = "Exact expected media-volume sentinel contents."
  type        = string
  sensitive   = true
}

variable "backup_volume_path" {
  description = "Mounted EnvoySSD backup volume path."
  type        = string
  sensitive   = true
  validation {
    condition     = startswith(var.backup_volume_path, "/Volumes/") && !strcontains(var.backup_volume_path, " ")
    error_message = "backup_volume_path must be an absolute /Volumes path without spaces."
  }
}

variable "backup_volume_uuid" {
  description = "Expected APFS backup volume UUID."
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.backup_volume_uuid))
    error_message = "backup_volume_uuid must be a UUID."
  }
}

variable "backup_sentinel_path" {
  description = "Path to the existing backup-volume sentinel."
  type        = string
  sensitive   = true
}

variable "backup_sentinel_content" {
  description = "Exact expected backup-volume sentinel contents."
  type        = string
  sensitive   = true
}

variable "upload_location" {
  description = "Existing Immich managed media root on the media volume."
  type        = string
  sensitive   = true
}

variable "external_location" {
  description = "Existing external-library root on the media volume."
  type        = string
  sensitive   = true
}

variable "backup_location" {
  description = "Existing Immich database-backup destination on EnvoySSD."
  type        = string
  sensitive   = true
}

variable "database_location" {
  description = "Existing PostgreSQL data directory on the internal SSD."
  type        = string
  sensitive   = true
}

variable "cache_location" {
  description = "Existing Immich machine-learning cache directory."
  type        = string
  sensitive   = true
}

variable "config_location" {
  description = "Existing Immich configuration directory."
  type        = string
  sensitive   = true
}
