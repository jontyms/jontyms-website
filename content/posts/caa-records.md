---
title: "Securing Your Domain with CAA Records: Prevent Unauthorized Certificate Issuance"
date: 2024-09-25T12:18:31-04:00
draft: False
author: "Jonathan Styles"
Tags: ["TLS", "SSL", "Certificate Authorities", "DNS", "CAA Records", "Cybersecurity", "Domain Security", "WatchTowr Labs"]

Description: An in-depth guide on securing domain ownership by using Certificate Authority Authorization (CAA) records. This post highlights the vulnerability exposed by WatchTowr Labs and explains how to implement fixes, including CAA records, certificate transparency monitoring, and DNSSEC, to protect your domain from unauthorized certificate issuance and malicious actors.
---

You may have seen a recent post by WatchTowr titled [We Spent $20 To Achieve RCE And Accidentally Became The Admins Of .MOBI](https://labs.watchtowr.com/we-spent-20-to-achieve-rce-and-accidentally-became-the-admins-of-mobi/).
The TLDR is that WatchTowr Labs discovered a major vulnerability in the .MOBI TLD by purchasing an expired WHOIS server domain
for $20, allowing them to control WHOIS queries. They found that many systems, including Certificate Authorities (CAs)
responsible for issuing TLS/SSL certificates, were querying this outdated WHOIS server, which enabled WatchTowr to spoof domain ownership information, namely emails.
This undermined the CA process, highlighting a significant flaw in the trust-based TLS/SSL certificate issuance system, making it exploitable by malicious actors.

This post highlights a few issues with the current CA system, namely:
1. WHOIS sucks. It's unencrypted, unauthenticated, and untrustworthy. Anyone who MITMs the certificate authority, compromises the WHOIS server, can just publish whatever they want.
2. Emails are a terrible way to verify domain ownership. They can be intercepted by malicious actors.

With all the discussion about this post, I saw little discourse about how to prevent this from happening to you.

# Easy fix #1
Use certificate transparency monitoring. There are a few services that will monitor your domain for new certificates listed [here](https://certificate.transparency.dev/monitors/).
Use one, please. It's better to know what is happening than not. If you see an unexpected certificate, you can take action.
Most ACME providers will allow you to revoke a certificate if you can prove you own the domain.

# Easy fix #2
Use [cert.sh](https://crt.sh/) or similar to manually monitor your domain for certificates.

# Harder Fix (Using CAA Records)

## What are CAA records?
Certificate Authority Authorization (CAA) records are DNS records that specify which certificate authorities (CAs) are allowed to issue certificates for a domain.
The [CA/Browser Forum](https://cabforum.org/) voted to make CAA records mandatory in 2017. This provides you with control over who and how CAs can issue certificates for your domain.

## How does this solve the problem?
This can ensure only trusted CAs can issue certificates, with (optionally) the authentication method you specify.
This can prevent a malicious actor from using a CA you do not trust to issue a certificate for your domain.

## Step 1 (Optional) - Set up DNSSEC
If you have not already set up DNSSEC for your domain, do so. This will help prevent DNS spoofing attacks. This can make it harder to forge DNS records and make both CAA and ACME DNS challenges more secure.

## Step 2 - Figure out what and how your organization uses certificates
This is quite time-consuming, especially if your organization is large and has many subdomains.
Using tools like [cert.sh](https://crt.sh/) can help you figure out what certificates are being issued for your domain and who is issuing them.
Get your list of CAs, which certificates they are issuing, and which authentication methods they are using.

## Step 4 - Gather Info about your CAs
You will need information about your CAs' CAA implementation. This can be found in their Certificate Policy (CP) and Certificate Practice Statement (CPS) documents.
Specifically, look for a section on CAA records. Like this one from Let's Encrypt:

> 4.2.1 Performing identification and authentication functions
> ISRG performs all identification and authentication functions in accordance with this CP/CPS. This includes validation per Section 3.2.2.
> Certificate information is verified using data and documents obtained no more than 90 days prior to issuance of the Certificate.
> As part of the issuance process, ISRG checks for CAA records and follows the processing instructions found, for each dNSName in the subjectAltName extension of the certificate to be issued, as specified in RFC 8659 and Section 3.2.2.8 of the Baseline Requirements. The CA acts in accordance with CAA records if present. If the CA issues, the CA will do so within the TTL of the CAA record, or 8 hours, whichever is greater. The CA's CAA identifying domain is letsencrypt.org.
> ISRG maintains a list of high-risk domains and blocks issuance of certificates for those domains. Requests for removal from the high-risk domains list will be considered, but will likely require further documentation confirming control of the domain from the Applicant, or other proof as ISRG management deems necessary.

You will need their CAA identifying domain and to check if they support RFC 8657, which is an optional feature that allows you to specify the authentication method.

## Step 5 - Create your CAA records

Let's Encrypt has great documentation on how to create CAA records [here](https://letsencrypt.org/docs/caa/).

General layout of a CAA record is:
```
example.com. CAA 0 issue "letsencrypt.org"
```

This record allows Let's Encrypt to issue certificates for example.com. The 0 is the flag.
You can use `issuewild` to add different requirements for wildcard certificates. A flag of value 128 informs the CA that if the record includes tags they don't recognize, the certificate should not be issued.

CAA records look for records starting with the same domain name as the CAA record. So if you have a CAA record for `test1.subdomain.example.com`, the CA will look for CAA records for `test1.subdomain.example.com`, `subdomain.example.com`, and `example.com` and will stop when it finds the first CAA record.

You can use a tool like [this](https://sslmate.com/caa/) to help you generate CAA records for all current CAs.

## Step 6 - Optional Extensions
If the CA supports RFC 8657, you can add the `validationmethods` and `accounturi` parameters to your CAA record.

### Validationmethods parameter
This parameter can be added after a Certificate Authority's (CA) identifying domain name to control which validation methods the CA can use to verify domain control. This allows you to restrict the CA to only using methods you trust for domain validation. For instance, to limit the CA to the `tls-alpn-01` method, you would append `;validationmethods=tls-alpn-01` to your CAA record value.

Commonly recognized validation methods include:

- `http-01`
- `dns-01`
- `tls-alpn-01`

### Accounturi parameter
This parameter can be used to specify which ACME accounts are authorized to request certificates for the domain. By including this parameter, you can prevent unauthorized certificate issuance, even if your domain is temporarily compromised, as only the specified ACME account can issue certificates. ACME account URIs typically follow a format like `https://example-ca.com/acme/acct/1234567890`, where the numbers represent the account ID.

These parameters help enhance security by allowing you to control both the validation methods and authorized ACME accounts.

## Step 7 - Monitor your Certificates
Ensure all renewals process as normal, and be proactive in checking that domain issuance is functioning as normal.
Ensure the CAA records and their effects are well documented and understood by all relevant parties.

## Comments
{{< chat caa-records >}}
