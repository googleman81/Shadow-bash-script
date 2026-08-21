# Shadow-bash-script
This is an optimizing tool for Geforce Now on a device running macOS.

It's purpose is to optimize the gaming experience running Geforce Now, some additional benefits to system responsiveness may occur.

I additionally recommend setting the DNS for the device to a proper IPv6 connection (i.e. 2606:4700:4700::1111), enabling stealth mode in the firewall settings and disabling incoming connections from downloaded and signed software.

I also recommend running:

launchctl disable gui/$(id -u)/com.apple.podcasts.PodcastsAgent

launchctl disable gui/$(id -u)/com.apple.podcasts.PodcastContentService

This will disable background activity from the Podcast app, which may cause latency or jitter.
It will survive a reboot but is easily reversible by using the exact same command while replacing "disable" with "enable".

If you just want the networking improvements apply sudo sysctl -w net.inet... in Terminal for the values represented in lines 275-285 i.e.
sudo sysctl -w net.inet.tcp.accurate_ecn=1

Have fun gaming.







