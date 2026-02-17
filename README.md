# Shadow-bash-script
This is an optimizing tool for Geforce Now on a device running macOS.

It's purpose is to optimize the gaming experience running Geforce Now, some additional benefits to system responsiveness may occur.

While the script is comprehensive, it's also somewhat personalized to the users system, a combination of a device running macOS 15.5 and their ISP in combination with the router.

Some of the functionality, like the rate limiting, may already be provided through either said ISP or router and certain functionality proven to be beneficial for this user specifically, like the awdl deactivation loop, may be unwanted or provide negligible benefit under differing conditions, so feel free to remove unwanted items.

Have fun gaming.

Edit:

I additionally recommend setting the DNS for the device to a proper IPv6 connection, enabling stealth mode in the firewall settings and disabling incoming connections from downloaded and signed software.

I also recommend running:

launchctl disable gui/$(id -u)/com.apple.podcasts.PodcastsAgent
launchctl disable gui/$(id -u)/com.apple.podcasts.PodcastContentService

This will disable background activity from the Podcast app, which may cause latency or jitter.
It will survive a reboot but is easily reversible by using the exact same command while replacing "disable" with "enable".







