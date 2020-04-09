#!/bin/bash
useradd adminuser
useradd notadminuser
echo "1" | passwd --stdin adminuser
echo "1" | passwd --stdin notadminuser
groupadd admin
gpasswd -a adminuser admin # -a add, -d delete
gpasswd -a vagrant admin # -a add, -d delete
bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"
cat > /usr/local/bin/test_login.sh << \EOF
#!/bin/bash
(( `date +%u` < 6 )) || id $PAM_USER | grep "(admin)"
EOF
chmod +x /usr/local/bin/test_login.sh
