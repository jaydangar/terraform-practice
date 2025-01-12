#!/bin/bash

# Install Apache HTTP Server
sudo yum update -y
sudo yum install httpd -y

# Start Apache and enable it on boot
sudo systemctl start httpd
sudo systemctl enable httpd

# Create a "Hello, World" page
echo "Hello, World!!!" | sudo tee /var/www/html/index.html