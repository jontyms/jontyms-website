---
title: "The Horse Plinko Incident (2023)"
date: 2023-10-14T07:41:52-04:00
draft: false
ShowToc: true
params:
  ShowToc: true
author: "Jonathan Styles"
description: "Summary of a my experience in the Horse Plinko Cyber Challenge 2023 (HPCC1). Covers competition details, cybersecurity challenges, preparation strategies, and lessons learned. Emphasizes the importance of backups, threat hunting, and persistent detection."
tags: ["The Horse Plinko Incident", "HPCC1", "Cybersecurity competition", "Hack@UCF", "Cyber challenge", "Linux security", "Windows security", "Capture the flag", "CTF competition", "Cyber defense", "Cybersecurity strategies", "Blue team tactics", "Cybersecurity adventure", "Red team vs blue team", "IT security", "Plinkterns", "Cybersecurity challenges", "Hackathon", "Cybersecurity events", "HPCC1 competition"]
---

Hey everyone,

I can't help but dive into this blog post without first tipping my virtual hat to the brilliant minds behind the scenes. To the organizers of the recent HPCC1 competition, you’ve orchestrated something truly epic. Your dedication, creativity, and the sheer complexity of the challenges pushed us to the limits of our knowledge and skills. And for that, I am genuinely thankful.

