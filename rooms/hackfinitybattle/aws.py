import boto3
import botocore
import json

# List of AWS services and their respective "list" command
aws_services = {
    "s3": "list_buckets",
    "ec2": "describe_instances",
    "lambda": "list_functions",
    "iam": "list_users",
    "rds": "describe_db_instances",
    "dynamodb": "list_tables",
    "ecr": "describe_repositories",
    "sqs": "list_queues",
    "sns": "list_topics",
    "cloudwatch": "list_metrics",
    "events": "list_rules",
    "sts": "get_caller_identity",
    "secretsmanager": "list_secrets",
    "kms": "list_keys",
    "ssm": "list_documents",
    "apigateway": "get_rest_apis",
    "cloudformation": "list_stacks",
    "logs": "describe_log_groups",
}

# File to store accessible services
output_file = "accessible_services.txt"

accessible_services = []

print("\n🔍 Checking AWS services access...\n")

for service, command in aws_services.items():
    try:
        client = boto3.client(service)
        method = getattr(client, command)
        response = method()
        
        # Log the service if the command executes successfully
        print(f"✅ Access allowed: {service}")
        accessible_services.append(service)
    
    except botocore.exceptions.ClientError as error:
        error_code = error.response['Error']['Code']
        if error_code == "AccessDenied" or "UnauthorizedOperation" in str(error):
            print(f"❌ Access denied: {service}")
        else:
            print(f"⚠️ Error in {service}: {error_code}")

# Save results to file
with open(output_file, "w") as f:
    f.write("\n".join(accessible_services))

print(f"\n✅ Access check completed! Results saved in {output_file}\n")
