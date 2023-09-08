# PAC3

---

Welcome to my experimental combat update for PAC3. Here's the overview of the important bits to expect.

I have a major update coming soon, when I finish wrapping some things up, so some of these aren't in yet.


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
	pac_client_lock_camera_consent 1

There are also commands for clients to free themselves if they're being grabbed.

 	pac_break_lock
	pac_stop_lock

Multiple options exist for servers to prevent mass abuse. Although I might've had things to say about server owners being resistant to new disruptive features, I've come to a compromise in the form of cvars. size limits, damage limits, which combat parts are allowed...

	pac_sv_combat_whitelisting 0
	pac_sv_damage_zone 1
	pac_sv_lock 1
	pac_sv_lock_grab 1
	pac_sv_lock_teleport 1
	pac_sv_lock_max_grab_radius 200
 	...


# Editor features:

## Bulk Select

Select multiple parts and do some basic operations repeatedly. By default it's CTRL + click to select/unselect a part.

Along with it, bulk apply properties is a new menu to change multiple parts' properties at once.

	
## Extensive customizability (user configs will be saved in data/pac3_config)

Customizable shortcuts for almost every action (in the pac settings menu).

Reordering the part menu actions layout (in the pac settings menu).

Changing your part categories, with possible custom icons. (no menu, you'll have to edit the pac_part_categories.txt file directly)


## Expanded settings menu

Clients can configure their editor experience, and owners with server access can configure serverwide combat-related limits and policies.

## Favorite assets for quick access (user configs will be saved in data/pac3_config)

right click on assets in the pac asset browser to save it to your favorites. it can also try to do series if they end in a number, but it might fail. right clicking on the related field will bring it up in your list
	
## Popup system

select a part and press F1 to open information about it. limited support but it will be useful later on. It can be configured to be on a part in your viewport, on your cursor, next to the part's tree label ...
 
## Editor autopilot

An idea: correct common mistakes automatically or inform the user about it.

For now, it's only two things: selecting an event will pick an appropriate operator, and clicking away from a proxy without a variable name will notify you about how it won't work, telling you to go back and change it


# Reference and help features

proxy bank: some presets with tooltip explanations. right click on the expression field to look at them
 
command bank: presets to use the command part. again, right click on the expression field to look at them
	
built-in wiki written by me, for every part and most event types: short tooltips to tell you what a part does when you hover over the label when choosing which part to create, longer tutorials opened with F1 when you select an existing part.


# Miscellaneous features

## Part notes

a text field for the base_part, so you can write notes on any part.

## pac_event_sequenced

pac_event but with more options to control series of numbered events.

pac will try to register the max number when you create a command event with the relevant number e.g. to reach command10 you need to have a command event with the name command10. rewear for best results.

examples:

this increments by 1 (and loops back if necessary)

	pac_event_sequenced hat_style +
 
this sets the series to 3

 	pac_event_sequenced hat_style set 3

keywords for going forward: +, add, backward, advance, sequence+

keywords for going backward: -, sub, backward, sequence-

keyword to set: set


## Improvements to physics and projectile parts

Set the surface properties, preview the sizes and some more.

For projectiles to change the physics mesh, it might have some issues.
 
## Bigger fonts for the editor + pac_editor_scale for the tree's scale

just a quick edit for people with higher resolution screens

## New tools

-destroy hidden parts, proxies and events. I also call it Ultra cleanup. This is a quick but destructive optimization tool to improve framerate by only keeping visible parts and obliterating non-static elements. You can mark parts to keep by writing "important" in their notes field.

-Engrave targets: assign proxies and events' target part to quickly allow you to reorganize them in a separate group in the editor.

-dump model submaterials: same as dump player submaterials (prints the submaterials in the console) but for a pac3 model you select in the tree

---

### Thank you for reading. Now go make something cool!

### Yours truly,
### Cédric.
