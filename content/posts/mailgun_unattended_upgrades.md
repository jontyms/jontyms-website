---
title: "Mailgun Unattended Upgrades Notifications"
date: 2022-01-27T16:27:12-05:00
draft: false
---
# No longer recommend

Tested on Ubuntu 20.04. I provide no guarantees. 

This is for you Alex from Selfhosted. No more gmail changing auth schemes and breaking your email alerts. 
### Step One
Acquire a Mailgun account https://signup.mailgun.com/new/signup.
Get three month for free then only $0.80(USD) per 1000 emails.
You might need a domain, I'm not sure.
### Step Two
Acquire STMP credentials from Mailgun. 
They will probably change their UI as soon as I post this so take this with a grain of salt. 
1. Go to the main dashboard
2. Next to the domain name press Domain Settings
3. Goto STMP credentials
4. Create a login
### Step Three 
SSH into the server. 
Run ``sudo apt-get install ssmtp mailutils ``
Run ``sudo nvim /etc/ssmtp/ssmtp.conf``



```
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=root

# The place where the mail goes. The actual machine name is required 
# MX records are consulted. Commonly mailhosts are named mail.domain.
mailhub=smtp.mailgun.org:587

# Where will the mail seem to come from?
rewriteDomain=domain_for_mailgun

# The full hostname
hostname=HOSTNAME

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
#FromLineOverride=YES
UseTLS=Yes
UseSTARTTLS=Yes
authuser=mailgunstmpuser@domain_for_mailgun
authpass=mailgunpass
```
Run ``sudo nvim /etc/apt/apt.conf.d/50unattended-upgrades ``


``` // Send email to this address for problems or packages upgrades
// If empty or unset then no email is sent, make sure that you
// have a working mail setup on your system. A package that provides
// 'mailx' must be installed. E.g. "user@example.com"
Unattended-Upgrade::Mail "EMAIL TO RECEIVE UPDATES";

// Set this value to one of:
//    "always", "only-on-error" or "on-change"
// If this is not set, then any legacy MailOnlyOnError (boolean) value
// is used to chose between "only-on-error" and "on-change"
Unattended-Upgrade::MailReport "on-change"; 
```

### Testing 
Run `` mail  EMAIL TO RECEIVE UPDATES``
Press enter on CC:
Type subject 
Type body press ctrl-d


Mail log at ``/var/log/mail.log`` 
Check Mailgun web logs 


You can change ``Unattended-Upgrade::MailReport "always"; ``
and run `` sudo unattended-upgrades --verbose ``
## Comments
{{< chat mailgun.unattended.upgrades >}}