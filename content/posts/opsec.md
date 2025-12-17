---
title: "What I do for my Cybersecurity"
date: 2025-12-16T21:40:35-05:00
draft: false
author: "Jonathan Styles"
tags: ["security", "opsec", "privacy"]
description: This is not necessarily a guide but a personal account of what I do for my cybersecurity and what you should do.
---
# Accounts and Logins
## 1. Use a Password Manager
I use [Bitwarden](https://bitwarden.com/) for all my passwords most of it features are free, I pay them so I can use their [Emergency Access](https://bitwarden.com/help/emergency-access/) feature. I have used [KeePassXC](https://keepassxc.org/) in the past, and I would trust [1Password](https://1password.com/) but haven't tried it yet. 

[Privacy Guides Password Mangers](https://www.privacyguides.org/en/passwords/)

### Choosing a Master Password
I choose a strong master password that is unique and not easily guessable. This is the single most important password in my life. I rotate it every 1 year (I don't necessarily that that's required). I printed out and used [EFF Diceware](https://www.eff.org/dice) to generate a strong password, with real dice. You can also use [Diceware](https://atoponce.github.io/webpassgen/index.html) to generate a strong password online. Use 5 to 7 words. This doesn't look as secure as random characters, but it is trust me. 

## 2. Use Two-Factor Authentication (2FA)
I use passkeys, my physical Yubikey or TOTP in [aegis](https://getaegis.app/) as much as possible. 

### Yubikey
I use a Yubikey for 2FA on my most important accounts. (Domain registration, email, Github, Cloudflare) I have two Yubikeys, I add both to each account. I carry one with me and keep in a secure undisclosed location. 

### TOTP
I use TOTP on all the reset of my accounts. I use [Aegis](https://getaegis.app/) for TOTP. Each year I print out my current TOTP code and store them in a secure undisclosed location. I also have encrypted cloud backups of my TOTP codes. On iOS I would trust [Ente Auth](https://ente.io/auth/).

### Passkeys
I use passkeys on all my accounts that support it. I store them in [Bitwarden](https://bitwarden.com/) so that I can access them from any device. There is very little reason not to use passkeys.

### Do Not Use Email or SMS
I really really don't want to use email or SMS for 2FA. But some sites force me. I use a very secure dedicated email for my accounts that require 2fa. Don't use SMS as much as possible. Wherever possible I go in and disable recovery email and SMS (very few sites support this).

## Email
I use a few email providers. I really like [Fastmail](https://www.fastmail.com/), I don't like [ProtonMail](https://protonmail.com/) as much. I use [SimpleLogin](https://simplelogin.io/) for my email aliases. Pretty much all my accounts use a custom email alias on my using my custom domain. If I lose any email provider, I can just migrate the domain to another provider. Using a custom email alias makes it a bit more secure and allows me to detect which company is spamming me or sharing my email with others.

# Computers and other Primary Computing Devices

I will admit the security posture of my devices is very weak. I am expected not to screw up my computer will not save me. 
## Full Disk Encryption
I use full disk encryption on all my computers everywhere I possibly can. I prefer full disk encryption because it means I can decide at any point to just remove the disk and give it to someone else without worrying about destroying the data or drive. For most of my devices the boot drive is decrypted with the TPM. For more secure devices I would recommend using a password or passphrase instead of a TPM. PLEASE PLEASE if you use TPM or Bitlocker safe the recovery key. I have seen some many people lose data to Bitlocker by not having the recovery key, it is not if it is when you will need the recovery key.

## Software
I use Linux (Fedora) on most of my systems. I don't think Linux is necessarily more secure it is just my preference. Being very selective about what software you install is very important.

## Backups 
I use [Backblaze](https://www.backblaze.com/) for my backups. I use their B2 storage with Restic. I would recommend you try their dedicated computer backup if you run Windows or MacOS. I like Backblaze because they will ship you a drive with your data on it making your recovery faster. 

Also most of my most important files that are synced to my Nextcloud instance on my home server and that is backed up to Backblaze. That gives me my 3 copies in 2 locations. 

## Ublock Origin
I love it, I install it on all my browsers. This is my reason for using Firefox in most places. Where I can't use the full version I use Ublock Lite.

## Comments
{{< chat .Name >}}
