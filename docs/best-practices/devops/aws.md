# AWS Best Practices

## Official Documentation
- **AWS Documentation**: https://docs.aws.amazon.com
- **AWS CLI**: https://docs.aws.amazon.com/cli
- **AWS Well-Architected Framework**: https://aws.amazon.com/architecture/well-architected
- **AWS Best Practices**: https://aws.amazon.com/architecture/reference-architecture-diagrams

## Account Setup and Security

### IAM Best Practices
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT:user/developer"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### Multi-Factor Authentication
```bash
# Enable MFA for root and IAM users
aws iam create-virtual-mfa-device \
  --virtual-mfa-device-name root-account-mfa-device \
  --path /

# Create IAM roles instead of using access keys
aws iam create-role \
  --role-name EC2-S3-Role \
  --assume-role-policy-document file://trust-policy.json
```

### AWS Organizations
```bash
# Set up organizational units
aws organizations create-organizational-unit \
  --parent-id r-example \
  --name Production

# Apply service control policies
aws organizations attach-policy \
  --policy-id p-example \
  --target-id ou-example
```

## Compute Services

### EC2 Best Practices
```bash
# Use appropriate instance types
# General Purpose: t3.micro, t3.small, m5.large
# Compute Optimized: c5.large, c5.xlarge
# Memory Optimized: r5.large, r5.xlarge
# Storage Optimized: i3.large, d3.xlarge

# Launch instance with proper configuration
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --count 1 \
  --instance-type t3.micro \
  --key-name my-key-pair \
  --security-group-ids sg-903004f8 \
  --subnet-id subnet-6e7f829e \
  --iam-instance-profile Name=EC2-S3-Role \
  --user-data file://user-data.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance},{Key=Environment,Value=Production}]'
```

### Auto Scaling Configuration
```json
{
  "AutoScalingGroupName": "my-asg",
  "MinSize": 2,
  "MaxSize": 10,
  "DesiredCapacity": 3,
  "LaunchTemplate": {
    "LaunchTemplateName": "my-launch-template",
    "Version": "$Latest"
  },
  "VPCZoneIdentifier": "subnet-12345678,subnet-87654321",
  "HealthCheckType": "ELB",
  "HealthCheckGracePeriod": 300,
  "Tags": [
    {
      "Key": "Environment",
      "Value": "Production",
      "PropagateAtLaunch": true
    }
  ]
}
```

### Lambda Functions
```python
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Use environment variables for configuration
        table_name = os.environ['DYNAMODB_TABLE']
        
        # Initialize AWS clients outside the handler when possible
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table(table_name)
        
        # Process the event
        result = process_data(event, table)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result)
        }
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }
```

## Storage Solutions

### S3 Best Practices
```bash
# Create bucket with proper configuration
aws s3api create-bucket \
  --bucket my-secure-bucket \
  --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1

# Enable versioning and encryption
aws s3api put-bucket-versioning \
  --bucket my-secure-bucket \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket my-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Set lifecycle policies
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-bucket \
  --lifecycle-configuration file://lifecycle.json
```

### EBS Optimization
```bash
# Create encrypted EBS volume
aws ec2 create-volume \
  --size 100 \
  --volume-type gp3 \
  --iops 3000 \
  --throughput 125 \
  --encrypted \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=AppData}]'

# Create snapshots for backup
aws ec2 create-snapshot \
  --volume-id vol-1234567890abcdef0 \
  --description "Daily backup $(date)"
```

## Database Services

### RDS Configuration
```bash
# Create RDS instance with best practices
aws rds create-db-instance \
  --db-instance-identifier myapp-prod-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 14.9 \
  --master-username dbadmin \
  --master-user-password MySecurePassword123! \
  --allocated-storage 100 \
  --storage-type gp3 \
  --storage-encrypted \
  --vpc-security-group-ids sg-12345678 \
  --db-subnet-group-name my-db-subnet-group \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --enable-performance-insights \
  --monitoring-interval 60 \
  --monitoring-role-arn arn:aws:iam::123456789012:role/rds-monitoring-role \
  --deletion-protection
```

### DynamoDB Best Practices
```python
import boto3
from boto3.dynamodb.conditions import Key, Attr

# Use connection pooling and proper configurations
dynamodb = boto3.resource(
    'dynamodb',
    region_name='us-east-1',
    config=Config(
        max_pool_connections=50,
        retries={'max_attempts': 3}
    )
)

table = dynamodb.Table('UserData')

# Use batch operations for multiple items
with table.batch_writer() as batch:
    for item in items:
        batch.put_item(Item=item)

# Implement proper error handling
try:
    response = table.query(
        KeyConditionExpression=Key('pk').eq(user_id),
        FilterExpression=Attr('active').eq(True),
        ProjectionExpression='user_id, email, #name',
        ExpressionAttributeNames={'#name': 'name'}
    )
except ClientError as e:
    logger.error(f"DynamoDB error: {e.response['Error']['Message']}")
    raise
```

## Networking and Security

### VPC Configuration
```bash
# Create VPC with proper CIDR blocks
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create public and private subnets
aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a

aws ec2 create-subnet \
  --vpc-id vpc-12345678 \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b

# Set up NAT Gateway for private subnets
aws ec2 create-nat-gateway \
  --subnet-id subnet-12345678 \
  --allocation-id eipalloc-12345678
```

