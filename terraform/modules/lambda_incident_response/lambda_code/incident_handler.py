import boto3
import os
import base64
import json
import time

def handler(event, context):
    print("Event received:", json.dumps(event))
    
    # Parse SNS message
    if 'Records' in event and len(event['Records']) > 0:
        sns_message = event['Records'][0]['Sns']
        message_text = sns_message.get('Message', '{}')
        try:
            message = json.loads(message_text)
            alarm_name = message.get('AlarmName', '')
            alarm_state = message.get('NewStateValue', '')
            
            print(f"Alarm: {alarm_name}, State: {alarm_state}")
            
            # Only launch helper instances for high CPU alarm in ALARM state
            if 'cpu-high' in alarm_name and alarm_state == 'ALARM':
                return launch_helper_instances(context)
            else:
                print("No action needed for this alarm state")
                return {"message": "No action taken"}
        except json.JSONDecodeError:
            print("Failed to parse SNS message")
            return {"error": "Failed to parse message"}
    else:
        print("No SNS records found in event")
        return {"error": "No SNS records"}

def launch_helper_instances(context):
    ec2 = boto3.resource('ec2')
    client = boto3.client('elbv2')
    ami_id = os.environ['AMI_ID']
    sg_id = os.environ['SG_ID']
    subnet_ids = os.environ['SUBNET_IDS'].split(',')
    tg_arn = os.environ['TARGET_GROUP_ARN']
    user_data = base64.b64decode(os.environ['USER_DATA']).decode('utf-8')

    # Launch 2 helper instances
    print("Starting to launch helper instances")
    instances = ec2.create_instances(
        ImageId=ami_id,
        InstanceType='t2.micro',
        MinCount=2,
        MaxCount=2,
        SecurityGroupIds=[sg_id],
        SubnetId=subnet_ids[0],
        UserData=user_data,
        TagSpecifications=[{
            'ResourceType': 'instance',
            'Tags': [
                {'Key': 'Type', 'Value': 'Helper'}, 
                {'Key': 'Name', 'Value': 'CPU-Helper'},
                {'Key': 'LaunchedBy', 'Value': 'Lambda'}
            ]
        }]
    )
    instance_ids = [i.id for i in instances]
    print(f"Instances launched with IDs: {instance_ids}")

    # Don't use waiters for long operations, just check state briefly
    ec2_client = boto3.client('ec2')
    max_wait = min(context.get_remaining_time_in_millis()/1000 - 10, 240)  # Leave 10 seconds buffer
    start_time = time.time()
    
    print(f"Waiting up to {max_wait} seconds for instances to be running")
    running_instances = []
    while time.time() - start_time < max_wait:
        response = ec2_client.describe_instances(InstanceIds=instance_ids)
        running_instances = []
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    running_instances.append(instance['InstanceId'])
        
        if len(running_instances) == len(instance_ids):
            break
            
        print(f"Waiting for instances to start... {len(running_instances)}/{len(instance_ids)} ready")
        time.sleep(5)

    # Register whatever instances are available with ALB target group
    if running_instances:
        print(f"Registering {len(running_instances)} instances with target group")
        targets = [{'Id': iid} for iid in running_instances]
        client.register_targets(TargetGroupArn=tg_arn, Targets=targets)
    else:
        print("No instances reached running state within the timeout period")
    
    return {
        "helper_instances": instance_ids,
        "registered_instances": running_instances,
        "status": "Success" if running_instances else "Partial - instances still starting"
    }