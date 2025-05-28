Simple HTTP/S reverse proxy for Prowlarr (and other *ARR apps) using the already existing VPN container.
Only tested with PIA VPN, other modifications might be necessary depending on your setup.


To enable it on Prowlarr, head to Settings > Indexers > Http 
And add "vpn" as host, 8118 as port, give it a tag/label, then click on "test".
Once working, add the tag/label to each indexer to proxy your connection through the VPN/VPN container.
