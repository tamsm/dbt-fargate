variable "region" {
  type        = string
  description = "Deployment target region"
}
variable "subnets" {
  type        = list(string)
  default     = []
  description = "Ideally use private subnet/s"
}

variable "project_dir" {
  type        = string
  description = "Path to dbt project directory, used for s3 upload"
}

variable "dbt_dir" {
  type        = string
  description = "The dbt project directory name"
}

variable "executions" {
#  type        = list(map(string, string, list(string)))
  description = "The list of scheduled ecs task executions, each containing a schedule expression and command array"
}

variable "log_configuration" {
  type        = any
  default     = null
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
}