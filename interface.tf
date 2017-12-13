variable "project" {
  description = "Project name."
  default     = ""
}

variable "customer" {
  description = "Customer name."
  default     = ""
}

variable "environment" {
  description = "Environment name."
}

variable "app" {
  description = "App name."
}

variable "ebs_app" {
  description = "EBS App name."
}

variable "app_solution_stack" {
  description = "Solution stack to be used."
}

variable "app_tier" {
  description = "Webserver or Worker."
  default     = "WebServer"
}

variable "separator" {
  description = "Separator to be used in naming."
  default     = "-"
}

variable "vpc_id" {
  description = "VPC id."
}

variable "vpc_ec2_subnets" {
  type        = "list"
  description = "Subnets for autoscaling group."
}

variable "vpc_elb_subnets" {
  type        = "list"
  description = "Subnets for loadbalancer."
}

variable "vpc_elb_scheme" {
  description = "internal or external."
  default     = ""
}

variable "rolling_update_enabled" {
  description = "Should we update in rolling manner."
  default     = "true"
}

variable "rolling_update_type" {
  default     = "Health"
  description = "Rolling update type."
}

variable "http_cidr_ingress" {
  description = "CIDR whitelist for 80 port."
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_egress" {
  description = "CIDR whitelist outbound ELB connectivity."
  default     = ["0.0.0.0/0"]
}

variable "elb_connection_draining_enabled" {
  default     = "true"
  description = "Should connection draining be enabled."
}

variable "elb_connection_draining_timeout" {
  default     = 180
  description = "Connection draining timeout in seconds."
}

variable "elb_ssl_cert" {
  default     = ""
  description = "ARN of certificate to use."
}

variable "ec2_key_name" {
  default     = ""
  description = "SSH Key Name to insert."
}

variable "ec2_instance_type" {
  description = "EC2 instance type."
}

variable "asg_min_size" {
  default     = 1
  description = "Minimum size of ASG group."
}

variable "asg_max_size" {
  default     = 1
  description = "Maximum size of ASG group."
}

variable "healthcheck_url" {
  default     = "TCP:80"
  description = "Application healthcheck URL."
}

variable "notification_endpoint" {
  default     = ""
  description = "Notification endpoint."
}

variable "ssh_source_restriction" {
  default     = "0.0.0.0/0"
  description = "CIDR SSH access whitelist."
}

variable "logs_stream" {
  default     = "false"
  description = "Should logs be published in CloudWatch."
}

variable "logs_delete_on_terminate" {
  default     = "false"
  description = "Should logs be removed from CloudWatch when environment is terminated."
}

variable "logs_retention" {
  default     = 7
  description = "CloudWatch logs retention in days."
}

variable "php_document_root" {
  description = "Specify the child directory of your project that is treated as the public-facing web root."
  default = "/"
}

variable "php_memory_limit" {
  description = "Amount of memory allocated to the PHP environment."
  default = "256M"
}

variable "php_zlib_output_compression" {
  description = "Specifies whether or not PHP should use compression for output."
  default = "false"
}

variable "php_allow_url_fopen" {
  default     = "On"
  description = "Specifies if PHP's file functions are allowed to retrieve data from remote locations, such as websites or FTP servers."
}

variable "php_display_errors" {
  default = "Off"
  description = "Specifies if error messages should be part of the output."
}

variable "php_max_execution_time" {
  default = "60"
  description = "Sets the maximum time, in seconds, a script is allowed to run before it is terminated by the environment."
}

variable "php_composer_options" {
  default = ""
  description = "Sets custom options to use when installing dependencies using Composer through composer.phar install. For more information including available options, go to http://getcomposer.org/doc/03-cli.md#install."
}

variable "db_uri" {
  default     = ""
  description = "DB_URI environment variable."
}

variable "asg_trigger_breach_duration" {
  description = "Amount of time, in minutes, a metric can be beyond its defined limit before the trigger fires."
  default     = 5
}

variable "asg_trigger_lower_breach_scale_increment" {
  description = "How many Amazon EC2 instances to remove when performing a scaling activity."
  default     = -1
}

variable "asg_trigger_lower_threshold" {
  default     = "2000000"
  description = "If the measurement falls below this number for the breach duration, a trigger is fired."
}

variable "asg_trigger_measure_name" {
  default     = "NetworkOut"
  description = "Metric used for your Auto Scaling trigger."
}

variable "asg_trigger_period" {
  default     = 5
  description = "Specifies how frequently Amazon CloudWatch measures the metrics for your trigger."
}

variable "asg_trigger_statistic" {
  default     = "Average"
  description = "Statistic the trigger should use, such as Average."
}

variable "asg_trigger_unit" {
  default     = "Bytes"
  description = "Unit for the trigger measurement, such as Bytes."
}

variable "asg_trigger_upper_breach_scale_increment" {
  description = "How many Amazon EC2 instances to add when performing a scaling activity."
  default     = 1
}

variable "asg_trigger_upper_threshold" {
  default     = "6000000"
  description = "If the measurement is higher than this number for the breach duration, a trigger is fired."
}

variable "batch_size_type" {
  default     = "Percentage"
  description = "The type of number that is specified in BatchSize."
}

variable "batch_size" {
  default     = "100"
  description = "Percentage or fixed number of Amazon EC2 instances in the Auto Scaling group on which to simultaneously perform deployments."
}

variable "loadbalancer_type" {
  default     = "classic"
  description = "Loadbalancer type."
}

variable "env_default_key" {
  default = "DEFAULT_ENV_%d"
}

variable "env_default_value" {
  default = "UNSET"
}

variable "env_vars" {
  default = {}
  type    = "map"
}

output "full-environment-name" {
  description = ""
  value       = "${aws_elastic_beanstalk_environment.app.name}"
}

output "role-name" {
  description = "IAM role name."
  value       = "${aws_iam_role.app.name}"
}

output "app-fqdn" {
  value       = "${lower(aws_elastic_beanstalk_environment.app.cname)}"
  description = "Application FQDN."
}

output "loadbalancers" {
  value       = "${aws_elastic_beanstalk_environment.app.load_balancers}"
  description = "Elastic load balancers in use by this environment."
}
