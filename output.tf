# define terraform module output values here 
output "lambda_arn" {
  description             = "Lambda ARN"
  value                   = aws_lambda_function.mylambda_func.arn
}
