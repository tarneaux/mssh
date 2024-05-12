#!/bin/bash -e

if [ $(find /keys -type d | wc -l) != 1 ] || [ $(find /keys -type f | wc -l) = 0 ]; then
    echo "The /keys volume needs to contain at least one file and no directories."
    exit 1
fi

[ -f "/hostkeys/ssh_host_rsa_key" ] || ssh-keygen -q -N "" -t rsa -b 4096 -f /hostkeys/ssh_host_rsa_key
[ -f "/hostkeys/ssh_host_ecdsa_key" ] || ssh-keygen -q -N "" -t ecdsa -f /hostkeys/ssh_host_ecdsa_key
[ -f "/hostkeys/ssh_host_ed25519_key" ] || ssh-keygen -q -N "" -t ed25519 -f /hostkeys/ssh_host_ed25519_key

for user in $(ls /keys); do
    if [ -d /home/"$user" ]; then
        WUID=$(stat -c "%u" /home/"$user")
        WGID=$(stat -c "%g" /home/"$user")
        # Create the user with the correct GID and UID to match the permissions
        # of their home directory.
        # 
        # Unlock user to allow SSH login. This effectively allows anybody who could
        # login with a password to bypass the password prompt, but it should be fine
        # on Alpine since no binaries have their SUID and/or SGID bits set.
        adduser --shell /bin/bash -D "$user" -g $WGID -u $WUID \
            && passwd -u "$user" || true
    fi
done

for user in $(ls /keys); do
    if [ ! -d /home/"$user" ]; then
        adduser --shell /bin/bash -D "$user"
        passwd -u "$user"
    fi
    chmod 700 /home/"$user"
    
    mkdir -p /home/"$user"/.ssh
    cp -f /keys/"$user" /home/"$user"/.ssh/authorized_keys

    chown "$user:$user" /home/"$user"/.ssh /home/"$user"/.ssh/authorized_keys
    chmod 700 /home/"$user"/.ssh
    chmod 600 /home/"$user"/.ssh/authorized_keys
done

echo "Starting SSHD"

KEYS="$(ls /hostkeys | grep -v '\.pub' | sed 's|^|-h /hostkeys/|g' | sed 's/$/ /g' | tr -d "\n")"

/usr/sbin/sshd -De $KEYS