Competing in the [Horse Plink Cyber Challenge 1](https://plinko.horse) (henceforth know as HPCC1) was not just a battle of wits and technical prowess; it was an adventure. From the adrenaline-pumping moments to the late-night problem-solving sessions, every second was a testament to the thoughtful planning that went into creating this event.

So, here’s a massive shoutout to the organizers. Your dedication to [Hack@UCF](https://www.hackucf.org/) and your innovative approach to challenges have left a lasting impression on all of us who participated. The experience was nothing short of exhilarating, and it’s all thanks to your hard work and dedication.

# The Game
<blockquote>
<p>
Welcome, new cybersecurity hires (and by "cybersecurity hires," I mean "unpaid interns"), to the International Horse Plinko League (IHPL)!
As the CEO of the International Horse Plinko League, it is my pleasure to welcome you to our great company. It’s certainly an interesting time to join us! After our expansion to an American branch in our last wave of hiring, we’ve continued to innovate new ways of bringing Horse Plinko to serve new markets and diverse business needs including the latest industry buzzwords, like "large language models" and "AI."
</p>
<p>
"Mr. Keating," you say, "how can dropping horses doused in Plinko Sauce™ down peg-laden boards have ANY business application at all, let alone applications in AI?" Well, your skepticism, though warranted, is in this case baseless! In collaboration with Dr. Ravy, our newest Senior Science Analyst, IHPL is exploring the new field of Bayesian Computing. Recently discovered, this field is similar to conventional and quantum computing. Instead of using bits (zero or one) or qubits (zero or one or maybe both?), Bayesian Computing makes use of pbits –  Probability-bits or Plinko-bits, depending on who you ask. Instead of being zero or one, pbits are either greater than 50% chance of being one or greater than 50% chance of being zero. Plinko boards are uniquely suited to the task of determining the final value of these pbits, and certain… emergent properties start to occur when horses are used, especially for artificial intelligence applications.
</p>
<p>
Much as it always is, the group of cybercriminals that call themselves the “Horse Liberation Front” have stated their clear opposition to our business practices in general and our pursuit of artificial intelligence in specific,
  </p>
- HPCC1 Blue Team Packet
</blockquote>

HPCC1 has some elements of role play all the competitors were called 'Plinkterns.' We were serving as unpaid interns for our corporate overlords.
The scoring consisted 65% uptime checks and 35% injects, which are business tasks related to our duties, requiring a written submission via the official competition Discord.

{{< bundle-image name="hpcc1_netmap_99.png">}}

For the competition we had 4 boxes we needed to secure 2 windows boxes running dns and wordpress, and 2 linux boxes. One was debian with a mariadb database on it and one was ubuntu with an vsftp server and a apache webgame server on it. The two linux boxes were scored with ssh as well. Our teammates Conner and Kevin handled the windows boxes and me an Ardian handled the linux boxes. (And a mostly ignored splunk box that was out of scope for red team)
# Preparation
As soon as we formed our team we started sending links back and forth with commands and blogs and stackoverflows all with cool ideas about what we should todo. ([This youtube video is great for learning about threat hunting](https://www.youtube.com/watch?v=EFgZPxpLKS0)). We decided our approach would be to write a script that removed all the low hanging fruit to buy us time to secure the more complex stuff. Speed was very important because the boxes would start "clean" and the instant the network unfroze red team would run scripts of their own.
```bash {linenos=true}

#!/bin/bash
#Thrown together by Ardian Peach (oatzs) for the Fall 2023 KnightHacksHorse Plinko Cyber Challenge at the University of Central Florida
passwd -l root

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
#SSH whitelist
echo "AllowUsers hkeating ubuntu" >> /etc/ssh/sshd_confi

apt install ufw -y
#metasploit default port
ufw deny 4444

#sets firewall rules
ufw allow 'Apache Secure' #443
ufw allow OpenSSH
ufw allow ftp
ufw allow http
ufw allow 20 tcp
ufw allow 990 tcp
ufw enable


sudo chown -R root:root /etc/apache2

#removing nopasswdlogon group
echo "Removing nopasswdlogon group"
sed -i -e '/nopasswdlogin/d' /etc/group

chmod 644 /etc/passwd

#Backup file required for scoring
cp /files/Seabiscuit.jpg ~
cp /files/Seabiscuit.jpg /bin
cp /files/Seabiscuit.jpg /media
cp /files/Seabiscuit.jpg /var
chattr +i /files/Seabiscuit.jpg

#allow only the scoring user
echo "hkeating" >> /etc/vsftpd.userlist
echo "userlist_enable=YES" >> /etc/vsftpd.userlist
echo "userlist_file=/etc/vsftpd.userlist" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf
echo "chroot_local_user=NO" >> /etc/vsftpd.conf

#general
echo "anonymous_enable=NO" >> /etc/vsftpd.conf
echo "local_enable=YES" >> /etc/vsftpd.conf
echo "write_enable=YES" >> /etc/vsftpd.conf
echo "xferlog_enable=YES" >> /etc/vsftpd.conf
echo "ascii_upload_enable=NO" >> /etc/vsftpd.conf
echo "ascii_download_enable=NO" >> /etc/vsftpd.conf
service vsftpd restart


#updates the repo so we can download our very useful tools
apt update -y
apt install ranger -y
apt install fail2ban -y
apt install tmux -y
apt install curl -y
apt install whowatch -y

wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64

for user in $( sed 's/:.*//' /etc/passwd);
	do
	  if [[ $( id -u $user) -ge 999 && "$user" != "nobody" ]]
	  then
		(echo "PASSWORD!"; echo "PASSWORD!") |  passwd "$user"
	  fi
done

pwck

chattr +i /etc/vsftpd.userlist
chattr +i /etc/vsftpd.conf
chattr +i /etc/ssh/sshd_config
```
The scoring user had to login with password so that threw off some of the typical ssh security advice you could use something like
```
Match User hkeating
PasswordAuthentication yes
Match all
PasswordAuthentication no
```
But we ended up just using user whitelists.
# Chapter 1 The Game Begins
```bash
ssh debian@172.16.4.5 -c "su     do iptables -A INPUT -p tcp --dport 22 -j ACCEPT && sudo iptables -A INPUT -p      tcp --dport 3306 -j ACCEPT && sudo iptables -A INPUT -j DROP"
```
This command cost me the first 10 minutes of the competition. 10 crucial minutes. Because while the red team was loading up the machine with backdoors malware and misconfigurations, I was trying to figure out why dns was broken. Eventually I found that it was all outbound connections and ran ```iptables -F``` quickly followed by the script we created in chapter 0. Next I checked for sus connections using ```sudo ss -peunt``` and proceeded with some basic threat hunting.
```bash
who -a
sudo nano /etc/ssh/sshd_config
sudo nvim /etc/ssh/sshd_config.d
htop
sudo apt install debsums
sudo debsums
systemctl list-units

```
Then while looking in the systemd services I found the worst malware ever Jenkins. Some ```sudo systemctl disable jenkins && sudo systemctl stop jenkins && sudo usermod -L jenkins``` threat eliminated. Next I look through users ```sudo usermod root -L``` to disallow root login. Next I ran [PSPY](https://github.com/DominicBreuker/pspy) while maybe not the best tool for blue teamers it was still great to see all the processes that got started on your box.
## Database
Now to the main attraction on my box the database. This along with ssh were the only 2 scored services on my box. The database was mariadb. First I ran ```sudo mysqldump --all-databases -p``` so that I could restore if my ham handed database admin broke some stuff. Next I ran ```sudo mysql_secure_installation``` which walked me through setting a root password and deleting annon users and deleting the test db. Next I logged into mysql and ran some queries first ```USE mysql;``` followed by ```SELECT User,Host,Password FROM mysql.user;``` Then created a wordpress user and granted it privileges
```sql
CREATE USER 'wordpress'@'172.16.4.7' IDENTIFIED WITH authentication_plugin BY '***';
GRANT ALL ON wordpress.* TO 'wordpress'@'172.16.4.7';
```
Password created by [diceware](https://diceware.dmuth.org/)
# Chapter 2
After Lunch the fun really started other than finding a few ssh keys in ~/.ssh/authorized keys nothing really happened on the db box. The real fun was on the game box. Upon logging in he ran the same script as me and started securing vsftp. I was called in to fix a 403 error in the apache server.
```php
<Directory /var/www/>
        Options -Indexes -FollowSymLinks
        AllowOverride None
        Require all granted <--- was set to denied
</Directory>
```
After that apache came back up and we started notice red team getting shells on the box (thanks to pspy). I decided to look into the apache access log.
```systemverilog
10.4.10.4 - - [08/Oct/2023:15:08:28 +0000] "GET /scoreboard/scorecheck.php?check=c3VkbyBpZA%3D%3D HTTP/1.1" 200 678 "http://172.16.4.4/scoreboard/scorecheck.php" "Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"
```
Thats strange all the other scorechecks are coming from go-http-client are where get requests to /web-config.json or /index.html
```systemverilog
172.16.255.221 - - [08/Oct/2023:15:09:05 +0000] "GET /web-config.json HTTP/1.1" 200 342 "-" "Go-http-client/1.1"
172.16.255.221 - - [08/Oct/2023:15:09:35 +0000] "GET /index.html HTTP/1.1" 200 2071 "-" "Go-http-client/1.1"
```
and sure enough at /var/www/scorebaord/scorecheck.php
```php
<title>PHP Web Shell</title>
<html>
<body>
    <!-- Replaces command with Base64-encoded Data -->
    <script>
    window.onload = function() {
        document.getElementById('execute_form').onsubmit = function () {
            var command = document.getElementById('check');
            command.value = window.btoa(command.value);
        };
    };
    </script>
```
Next on the game box I ran ```debsums -c``` and found ```/lib/x86_64-linux-gnu/security/pam_unix.so``` was modified ran
```shell
dpkg -S /lib/x86_64-linux-gnu/security/pam_unix.so
apt reinstall libpam-modules
```
Then we made the fatal mistake having to much uptime. The one thing red team cant stand is people actually doing good.
So red team began messing with us ```mv /bin/ls /bin/sl```  I fixed it by running ```sudo apt reinstall coreutils```.
Basically scorched earth
```bash
rm -rf /var/www/html/*
rm -rf /srv/ftp/*
killall vsftpd
killall vsftpd
killall vsftpd
killall vsftpd
killall vsftpd
killall vsftpd
```
We were able to restore ftp by killing the fork bomb and moving one of our hidden Seabiscuits.jpg back into place.

```bash
bash > /dev/urandom
iptables -I INPUT -p tcp --dport 22 -j DROP
```
At the end of the game we had ftp up but our apache web game was yetted and we didn't have a backup but all our other services were up.

# Summary of Findings and Future Recommendations
### Better Finding of Persistance
After consulting with the red team after the game we learned the only persistance they had left was a [sliver](https://github.com/BishopFox/sliver) beacon on the game box. It was in /etc/cron.d/scheduled_tasks
```crontab
* * * * * /bin/sh -c /usr/bin/flock -n /tmp/fcj.lockfile /bin/ssһd
```
but wait thats just ssh. No its ssh[d](https://unicodeplus.com/U+04BB) Cyrillic Small Letter Shha. GG red team.
### Switch to ansible for initial config scrips
It was too time consuming to download ```chmod +x``` and run the scripts ansible would solve that problem.
### Find bad binaries
```debsums``` only checks dpkg installed files it doesn't find stuff put there by ne'er-do-wells. Still working on a solution.
### Networking logging is important
They had splunk setup but none of us knew how to use it so we had no connection logs.
### Backups Backups and Backups
Upon getting familiar with your environment make a list of files that need to be backed up and the restore procedures for each service. We could have been screwed if red team rm'd /var/www any earlier.
