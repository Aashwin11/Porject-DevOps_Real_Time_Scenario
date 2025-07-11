#!/bin/bash -xe

# Update package lists
echo "Updating package lists..."
apt update -y

# Install Apache2
echo "Installing Apache2..."
apt install -y apache2

# Start and enable Apache2 service
echo "Starting and enabling Apache2..."
systemctl start apache2
systemctl enable apache2

# Wait for Apache's web root to be created (just in case)
WEB_ROOT="/var/www/html"
for i in {1..10}; do
    if [ -d "$WEB_ROOT" ]; then
        break
    fi
    sleep 1
done

# Fetch instance ID from the Instance Metadata Service (IMDSv2)
echo "Fetching instance ID from metadata service (IMDSv2)..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# Create a custom index.html file with the instance ID
echo "Creating custom index.html in $WEB_ROOT..."
cat <<EOF > "$WEB_ROOT/index.html"
<!DOCTYPE html>
<html>
<head>
    <title>My Ubuntu 24.04 Web Server</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #e6f7ff; color: #333; text-align: center; padding-top: 50px; margin: 0; }
        .container { background-color: #ffffff; border: 1px solid #cceeff; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); display: inline-block; padding: 40px; max-width: 700px; margin: 20px; }
        h1 { color: #007bff; font-size: 2.5em; margin-bottom: 20px; }
        p { font-size: 1.2em; line-height: 1.6; }
        .instance-id { font-weight: bold; color: #dc3545; background-color: #ffe6e6; padding: 5px 10px; border-radius: 5px; display: inline-block; margin-top: 10px; }
        .footer { margin-top: 40px; font-size: 0.9em; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Your Ubuntu 24.04 Web Server!</h1>
        <p>This page is proudly served by an Apache web server on your EC2 instance.</p>
        <p>Your EC2 Instance ID is:</p>
        <p class="instance-id">${INSTANCE_ID}</p>
        <p>This entire setup was automated using EC2 User Data from Terraform.</p>
    </div>
    <div class="footer">
        <p>&copy; Apache Web Server on AWS EC2</p>
    </div>
</body>
</html>
EOF

echo "User data script for Ubuntu 24.04 completed successfully."