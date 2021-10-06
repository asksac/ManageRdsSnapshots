#
# This script performs the following steps: 
# 1. Creates an EventBridge rule
# 2. Creates an EventBridge target pointing to Lambda function 
#

resource "aws_cloudwatch_event_rule" "event_rule" {
  name                  = "${var.app_shortcode}_Lambda_Scheduler_Rule"
  description           = "Triggers Lambda function ${var.lambda_name} automatically based on schedule"

  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
  schedule_expression   = var.schedule_expression 
}

resource "aws_cloudwatch_event_target" "event_target" {
  arn           = aws_lambda_alias.mylambda_latest.arn # aws_lambda_function.mylambda_func.arn
  rule          = aws_cloudwatch_event_rule.event_rule.id

  depends_on    = [ aws_lambda_permission.allow_eventbridge ]
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mylambda_func.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule.arn
  qualifier     = aws_lambda_alias.mylambda_latest.name
}

