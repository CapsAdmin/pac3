# PAC3

---

PAC3 gives you the ability to personalize your player model's look by placing objects and effects on yourself. You can go from putting just a hat on your head to creating an entire new player model. PAC works on any entity and can also be used as a way to make custom weapons and npcs for your gamemode easily. 

You can wear your outfit on any server with PAC3 and everyone should be able to see it on you as long as they have the content you used.

---
# New combat-related parts:

	damage_zone: deals damage (a more direct and controllable alternative to projectiles)
 
 	hitscan: shoots bullets
	
 	lock: teleport/grab
	
	force: does physics forces
 
 	health_modifier: changes your health, armor etc
	
	interpolated_multibone: morphs position / angles between different base_movables nodes, like a path


The combat features work with the principle of consent. The lock part especially is severely restricted for grabbing players, for what should be obvious reasons. You can only damage or grab players who have opted in for the corresponding consent.

	pac_client_damage_zone_consent 0
	pac_client_hitscan_consent 0
	pac_client_force_consent 0
	pac_client_grab_consent 0
	pac_client_lock_camera_consent 0

There are also commands for clients to free themselves if they're being grabbed.

 	pac_break_lock
	pac_stop_lock

Multiple options exist for servers to prevent mass abuse. Although I might've had things to say about server owners being resistant to new disruptive features, I've come to some compromises in the form of cvars, size limits, damage limits, which combat parts are allowed, several net-protecting options to ease the load on the server's processing and on the network (reliable channel)... With pac_sv_block_combat_features_on_next_restart on, the server doesn't even create the network strings or the net receivers for corresponding disabled parts when starting up.

In singleplayer sandbox, the default for the combat features will be 1 when creating the convars the first time. In other gamemodes and in multiplayer, however, it will be 0.

	pac_sv_combat_whitelisting 0
	pac_sv_damage_zone 0
	pac_sv_lock 0
	pac_sv_lock_grab 0
	pac_sv_lock_teleport 0
	pac_sv_lock_max_grab_radius 200
 	pac_sv_combat_enforce_netrate 0
	pac_sv_entity_limit_per_combat_operation 500
 	pac_sv_entity_limit_per_player_per_combat_operation 40
  	pac_sv_player_limit_as_fraction_to_drop_damage_zone 1
	pac_sv_block_combat_features_on_next_restart 1
	pac_sv_combat_distance_enforced 0
 	...


# Editor features:

## Bulk Select

Select multiple parts and do some basic operations repeatedly. By default it's CTRL + click to select/unselect a part.

Along with it, bulk apply properties is a new menu to change multiple parts' properties at once.

	
## Extensive customizability (user configs will be saved in data/pac3_config)

Customizable shortcuts for almost every action (in the pac settings menu).

Reordering the part menu actions layout (in the pac settings menu).

Changing your part categories, with possible custom icons.

Colors for the event wheel (with a menu) + a new grid style for command events that doesn't move too much.


## Expanded settings menu

Clients can configure their editor experience, and owners with server access can configure serverwide combat-related limits and policies.

## Favorite assets for quick access (user configs will be saved in data/pac3_config)

right click on assets in the pac asset browser to save it to your favorites. it can also try to do series if they end in a number, but it might fail. right clicking on the related field will bring it up in your list
	
## Popup system

select a part and press F1 to open information about it. limited support but it will be useful later on. It can be configured to be on a part in your viewport, on your cursor, next to the part's tree label ...
 
## Editor copilot : Foolproofing and editor assist

Selecting an event will pick an appropriate operator, and clicking away from a proxy without a variable name will notify you about how it won't work, telling you to go back and change it

Writing a name into an event's type will create a command event with that name if the name isn't a recognized event type, so you can quickly setup command events.

auto-disable editor camera to preview the camera part when creating a camera part

auto-focus on the relevant property when creating certain parts

# Reference and help features

proxy bank: some presets with tooltip explanations. right click on the expression field to look at them
 
command bank: presets to use the command part. again, right click on the expression field to look at them

built-in wiki written by me, for every part and most event types: short tooltips to tell you what a part does when you hover over the label when choosing which part to create, longer tutorials opened with F1 when you select an existing part.


# Miscellaneous features

## Part notes

a text field for the base_part, so you can write notes on any part.

## Prompt for autoload

option to get a prompt to choose between your autoload file, your latest backup or latest loaded outfit when starting.

## Queue prop/NPC outfits (singleplayer only)

option so that, when loading an outfit for props/NPCs, instead of hanging in the editor and needing to reassign the owner name manually, pac will not wear yet, but wait for you to spawn an appropriate prop or entity that had the outfit.

## pac_event_sequenced

pac_event but with more options to control series of numbered events.

pac will try to register the max number when you create a command event with the relevant number e.g. to reach command10 you need to have a command event with the name command10. rewear for best results.

examples:

this increments by 1 (and loops back if necessary)

	pac_event_sequenced hat_style +
 
this sets the series to 3

 	pac_event_sequenced hat_style set 3

keywords for going forward: +, add, forward, advance, sequence+

keywords for going backward: -, sub, backward, sequence-

keyword to set: set


## Improvements to physics and projectile parts

Set the surface properties, preview the sizes and some more.

For projectiles to change the physics mesh, it might have some issues.
 
## Bigger fonts for the editor + pac_editor_scale for the tree's scale

just a quick edit for people with higher resolution screens

## New tools

-destroy hidden parts, proxies and events. I also call it Ultra cleanup. This is a quick but destructive optimization tool to improve framerate by only keeping visible parts and obliterating non-static elements. You can mark parts to keep by writing "important" in their notes field.

<img width="650" alt="Screenshot 2023-09-02 at 06 54 28" src="https://github.com/CapsAdmin/pac3/assets/204157/276c7bfc-f5a9-422a-bfb6-683a26981539">

Some links to check out:
* [wiki](https://wiki.pac3.info/start "PAC3 Wiki")
* [steam workshop](http://steamcommunity.com/sharedfiles/filedetails/?id=104691717 "Workshop Version") 
* [discord server](https://discord.gg/utpR3gJ "Join PAC3 Discord Server") 

---
