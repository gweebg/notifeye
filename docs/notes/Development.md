## Development Setup


### The Problem

Being used to develop local-only applications, building an application that integrates with an outside service via webhooks (Logz.io), came with some challenges when we discussing about the development environment.

For instance, configuring webhooks in Logz.io requires a valid endpoint to execute the HTTP requests. This meant that, even for testing, we need a valid (SSL-prefered) URL.

This requires a domain, a dns provider and a server.

### Solution

Thankfully, I already meet the requirements. So my half-baked solution involves hosting the application's development server at the homeserver by proxying it via nginx, using Let's Encrypt certificates. Due to my DNS provider being Cloudflare, there is also an added security measure since I proxy all traffic via their servers first.

This setup brings several advantages:

+ **Flexibility**:
    - No need for production-ready releases to test integrations.
    - Enables remote development via SSH, allowing coding from any machine with internet access.

+ **Cost-effectiveness**:
    - Utilizes existing infrastructure, avoiding the need for additional hosting services.

However, it also comes with some disadvantages:

+ **Network dependency**:
    - Requires a VPN to access the development server when working outside the homeserver's network.

+ **Potential latency**:
    - Depending on the network setup, there might be slight delays when accessing the development environment remotely.

### Security

Due to the need of exposing the application to the internet and due to it being a development build, I took the decision of only allowing certain IP addresses to access the application.

This behaviour is achieved via the configuration of an access control list at the virtual host (reverse proxy level).
