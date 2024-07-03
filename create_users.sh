#!/bin/bash

# Define log file and secure passwords file
LOG_FILE="/var/log/user_management.log"
SECURE_PASSWORDS_FILE="/var/secure/user_passwords.txt"

# Ensure the log and secure directories exists
mkdir -p /var/log
mkdir -p /var/secure

# Clear previous logs and passwords
> $LOG_FILE
> $SECURE_PASSWORDS_FILE

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Creates a user with a random password
create_user() {
    local username="$1"
    local groups="$2"

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping."
        return
    fi

    # Create personal group
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        log_message "Group $username created."
    else
        log_message "Group $username already exists."
    fi

    # Create user with personal group and home directory
    useradd -m -g "$username" -G "$groups" "$username"
    log_message "User $username created and added to groups $groups."

    # Set up home directory permissions
    chmod 700 "/home/$username"
    chown "$username:$username" "/home/$username"
    log_message "Home directory for $username set up with appropriate permissions."

    # Generate a random password and set it for the user
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd
    log_message "Password for user $username set."

    # Store the password securely in comma-delimited format
    echo "$username,$password" >> $SECURE_PASSWORDS_FILE
}

# Ensure the input file is provided
if [ -z "$1" ]; then
    echo "You gaz include input file nau: $0 <input_file>"
    exit 1
fi

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Remove any leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create the user and set up everything
    create_user "$username" "$groups"
done < "$1"

log_message "User management script completed."

# Set permissions for the secure passwords file
chmod 600 $SECURE_PASSWORDS_FILE
log_message "Permissions for $SECURE_PASSWORDS_FILE set to 600."

echo "User management script completed. Check $LOG_FILE for details."
