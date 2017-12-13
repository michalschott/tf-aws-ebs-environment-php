data "aws_iam_policy_document" "app" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${join(var.separator, compact(list(var.customer, var.project, var.app, var.environment)))}"
  assume_role_policy = "${data.aws_iam_policy_document.app.json}"
}

resource "aws_iam_instance_profile" "app" {
  name = "${join(var.separator, compact(list(var.customer, var.project, var.app, var.environment)))}"
  role = "${aws_iam_role.app.name}"
}

data "aws_iam_policy_document" "ebs" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "elasticbeanstalk.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ebs" {
  name               = "${join(var.separator, compact(list(var.customer, var.project, var.app, var.environment, "ebs")))}"
  assume_role_policy = "${data.aws_iam_policy_document.ebs.json}"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkEnhancedHealth" {
  role       = "${aws_iam_role.ebs.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "AWSElasticBeanstalkService" {
  role       = "${aws_iam_role.ebs.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_security_group" "app" {
  name        = "${join(var.separator, compact(list(var.customer, var.project, var.environment, var.app)))}"
  description = "Load Balancer Security Group"
  vpc_id      = "${var.vpc_id}"

  tags {
    "Name"        = "${join(var.separator, compact(list(var.customer, var.project, var.environment, var.app)))}"
    "Terraform"   = "true"
    "Customer"    = "${length(var.customer) > 0 ? var.customer : "N/A"}"
    "Project"     = "${length(var.project) > 0 ? var.project : "N/A"}"
    "Environment" = "${var.environment}"
  }
}

resource "aws_security_group_rule" "app_ingress_tcp_80_cidr" {
  security_group_id = "${aws_security_group.app.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = "${var.http_cidr_ingress}"
  type              = "ingress"
}

resource "aws_security_group_rule" "app_ingress_tcp_443_cidr" {
  count             = "${var.elb_ssl_cert == "" ? 0 : 1}"
  security_group_id = "${aws_security_group.app.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = "${var.http_cidr_ingress}"
  type              = "ingress"
}

resource "aws_security_group_rule" "app_egress_tcp_80" {
  security_group_id = "${aws_security_group.app.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = "${var.http_cidr_egress}"
  type              = "egress"
}

resource "aws_elastic_beanstalk_environment" "app" {
  name                = "${join(var.separator, compact(list(var.customer, var.project, var.app, var.environment)))}"
  application         = "${var.ebs_app}"
  solution_stack_name = "${var.app_solution_stack}"
  tier                = "${var.app_tier}"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${var.vpc_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${join(",", var.vpc_ec2_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${join(",", var.vpc_elb_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "${var.vpc_elb_scheme}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "${var.rolling_update_enabled}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "${var.rolling_update_type}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.app.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.app.id}"
  }

  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerProtocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elb:listener"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = "${var.elb_ssl_cert}"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerEnabled"
    value     = "${var.elb_ssl_cert == "" ? "false" : "true"}"
  }

  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "${var.elb_ssl_cert == "" ? "true" : "false"}"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "${var.elb_ssl_cert == "" ? "false" : "true"}"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = "${var.elb_ssl_cert}"
  }

  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingEnabled"
    value     = "${var.elb_connection_draining_enabled}"
  }

  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingTimeout"
    value     = "${var.elb_connection_draining_timeout}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${var.ec2_key_name}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SSHSourceRestriction"
    value     = "tcp,22,22,${var.ssh_source_restriction}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${var.ec2_instance_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${aws_iam_instance_profile.app.name}"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "${var.asg_min_size}"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "${var.asg_max_size}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "${var.asg_trigger_breach_duration}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerBreachScaleIncrement"
    value     = "${var.asg_trigger_lower_breach_scale_increment}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "${var.asg_trigger_lower_threshold}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "${var.asg_trigger_measure_name}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "${var.asg_trigger_period}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "${var.asg_trigger_statistic}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "${var.asg_trigger_unit}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperBreachScaleIncrement"
    value     = "${var.asg_trigger_upper_breach_scale_increment}"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "${var.asg_trigger_upper_threshold}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "${var.healthcheck_url}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Endpoint"
    value     = "${var.notification_endpoint}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "${var.logs_stream}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "${var.logs_delete_on_terminate}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "${var.logs_retention}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "${var.batch_size_type}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "${var.batch_size}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "${var.loadbalancer_type}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "${aws_iam_role.ebs.name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "document_root"
    value     = "${var.php_document_root}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "memory_limit"
    value     = "${var.php_memory_limit}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "allow_url_fopen"
    value     = "${var.php_allow_url_fopen}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "zlib.output_compression"
    value     = "${var.php_zlib_output_compression}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "display_errors"
    value     = "${var.php_display_errors}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "max_execution_time"
    value     = "${var.php_max_execution_time}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "composer_options"
    value     = "${var.php_composer_options}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 0))), 0)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 0))), 0), var.env_default_value)}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 1))), 1)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 1))), 1), var.env_default_value)}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 2))), 2)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 2))), 2), var.env_default_value)}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 3))), 3)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 3))), 3), var.env_default_value)}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "${element(concat(keys(var.env_vars), list(format(var.env_default_key, 4))), 4)}"
    value     = "${lookup(var.env_vars, element(concat(keys(var.env_vars), list(format(var.env_default_key, 4))), 4), var.env_default_value)}"
  }

  tags {
    "Terraform"   = "true"
    "Customer"    = "${length(var.customer) > 0 ? var.customer : "N/A"}"
    "Environment" = "${var.environment}"
    "Project"     = "${length(var.project) > 0 ? var.project : "N/A"}"
  }
}
