import boto3
import os
import base64
import json
import time
import uuid
from datetime import datetime, timedelta

def handler(event, context):
    print(f"Event received: {json.dumps(event)}")
    
    # Check if this is a scheduled recheck event
    if event.get('source') == 'aws.events' and event.get('detail-type') == 'Scheduled Event':
        print("This is a scheduled recheck event")
        return check_cpu_and_adjust()
    
    # Check if this is an alarm notification
    if 'Records' in event and len(event['Records']) > 0 and 'Sns' in event['Records'][0]:
        sns_message = event['Records'][0]['Sns']
        try:
            message = json.loads(sns_message.get('Message', '{}'))
            alarm_name = message.get('AlarmName', '')
            alarm_state = message.get('NewStateValue', '')
            
            print(f"Alarm: {alarm_name}, State: {alarm_state}")
            
            if 'cpu-high' in alarm_name.lower() and alarm_state == 'ALARM':
                print("CPU high alarm triggered, launching helper instances")
                return launch_helper_instances(2)
            elif 'cpu-low' in alarm_name.lower() and alarm_state == 'ALARM':
                print("CPU low alarm triggered, terminating helper instances")
                return terminate_helper_instances()
        except Exception as e:
            print(f"Error processing SNS message: {str(e)}")
            return {"error": f"Error processing message: {str(e)}"}
    
    print("Event not recognized or no action needed")
    return {"message": "No action taken"}

def launch_helper_instances(count):
    """Launch helper instances and register with target group"""
    ec2 = boto3.resource('ec2')
    client = boto3.client('elbv2')
    lambda_client = boto3.client('lambda')
    events_client = boto3.client('events')
    
    ami_id = os.environ['AMI_ID']
    sg_id = os.environ['SG_ID']
    subnet_ids = os.environ['SUBNET_IDS'].split(',')
    tg_arn = os.environ['TARGET_GROUP_ARN']
    user_data = base64.b64decode(os.environ['USER_DATA']).decode('utf-8')
    
    # Generate a unique batch ID for tracking
    batch_id = f"helper-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    
    try:
        # Launch instances
        print(f"Launching {count} helper instances")
        instances = ec2.create_instances(
            ImageId=ami_id,
            InstanceType='t2.micro',
            MinCount=count,
            MaxCount=count,
            SecurityGroupIds=[sg_id],
            SubnetId=subnet_ids[0],
            UserData=user_data,
            TagSpecifications=[{
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Type', 'Value': 'Helper'},
                    {'Key': 'Name', 'Value': f'CPU-Helper-{batch_id}'},
                    {'Key': 'CreatedBy', 'Value': 'Lambda'},
                    {'Key': 'CreatedAt', 'Value': datetime.now().isoformat()}
                ]
            }]
        )
        instance_ids = [i.id for i in instances]
        print(f"Launched instances: {instance_ids}")
        
        # Wait for instances to be running (with timeout)
        ec2_client = boto3.client('ec2')
        print("Waiting for instances to become available")
        waiter = ec2_client.get_waiter('instance_running')
        waiter.wait(InstanceIds=instance_ids)
        
        # Register with target group
        print(f"Registering instances with target group: {tg_arn}")
        targets = [{'Id': iid} for iid in instance_ids]
        client.register_targets(TargetGroupArn=tg_arn, Targets=targets)
        
        # Schedule a recheck after 4 minutes
        rule_name = f"cpu-recheck-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        schedule_time = datetime.now() + timedelta(minutes=4)
        cron_expression = f"cron({schedule_time.minute} {schedule_time.hour} {schedule_time.day} {schedule_time.month} ? {schedule_time.year})"
        
        print(f"Creating CloudWatch Events rule to check CPU again in 4 minutes")
        events_client.put_rule(
            Name=rule_name,
            ScheduleExpression=cron_expression,
            State='ENABLED',
            Description='CPU utilization recheck'
        )
        
        # Add current Lambda as target
        events_client.put_targets(
            Rule=rule_name,
            Targets=[{
                'Id': '1',
                'Arn': context.invoked_function_arn
            }]
        )
        
        print(f"Successfully launched instances and scheduled recheck")
        return {"message": "Launched helper instances", "instances": instance_ids, "recheck_rule": rule_name}
    
    except Exception as e:
        print(f"Error launching instances: {str(e)}")
        return {"error": f"Failed to launch instances: {str(e)}"}

def terminate_helper_instances():
    """Terminate all helper instances created by Lambda"""
    ec2 = boto3.client('ec2')
    
    try:
        # Find all instances with the Helper tag
        print("Finding all helper instances")
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Type', 'Values': ['Helper']},
                {'Name': 'tag:CreatedBy', 'Values': ['Lambda']},
                {'Name': 'instance-state-name', 'Values': ['pending', 'running']}
            ]
        )
        
        instance_ids = []
        for reservation in response.get('Reservations', []):
            for instance in reservation.get('Instances', []):
                instance_ids.append(instance['InstanceId'])
        
        if not instance_ids:
            print("No helper instances found to terminate")
            return {"message": "No helper instances found"}
        
        # Terminate the instances
        print(f"Terminating {len(instance_ids)} helper instances: {instance_ids}")
        ec2.terminate_instances(InstanceIds=instance_ids)
        
        return {"message": "Terminated helper instances", "instances": instance_ids}
    
    except Exception as e:
        print(f"Error terminating instances: {str(e)}")
        return {"error": f"Failed to terminate instances: {str(e)}"}

def check_cpu_and_adjust():
    """Check current CPU utilization and add more instances if needed"""
    cloudwatch = boto3.client('cloudwatch')
    
    try:
        # Get ASG name from the environment or extract from alarm ARN
        asg_name = os.environ.get('ASG_NAME', '')
        if not asg_name:
            print("ASG name not found in environment, cannot check CPU")
            return {"error": "ASG name not available"}
        
        # Get current CPU utilization
        end_time = datetime.now()
        start_time = end_time - timedelta(minutes=5)
        
        print(f"Getting CPU metrics for ASG: {asg_name}")
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[{'Name': 'AutoScalingGroupName', 'Value': asg_name}],
            StartTime=start_time,
            EndTime=end_time,
            Period=60,
            Statistics=['Average']
        )
        
        datapoints = response.get('Datapoints', [])
        if not datapoints:
            print("No CPU utilization data found")
            return {"message": "No CPU data available"}
        
        # Find the most recent datapoint
        latest = sorted(datapoints, key=lambda x: x['Timestamp'])[-1]
        cpu = latest['Average']
        print(f"Current CPU utilization: {cpu}%")
        
        # If CPU is still high, launch more instances
        if cpu > 70:
            print("CPU still above threshold, launching more instances")
            return launch_helper_instances(2)
        else:
            print("CPU is under control, no additional instances needed")
            return {"message": "CPU below threshold, no action needed"}
    
    except Exception as e:
        print(f"Error checking CPU: {str(e)}")
        return {"error": f"Failed to check CPU: {str(e)}"}