# AWS CloudFormation Best Practices

## Table of Contents
- [Official Documentation](#official-documentation)
- [Core Concepts](#core-concepts)
- [Project Structure Examples](#project-structure-examples)
- [Configuration Examples](#configuration-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Do's and Don'ts](#dos-and-donts)
- [Additional Resources](#additional-resources)

## Official Documentation

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)
- [CloudFormation Template Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html)
- [CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)

## Core Concepts

### Infrastructure as Code (IaC)
- **Templates**: JSON or YAML files that define AWS resources
- **Stacks**: Collections of AWS resources managed as a single unit
- **Change Sets**: Preview changes before applying them
- **Nested Stacks**: Break down large templates into smaller, reusable components
- **Stack Sets**: Deploy stacks across multiple accounts and regions

### Key Components
- **Resources**: AWS services to create (required)
- **Parameters**: Input values to customize templates
- **Outputs**: Values returned after stack creation
- **Mappings**: Static key-value pairs for conditional logic
- **Conditions**: Control resource creation based on parameters
- **Metadata**: Additional information about resources

## Project Structure Examples

### Basic Project Structure
```
cloudformation/
├── templates/
│   ├── infrastructure/
│   │   ├── vpc.yaml
│   │   ├── security-groups.yaml
│   │   └── subnets.yaml
│   ├── applications/
│   │   ├── web-app.yaml
│   │   └── api-gateway.yaml
│   └── main.yaml
├── parameters/
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
├── scripts/
│   ├── deploy.sh
│   ├── validate.sh
│   └── delete.sh
└── README.md
```

### Advanced Multi-Environment Structure
```
cloudformation/
├── environments/
│   ├── dev/
│   │   ├── parameters.json
│   │   └── deploy.sh
│   ├── staging/
│   │   ├── parameters.json
│   │   └── deploy.sh
│   └── prod/
│       ├── parameters.json
│       └── deploy.sh
├── modules/
│   ├── vpc/
│   │   ├── template.yaml
│   │   └── README.md
│   ├── rds/
│   │   ├── template.yaml
│   │   └── README.md
│   └── ecs/
│       ├── template.yaml
│       └── README.md
├── policies/
│   ├── bucket-policy.json
│   └── role-policy.json
└── main-template.yaml
```

## Configuration Examples

### Basic VPC Template
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'VPC with public and private subnets'

Parameters:
  EnvironmentName:
    Description: Environment name prefix
    Type: String
    Default: dev
  
  VpcCIDR:
    Description: CIDR block for VPC
    Type: String
    Default: 10.0.0.0/16

Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-VPC

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-IGW

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Sub 
        - ${VpcCIDR}
        - VpcCIDR: !Select [0, !Split ['.', !Ref VpcCIDR]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-Public-Subnet-AZ1

Outputs:
  VPC:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${EnvironmentName}-VPCID

  PublicSubnet1:
    Description: Public Subnet 1 ID
    Value: !Ref PublicSubnet1
    Export:
      Name: !Sub ${EnvironmentName}-PUB1-SN
```

### Application Load Balancer with Auto Scaling
```yaml
Resources:
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub ${EnvironmentName}-ALB
      Subnets:
        - !ImportValue 
          Fn::Sub: ${EnvironmentName}-PUB1-SN
        - !ImportValue 
          Fn::Sub: ${EnvironmentName}-PUB2-SN
      SecurityGroups:
        - !Ref LoadBalancerSecurityGroup
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-ALB

  LoadBalancerListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref DefaultTargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      VPCZoneIdentifier:
        - !ImportValue 
          Fn::Sub: ${EnvironmentName}-PRIV1-SN
        - !ImportValue 
          Fn::Sub: ${EnvironmentName}-PRIV2-SN
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: !Ref MinSize
      MaxSize: !Ref MaxSize
      DesiredCapacity: !Ref DesiredCapacity
      TargetGroupARNs:
        - !Ref DefaultTargetGroup
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-ASG
          PropagateAtLaunch: true
```

### Parameters File Example
```json
[
  {
    "ParameterKey": "EnvironmentName",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "VpcCIDR",
    "ParameterValue": "10.0.0.0/16"
  },
  {
    "ParameterKey": "MinSize",
    "ParameterValue": "2"
  },
  {
    "ParameterKey": "MaxSize",
    "ParameterValue": "10"
  },
  {
    "ParameterKey": "DesiredCapacity",
    "ParameterValue": "4"
  }
]
```

## Best Practices

### Template Organization
1. **Use Nested Stacks**: Break large templates into smaller, manageable pieces
2. **Modular Design**: Create reusable templates for common patterns
3. **Consistent Naming**: Use clear, descriptive names with environment prefixes
4. **Version Control**: Store templates in Git with proper branching strategy

### Security
1. **IAM Policies**: Use least privilege principle for CloudFormation service roles
2. **Parameter Encryption**: Use NoEcho for sensitive parameters
3. **Cross-Stack References**: Use Outputs and ImportValue for resource sharing
4. **Resource Policies**: Implement proper resource-level security

### Performance and Reliability
1. **Stack Limits**: Keep stacks under 200 resources when possible
2. **Rollback Configuration**: Configure automatic rollback on failure
3. **Change Sets**: Always use change sets for production updates
4. **Stack Policies**: Protect critical resources from accidental updates

### Cost Optimization
1. **Resource Tagging**: Implement comprehensive tagging strategy
2. **Condition Usage**: Use conditions to create optional resources
3. **Instance Sizing**: Use parameters for flexible instance sizing
4. **Cleanup Policies**: Set retention policies for logs and backups

## Common Patterns

### Multi-Environment Deployment
```bash
# Deploy script example
#!/bin/bash
ENVIRONMENT=$1
STACK_NAME="myapp-${ENVIRONMENT}"
TEMPLATE_FILE="main-template.yaml"
PARAMETERS_FILE="environments/${ENVIRONMENT}/parameters.json"

aws cloudformation deploy \
  --template-file ${TEMPLATE_FILE} \
  --stack-name ${STACK_NAME} \
  --parameter-overrides file://${PARAMETERS_FILE} \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

### Cross-Stack Dependencies
```yaml
# Parent stack exports
Outputs:
  VPCId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${AWS::StackName}-VPCID

# Child stack imports
Parameters:
  NetworkStackName:
    Type: String
    Description: Name of the network stack

Resources:
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !ImportValue 
        Fn::Sub: ${NetworkStackName}-VPCID
```

### Conditional Resource Creation
```yaml
Conditions:
  CreateProdResources: !Equals [!Ref EnvironmentName, production]
  CreateDevResources: !Equals [!Ref EnvironmentName, development]

Resources:
  ProdDatabase:
    Type: AWS::RDS::DBInstance
    Condition: CreateProdResources
    Properties:
      MultiAZ: true
      DeletionProtection: true

  DevDatabase:
    Type: AWS::RDS::DBInstance
    Condition: CreateDevResources
    Properties:
      MultiAZ: false
      DeletionProtection: false
```

## Do's and Don'ts

### Do's
✅ **Use version control** for all CloudFormation templates
✅ **Validate templates** before deployment using `aws cloudformation validate-template`
✅ **Use change sets** to preview changes before applying
✅ **Implement proper tagging** strategy for resource management
✅ **Use parameters** for environment-specific configurations
✅ **Document templates** with clear descriptions and comments
✅ **Use Stack Policies** to protect critical resources
✅ **Implement rollback triggers** for automated failure recovery
✅ **Use Mappings** for region-specific configurations
✅ **Test templates** in non-production environments first

### Don'ts
❌ **Don't hardcode values** that vary between environments
❌ **Don't create overly large stacks** (>200 resources)
❌ **Don't ignore drift detection** - run it regularly
❌ **Don't skip validation** of templates before deployment
❌ **Don't forget to clean up** unused stacks and resources
❌ **Don't use admin privileges** for CloudFormation service roles
❌ **Don't deploy directly to production** without testing
❌ **Don't ignore stack events** during deployment
❌ **Don't create circular dependencies** between stacks
❌ **Don't use deprecated resource types**

## Additional Resources

### Tools and Extensions
- [AWS CloudFormation Linter (cfn-lint)](https://github.com/aws-cloudformation/cfn-lint)
- [CloudFormation Guard](https://github.com/aws-cloudformation/cloudformation-guard)
- [Troposphere](https://github.com/cloudtools/troposphere) - Python library for CloudFormation
- [AWS CDK](https://aws.amazon.com/cdk/) - Cloud Development Kit
- [Rain](https://github.com/aws-cloudformation/rain) - CloudFormation CLI tool

### Learning Resources
- [AWS CloudFormation Workshops](https://workshops.aws/)
- [CloudFormation Templates GitHub](https://github.com/awslabs/aws-cloudformation-templates)
- [AWS Quick Starts](https://aws.amazon.com/quickstart/)
- [CloudFormation Best Practices Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)

### Community Resources
- [AWS CloudFormation Reddit](https://www.reddit.com/r/aws/)
- [AWS CloudFormation Stack Overflow](https://stackoverflow.com/questions/tagged/amazon-cloudformation)
- [AWS Developer Forums](https://forums.aws.amazon.com/forum.jspa?forumID=92)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

### Monitoring and Troubleshooting
- [AWS CloudTrail](https://aws.amazon.com/cloudtrail/) - API logging
- [AWS Config](https://aws.amazon.com/config/) - Resource compliance
- [AWS CloudWatch](https://aws.amazon.com/cloudwatch/) - Monitoring and alerts
- [AWS Systems Manager](https://aws.amazon.com/systems-manager/) - Operational insights