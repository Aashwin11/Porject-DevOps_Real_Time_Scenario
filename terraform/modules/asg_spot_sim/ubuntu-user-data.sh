#!/bin/bash -xe
# Update package lists
apt update -y

# Install Apache2 and PHP (for dynamic content)
apt install -y apache2 php libapache2-mod-php

# Enable PHP (ignore error if already enabled)
a2enmod php* || true

# Restart and enable Apache2
systemctl restart apache2
systemctl enable apache2

WEB_ROOT="/var/www/html"
# Remove the default index.html so Apache serves index.php
rm -f $WEB_ROOT/index.html

# Create index.php with CPU burn and instance ID
cat <<'EOF' > $WEB_ROOT/index.php
<?php
$start = microtime(true);
while ((microtime(true) - $start) < 1.0) {
  hash('sha512', uniqid(rand(), true));
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Ubuntu 24.04 Web Server</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>Welcome to Your Ubuntu 24.04 Web Server!</h1>
    <p>Instance ID: <strong><?php echo gethostname(); ?></strong></p>
    <p>If you see this, PHP and CPU burn are working!</p>
</body>
</html>
EOF
