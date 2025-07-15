#!/bin/bash -xe

# Update package lists
apt update -y

# Install Apache2 and PHP
apt install -y apache2 php libapache2-mod-php

# Enable PHP module and restart Apache
a2enmod php7.4 || true   # adjust PHP version if needed
systemctl restart apache2
systemctl enable apache2

# Wait for web root
WEB_ROOT="/var/www/html"
for i in {1..10}; do
    if [ -d "$WEB_ROOT" ]; then break; fi
    sleep 1
done

# Create the CPU burning PHP index page
cat <<'EOF' > "$WEB_ROOT/index.php"
        <?php
        // CPU burn ~0.5 sec per request for load testing
        $start = microtime(true);
        while ((microtime(true) - $start) < 0.5) {
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
        </body>
        </html>
EOF
