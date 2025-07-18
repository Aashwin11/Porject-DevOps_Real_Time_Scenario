import boto3
import os
import base64

def handler(event, context):
    ec2 = boto3.resource('ec2')
    client = boto3.client('elbv2')
    ami_id = os.environ['AMI_ID']
    sg_id = os.environ['SG_ID']
    subnet_ids = os.environ['SUBNET_IDS'].split(',')
    tg_arn = os.environ['TARGET_GROUP_ARN']
    user_data = base64.b64decode(os.environ['USER_DATA']).decode('utf-8')

    # Launch 2 helper instances
    instances = ec2.create_instances(
        ImageId=ami_id,
        InstanceType='t2.micro',
        MinCount=2,
        MaxCount=2,
        SecurityGroupIds=[sg_id],
        SubnetId=subnet_ids[0],  # Or use random.choice(subnet_ids) for spreading
        UserData=user_data,
        TagSpecifications=[{
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Type', 'Value': 'Helper'}]
        }]
    )
    instance_ids = [i.id for i in instances]

    # Wait for running state
    ec2_client = boto3.client('ec2')
    waiter = ec2_client.get_waiter('instance_running')
    waiter.wait(InstanceIds=instance_ids)

    # Register with ALB target group
    targets = [{'Id': iid} for iid in instance_ids]
    client.register_targets(TargetGroupArn=tg_arn, Targets=targets)

    print(f"Launched and registered helper instances: {instance_ids}")
    return {"helper_instances": instance_ids}