# Privoxy

[Privoxy](https://www.privoxy.org) is a simple HTTP/S reverse proxy for Prowlarr and other *arr apps using the already existing VPN container.  
Tested with PIA VPN, other modifications might be necessary depending on your provider.  


## Installation

Enable Privoxy by setting `COMPOSE_PROFILES=privoxy`.  

To enable it on Prowlarr, head to Settings > Indexers > Http.  
Add "vpn" as host, 8118 as port, give it a tag/label, then click on "test".  
Once working, add the tag/label to each indexer to proxy your connection through the VPN/VPN container.  