### Security Groups
```json
{
  "GroupName": "web-server-sg",
  "Description": "Security group for web servers",
  "VpcId": "vpc-12345678",
  "SecurityGroupRules": [
    {
      "IpPermissions": [
        {
          "IpProtocol": "tcp",
          "FromPort": 80,
          "ToPort": 80,
          "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
        },
        {
          "IpProtocol": "tcp",
          "FromPort": 443,
          "ToPort": 443,
          "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
        },
        {
          "IpProtocol": "tcp",
          "FromPort": 22,
          "ToPort": 22,
          "UserIdGroupPairs": [{"GroupId": "sg-87654321"}]
        }
      ]
    }
  ]
}
```

### Application Load Balancer
```bash
# Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name my-application-load-balancer \
  --subnets subnet-12345678 subnet-87654321 \
  --security-groups sg-12345678 \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4

# Create target group
aws elbv2 create-target-group \
  --name my-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-12345678 \
  --health-check-protocol HTTP \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3
```

## Container Services

### ECS Configuration
```json
{
  "family": "my-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "my-app",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "environment": [
        {"name": "NODE_ENV", "value": "production"}
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db/password"
        }
      ]
    }
  ]
}
```

### EKS Best Practices
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      serviceAccountName: my-app-service-account
      containers:
      - name: my-app
        image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: AWS_REGION
          value: us-east-1
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: host
```

## Monitoring and Logging

### CloudWatch Configuration
```bash
# Create custom metric
aws cloudwatch put-metric-data \
  --namespace "MyApp/Performance" \
  --metric-data MetricName=ResponseTime,Value=200,Unit=Milliseconds,Dimensions=Environment=Production

# Create alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "High-CPU-Utilization" \
  --alarm-description "Alarm when CPU exceeds 70%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:my-topic
```

### X-Ray Tracing
```python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch all supported libraries
patch_all()

@xray_recorder.capture('my_function')
def my_function():
    # Add custom annotations and metadata
    xray_recorder.put_annotation('user_id', user_id)
    xray_recorder.put_metadata('request_data', request_data)
    
    # Your function logic here
    return result
```

## CI/CD Integration

### CodePipeline Configuration
```json
{
  "pipeline": {
    "name": "my-app-pipeline",
    "roleArn": "arn:aws:iam::123456789012:role/CodePipelineRole",
    "artifactStore": {
      "type": "S3",
      "location": "my-pipeline-artifacts"
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "SourceAction",
            "actionTypeId": {
              "category": "Source",
              "owner": "ThirdParty",
              "provider": "GitHub",
              "version": "1"
            },
            "configuration": {
              "Owner": "my-org",
              "Repo": "my-app",
              "Branch": "main",
              "OAuthToken": "{{resolve:secretsmanager:github-token:SecretString:token}}"
            },
            "outputArtifacts": [{"name": "SourceOutput"}]
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "BuildAction",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "configuration": {
              "ProjectName": "my-app-build"
            },
            "inputArtifacts": [{"name": "SourceOutput"}],
            "outputArtifacts": [{"name": "BuildOutput"}]
          }
        ]
      }
    ]
  }
}
```

### CodeBuild Specification
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"my-app","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

## Cost Optimization

### Resource Tagging Strategy
```bash
# Implement consistent tagging
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Environment,Value=Production \
         Key=Project,Value=MyApp \
         Key=Owner,Value=DevTeam \
         Key=CostCenter,Value=Engineering \
         Key=Backup,Value=Required
```

### Reserved Instances and Savings Plans
```bash
# Analyze usage patterns
aws ce get-usage-and-costs \
  --time-period Start=2023-01-01,End=2023-12-31 \
  --granularity MONTHLY \
  --metrics BlendedCost,UsageQuantity \
  --group-by Type=DIMENSION,Key=SERVICE

# Purchase Reserved Instances based on analysis
aws ec2 purchase-reserved-instances-offering \
  --reserved-instances-offering-id 438012d3-4052-4cc7-b2e3-8d78e9b4feaf \
  --instance-count 2
```

### Automated Resource Cleanup
```python
import boto3
from datetime import datetime, timedelta

def cleanup_unused_resources():
    ec2 = boto3.client('ec2')
    
    # Find unattached EBS volumes older than 30 days
    response = ec2.describe_volumes(
        Filters=[
            {'Name': 'status', 'Values': ['available']},
        ]
    )
    
    cutoff_date = datetime.now() - timedelta(days=30)
    
    for volume in response['Volumes']:
        create_time = volume['CreateTime'].replace(tzinfo=None)
        if create_time < cutoff_date:
            print(f"Deleting unused volume: {volume['VolumeId']}")
            ec2.delete_volume(VolumeId=volume['VolumeId'])
```

## Security Best Practices

### AWS Config Rules
```json
{
  "ConfigRuleName": "s3-bucket-public-access-prohibited",
  "Description": "Checks that S3 buckets do not allow public access",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  },
  "Scope": {
    "ComplianceResourceTypes": [
      "AWS::S3::Bucket"
    ]
  }
}
```

### Secrets Manager Integration
```python
import boto3
import json

def get_secret(secret_name, region_name="us-east-1"):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except ClientError as e:
        logger.error(f"Error retrieving secret: {e}")
        raise e
```

## Common Pitfalls

1. **Over-provisioning**: Right-size instances based on actual usage
2. **No encryption**: Enable encryption for data at rest and in transit
3. **Weak IAM policies**: Follow principle of least privilege
4. **No monitoring**: Implement comprehensive monitoring and alerting
5. **Single AZ deployment**: Use multiple AZs for high availability
6. **No backup strategy**: Implement automated backup and restore procedures
7. **Cost blindness**: Regularly review and optimize costs
8. **Security group misconfig**: Avoid overly permissive rules
9. **No disaster recovery**: Plan for regional failures
10. **Vendor lock-in**: Design for portability where possible