# PlacePlugins

PlacePlugins allows you to load plugins that are stored with the place file. This makes distributing secure and private plugins to your team super easy!

# How to Use Place Plugins (the easy way)

1. Install [the PlacePlugins plugin](https://www.roblox.com/library/1417014043/Place-Plugins)
2. Open up the place that has place plugins
3. In the `PLUGINS` tab of Roblox Studio, press `Load New` under `PlacePlugins`
4. Always press `Load New` after opening the place. You have to manually load new versions of individual place plugins for security.

# Technical Details and More Information

## Writing Your Own Place Plugins

PlacePlugins go in a PlacePlugins folder inside ServerStorage.

Place plugins run just like normal plugins. Here are three supported formats:
* A Script or LocalScript will become a plugin
* A Folder will become a plugin, and all the scripts/loclascripts inside will run
* A NumberValue with an AssetId will get and load the plugin at the given asset id.

You should develop place plugins as normal plugins, then stick the plugin in the PlacePlugins folder once you're ready to share it with your team.

## The Manage Window

The Manage window (accessible with `PLUGINS > PlacePlugins > Manage`) will:
* show all recognized plugins
* show status individual plugins
* give auto-load options per-plugin
* gives the option to load individual plugins
* gives you the option to disable auto-loading of any plugins
* gives you the option to load every plugin

## Security

PlacePlugins will not automatically run place plugins that it has not previously been told to run by a user. If a place plugin's scripts, localscripts, or modulescripts change then it will treat the plugin as "new" or "unrecognized". In effect, the only plugin code that runs automatically is plugin code that the user has specifically granted permission to run.

Specifically, this is done by:
1. Sha1-hashing all script, localscript, and modulescript sources
2. Sticking those hashes into an array
3. Sorting that array
4. Concatenating that array into a single string
5. Comparing that string to the last saved string for the module name in the current place id