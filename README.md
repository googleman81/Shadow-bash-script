# Shadow-bash-script
This is an optimizing tool for Geforce Now on a device running macOS.

It's purpose is to optimize the gaming experience running Geforce Now, some additional benefits to system responsiveness may occur.

While the script is comprehensive, it's also somewhat personalized to the users system, a combination of a device running macOS 15.5 and their ISP in combination with the router.

Some of the functionality, like the rate limiting, may already be provided through either said ISP or router and certain functionality proven to be beneficial for this user specifically, like the awdl deactivation loop, may be unwanted or provide negligible benefit under differing conditions, so feel free to remove unwanted items.

Have fun gaming.

Edit: I recommend running the following periodically, it will force a new sign on and reconfiguration of the app settings and is currently the best method I've found to erase performance decreases caused by the accumulation of GFN related files:

rm -rf "$HOME/Library/Application Support/GeForceNOW" \
"$HOME/Library/Application Support/NVIDIA/GeForceNOW" \
"$HOME/Library/Caches/GeForceNOW" \
"$HOME/Library/Caches/NVIDIA" \
"$HOME/Library/Logs/GeForceNOW" \
"$HOME/Library/Logs/NVIDIA" \
"$HOME/Library/Saved Application State/com.nvidia.GeForceNOW.savedState" \
"$HOME/Library/Application Scripts/com.nvidia.GeForceNOW" \
"$HOME/Library/Cookies/com.nvidia.GeForceNOW.binarycookies" \
"$HOME/Library/Preferences/com.nvidia.GeForceNOW.plist" \
"$HOME/Library/Group Containers/group.com.nvidia.GeForceNOW" \
"$HOME/Library/WebKit/com.nvidia.GeForceNOW" \
"$HOME/Library/Application Support/com.nvidia.GeForceNOW"





