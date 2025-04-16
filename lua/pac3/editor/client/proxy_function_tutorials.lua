local Tutorials = {}

--basic math functions
Tutorials["none"] = [[none(n) doesn't do anything. it passes the argument straight through. it's only used in easy setup to read an input without modifications.]]
Tutorials["sin"] = [[sin(rad) is the sine wave function. it has a range of [-1,1] and is cyclical.

rad is radians. one full cycle takes 2*PI radians. pi is 3.1416... so a full cycle is around 6.283 radians

sin(0) = 0 (zero crossing on the upward slope)
sin(PI/2) = 1 (the peak)
sin(PI) = 0 (zero crossing on the downward slope)
sin((3/2) * PI) = -1 (the trough / valley)
sin(2*PI) = 0 (zero crossing on the upward slope, starting another cycle)

there are some interesting symmetries and regularities, but either you already know what a sine is, or you don't. I'll just give you some interesting setups

the most typical use involves time.
sin(time()*10)

UCM (uniform circular motion)
when you map a sine and cosine on the position of an object, you trace a circular path by definition. the sine is the height or Y, the cosine is the width or X position.
it's useful for orbits / revolutions
100*sin(3*time()), 100*cos(3*time())

power sines make shorter pulses. even powers make the range [0,1] (they convert every trough into a peak), while odd powers keep the range to [-1,1].
compare these:
sin(time()*5)^10
sin(time()*5)^15

also see nsin and nsin2]]

Tutorials["cos"] = [[cos(rad) is the cosine wave function. it has a range of [-1,1] and is cyclical.

rad is radians. one full cycle takes 2*PI radians. pi is 3.1416... so a full cycle is around 6.283 radians

sin(0) = 1 (the peak)
sin(PI/2) = 0 (zero crossing on the downward slope)
sin(PI) = -1 (the trough / valley)
sin((3/2) * PI) = 0 (zero crossing on the upward slope)
sin(2*PI) = 1 (the peak)

there are some interesting symmetries and regularities, but either you already know what a cosine is, or you don't. I'll just give you some interesting setups

the most typical use involves time.
cos(time()*10)

UCM (uniform circular motion)
when you map a sine and cosine on the position of an object, you trace a circular path by definition. the sine is the height or Y, the cosine is the width or X position.
it's useful for orbits / revolutions
100*sin(3*time()), 100*cos(3*time())

power sines make shorter pulses. even powers make the range [0,1] (they convert every trough into a peak), while odd powers keep the range to [-1,1].
compare these:
cos(time()*5)^10
cos(time()*5)^15

also see ncos and ncos2]]

Tutorials["tan"] = [[tan(rad) is the tangent function. I don't have much to say about it but you can look more up if you wish.
the range is [-inf,inf], it's asymptotic, it represents the slope of a surface if it's perfectly vertical, the slope is practically infinite.

rad is radians. one full cycle takes 2*PI radians. pi is 3.1416... so a full cycle is around 6.283 radians

]]
Tutorials["abs"] = [[abs(n) takes the absolute value. it removes any negative sign. that's all. it's useless if you're always working with positive numbers.]]
Tutorials["sgn"] = [[sgn(n) takes the sign.
if n > 0 then sgn(n) = 1
if n = 0 then sgn(n) = 0
if n < 0 then sgn(n) = -1

idea: you can use sgn with random_once to randomly pick a side with sgn(random_once(0,-1,1)), then multiplying with whatever else you might've had.]]
Tutorials["acos"] = [[acos(cos) is the arc-cosine, the reverse of cos. it will give the corresponding angle in radians.
cos is a cosine value. we expect between -1 and 1]]
Tutorials["asin"] = [[asin(sin) is the arc-sine, the reverse of sin. it will give the corresponding angle in radians.
sin is a sine value. we expect between -1 and 1]]
Tutorials["atan"] = [[atan(tan) is the arc-tangent, the reverse of tan. it will give the corresponding angle in radians.
sin is a tangent value]]
Tutorials["atan2"] = [[atan2(tan) is an alternate arc-tangent, the reverse of tan. it will give the corresponding angle in radians.
tan is a tangent value]]
Tutorials["ceil"] = [[ceil(n) rounds the number up.
ceil(0) = 0
ceil(0.001) = 1
ceil(1) = 1]]
Tutorials["floor"] = [[floor(n) rounds the number down.
floor(0) = 0
floor(0.999) = 0
floor(1) = 1]]
Tutorials["round"] = [[round(n,dec) rounds the number up to a certain amount of decimals
dec is decimal magnitude. 0 if not provided (whole numbers), 1 is tenths, 2 is hundredths, -1 is tens, -2 is hundreds etc.]]
Tutorials["rand"] = [[rand() is math.random. it generates a random number from 0 to 1]]
Tutorials["randx"] = [[randx(a,b) is math.Rand(a,b). it generates a random number from a to b.]]
Tutorials["sqrt"] = [[sqrt(x) is just the square root. it's equivalent to x^0.5
avoid negative values.]]
Tutorials["exp"] = [[exp(base,exponent) is an exponentiation. it's equivalent to base^exponent]]
Tutorials["log"] = [[log(x, base) is the logarithm on a base. logarithms are the reverse of the exponentiation operation.
e.g. since 10^3 = 1000, log(1000,10) = 3]]
Tutorials["log10"] = [[log10(x) is the logarithm on base ten. logarithms are the reverse of the exponentiation operation.
e.g. since 10^3 = 1000, log10(1000) = 3]]
Tutorials["deg"] = [[deg(rad) converts radians to degrees. PI radians = 180 degrees]]
Tutorials["rad"] = [[rad(deg) converts degrees to radians. PI radians = 180 degrees]]
Tutorials["clamp"] = [[clamp(x,min,max) restricts x within a minimum and maximum. if x goes above max, clamp will still return max. if x goes below min, clamp will still return min.
observe clamp(timeex(),0,1) or clamp(10*timeex(),0,50)
it was standard for fades and movement transitions but now ezfade and ezfade_4pt exist to make it easier]]

Tutorials["nsin"] = [[nsin(radians) is the normalized sine.
it is simply 0.5 + 0.5*sin(radians)

whereas sin has the codomain of [-1,1], we may sometimes want a normalized [0,1] for various reasons

keep in mind sin(0) is 0 (the wave's zero-crossing going up), so nsin(0) will be 0.5, so you may want to use nsin2 if you want to start at 0]]

Tutorials["nsin2"] = [[nsin2(radians) is another normalized sine, but phase-shifted to start at 0.
it is simply 0.5 + 0.5*sin(-PI/2 + radians)

whereas sin has the codomain of [-1,1], we may sometimes want a normalized [0,1] for various reasons

keep in mind sin(0) is 0 (the wave's zero-crossing going up), so nsin(0) will be 0.5, this is why nsin2 exists to start at 0 (the wave's trough) instead]]

Tutorials["ncos"] = [[ncos(radians) is the normalized cosine.
it is simply 0.5 + 0.5*cos(radians)

whereas cos has the codomain of [-1,1], we may sometimes want a normalized [0,1] for various reasons

keep in mind sin(0) is 0, so nsin(0) will be 0.5, so you may want to use ncos2 if you want to start at 0]]

Tutorials["ncos2"] = [[ncos2(radians) is another normalized cosine, but phase-shifted to start at 0.
it is simply 0.5 + 0.5*sin(-PI + radians)

whereas cos has the codomain of [-1,1], we may sometimes want a normalized [0,1] for various reasons

keep in mind cos(0) is 1 (the wave's peak), so ncos(0) will be 0.5, this is why you should use ncos2 if you want to start at 0 (the wave's trough)
but ncos2 is the same as nsin2. we forced them to have the wave starting at the same phase]]

Tutorials["polynomial"] =
[[polynomial(x, a0, a1, a2, a3 ..., aN)

computes a polynomial series, which means it takes the base x and sums over exponents for every coefficient provided a1*x + a2*x^2 + a3*x^3 ... + aN*x^N
x is the base
for any a(0) .. to a(N), a(n) is a coefficient and the sum will add a * x^n

e.g. you might have polynomial(2,0,1,2,3) which is 34, since it is computed as 0*1 + 1*2 + 2*(2*2) + 3*(2*2*2)]]


--basic logic and commands
Tutorials["command"] = [[command(name) reads your own pac_proxy data (from console commands).

name is the name of the value. it is optional but the alternative is weird.
without that argument, it will use the name of the proxy part. which wouldn't allow multiple values in the same expression.

e.g. "pac_proxy my_number 1" means command("my_number") will be 1
if you then run "pac_proxy my_number ++1" repeatedly, command("my_number") will be 2, then 3, then 4 ...
you can also do "pac_proxy my_number --5" etc. and enter vectors.
"pac_proxy my_number 1 2 3"]]

Tutorials["property"] =
[[property(property_name, field)

it takes a part's property. the part is the target entity

property_name is a part's variable name. e.g. "Alpha"
field is an axis: "x", "y", "z", "p", "y", "r", "r", "g", "b"]]

Tutorials["number_operator_alternative"] = [[number_operator_alternative(comp1, op, comp2, num1, num2) or if_else is a simple if statement to choose between two numbers depending on the compared input values

comp1 is the first element to compare
op is the operator, it is a string / text. we expect quotes. you have most number-based operators written different ways
	"=", "==", "equal"
	">", "above", "greater", "greater than"
	">=", "above or equal", "greater or equal", "greater than or equal"
	"<", "below", "less", "less than"
	"<=", "below or equal", "less or equal", "less than or equal"
	"~=", "!=", "not equal"

comp2 is the second element to compare.

num1 is the result to give if the comparison was found to be true. that's the "if" case, it's optional, 1 if not provided
num2 is the result to give if the comparison was found to be false. that's the "else" case, it's optional, 0 if not provided

thus we might have if_else(4, ">", 5, 1, -1), and we know that's not true so we shall take -1 as a result]]
Tutorials["if_else"] = Tutorials["number_operator_alternative"]

Tutorials["sequenced_event_number"] = [[sequenced_event_number(name) reads your own pac_event_sequenced data for command events (from console commands).

name is the base name of the sequenced event

events will only be registered as sequences if you have a series of numbered command events like hat1, hat2, hat3,
or if you force it to register with e.g. "pac_event_sequenced_force_set_bounds color 1 5"

keep in mind sequenced events are managed independently from normal command events, although they end up applied to the same source.
we will not change the code to force that. if you have a series of numbered events, they are not necessarily a sequence. e.g. I have togglepad0 to togglepad9 bound to my keypad, they are independent bind togglers, they shouldn't mess with each other.

if they are a sequenced event, you should avoid triggering them from the event wheel or with normal pac_event commands. please use pac_event_sequenced to set your sequenced events so the function can update properly.]]

Tutorials["feedback"] = [[feedback(), feedback_x(), feedback_y() and feedback_z() take the proxy's previous computed value of the main expression.
it is used in feedback controllers to maintain a memory that's adjustable with a command-controlled speed, and in feedback attractors to gravitate toward a changeable target number

typical examples would be
feedback() + ftime()*command("speed")
feedback_x() + ftime()*(command("targetx") - feedback_x()), feedback_y() + ftime()*(command("targety") - feedback_y()), feedback_z() + ftime()*(command("targetz") - feedback_z())
feedback() - 4*(command("target") - feedback())

extra expressions can't change feedbacks. they can read them from the previous frame though. feebacks are only computed from the main expression]]

Tutorials["feedback_x"] = Tutorials["feedback"]
Tutorials["feedback_y"] = Tutorials["feedback"]
Tutorials["feedback_z"] = Tutorials["feedback"]

local extravar_tutorial = [[the extra/var series range from 1 to 5, so you'll have extra1, extra2, extra3, extra4, extra5 or alternatively var1, var2, var3, var4, var5

var1(uid) for example takes the result of the first extra expression of the proxy referenced

uid is a string argument corresponding to the Unique ID, partial UID or name of a proxy.
It's optional but you'll probably end up using it anyway because it's not hugely useful if it's gone.

the two main uses for this function are:
1-without the uid argument: working inside the same proxy, compressing some math for readability. extra expressions are computed before the main expression.
2-with the uid argument: outsourcing / creating variables used by other proxies. defining some stuff outside is useful to make your proxies more meaningful and simpler down the line

Keep in mind if you have feedback functions, feedback can only change based on the main expression. Put your main math in the main expression in that case.
You can simply put a feedback() in your extra expression and it'll work then. You could also do some minor reformatting on it.

here's what you should do, e.g. with a standard feedback attractor setup.
main : feedback() + ftime()*(feedback)
extra1 : feedback()]]

for i=1,5,1 do
	Tutorials["var"..i] = extravar_tutorial
	Tutorials["extra"..i] = extravar_tutorial
end


--sequences
Tutorials["hexadecimal_level_sequence"] = [[hexadecimal_level_sequence(freq, hex) converts a hexadecimal string into numbers, and animated as a sequence, but  normalized to [0,1] ranges

freq is the frequency of the sequence. how many times it should run every second.
hex is a hexadecimal (base 16) string / text. every letter corresponds to a frame, these are divided by 15 at the end.

it's a weird one but it was a coin flip to decide whether people want a true hexadecimal or a normalized sequence maker.

"0" = 0
"1" = 1/15 (0.067)
...
"9" = 9/15 (0.6)
"a" = 10/15 (0.667)
"b" = 11/15 (0.733)
"c" = 12/15 (0.8)
"d" = 13/15 (0.866)
"e" = 14/15 (0.933)
"f" = 1

"0f" would be a simple binary flicker pulse
"000f00000f00f00f0f0ff00f0f0f0f" would be a semi-erratic flicker, might look good with 0.5 frequency.
"0123456789abcdefedcba987654321" would be a linear fadein-fadeout]]

Tutorials["letters_level_sequence"] = [[letters_level_sequence(freq, str) converts a string of  letters into numbers

it's inspired by Source / Hammer light presets, but normalized to [0,1] ranges.

freq is the frequency of the sequence. how many times it should run every second.
str is the letters. we expect quotes.

"az" would be a simple binary flicker pulse
"abcdefghijklmnopqrstuvwxyz" would be a sawtooth-style pulse]]

Tutorials["numberlist_level_sequence"] = [[numberlist_level_sequence(freq, ...) converts a "vararg" list of numbers and cycles through them regularly. no further processing is done to the numbers

freq is the frequency of the sequence. how many times it should run every second.
... is the numbers, separated by commas e.g. a1, a2, a3 ... aN

0,1 would be a simple binary flicker pulse
0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1 would be a sawtooth-style pulse]]



--time
Tutorials["time"] = [[time() gives you world time, it is RealTime(). It's the server time unaffected by sv_timescale or other factors like pausing.]]
Tutorials["synced_time"] = [[synced_time() gives you CurTime(). It's the server time affected by sv_timescale and other factors like pausing.]]
Tutorials["systime"] = [[systime() gives you system time, it is SysTime()]] Tutorials["stime"] = Tutorials["systime"]
Tutorials["frametime"] = [[frametime() gives you FrameTime(), which is how long it took to draw the previous frame on your screen.
It is used when adjusting iteratively by addition while maintaining a steady speed]] Tutorials["ftime"] = Tutorials["frametime"]
Tutorials["framenumber"] = [["framenumber() gives you FrameNumber(), which is the amount of frames that were drawn since you loaded the map"]] Tutorials["fnumber"] = Tutorials["framenumber"]
Tutorials["timeex"] = [[timeex() is the time in seconds counted from when the proxy was shown, like a chronometer / stopwatch. It is a simple yet capital building block in an immense amount of the proxies you can think of.]]

--randomness and interpolation
Tutorials["ezfade"] = [[ezfade(speed, starttime, endtime) creates standard fades flexibly. think of clamps. this is that, but a bit easier and quicker to set up.

clamp(timeex(), 0, 1) = ezfade() = ezfade(1)
clamp(1 - timeex(), 0, 1) = ezfade(-1)
clamp(-9 + 2*timeex(), 0, 1) = ezfade(2, 4.5)
clamp(-1 + 0.5*timeex(),0 , 1)*clamp(2 - timeex()*0.5, 0, 1) = ezfade(0.5, 2, 6)

speed (optional, default = 1) is how fast the fades should work. the speed is the same for the fade-in and the fade-out. 2 means it will last half a second. negative values gives you the simple fadeout setup
starttime (optional, default = 0) is when the fade should start happening, starting from showtime. if speed is negative, starttime will count as an endtime
endtime (optional) is when the fade-out should end.

keep in mind we are still working in normalized space, we're within 0 and 1. it is suitable for float-based variables like Alpha.
but if you want to use that in another variable you might have to adjust by multiplying.

it's by design. forget about putting your min and max inside the function. work in normalized terms to have a clear view of the time.]]

Tutorials["ezfade_4pt"] = [[ezfade_4pt(in_starttime, in_endtime, out_starttime, out_endtime) creates a fadein-fadeout setup in normalized ranges i.e. [0,1] based on four time points rather than speeds

in_starttime is the time when the fadein should start (where it starts moving from 0 to 1).
in_endtime is the time when the fadein should end (where it is 1)
out_starttime is the time when the fadeout should start (where it starts moving from 1 back to 0), it is optional if you wish to have only a fadein
out_endtime is the time when the fadeout should end (where it finally stops at 0)]]
Tutorials["random"] = [[random(min, max) gives you a random number every time it is called. it will flicker like mad.

min and max are optional arguments. they are implicitly 0 and 1 if not specified.

for held randomness, please review random_once(seed, min, max) and sample_and_hold(seed, duration, min, max, ease)]]
Tutorials["random_once"] = [[random_once(seed, min, max) gives you a random number every time the proxy is shown. it will reset when the proxy is hidden and shown.

seed is an optional argument, it is implicitly 0 if not specified. seed will allow you to choose between independent or shared sources. they are not a true RNG seed (you still get new randomness every showtime) but they work similarly.
min and max are optional arguments. they are implicitly 0 and 1 if not specified.

e.g. you might have random_once(1),random_once(2),random_once(2) resulting in 0.141, 0.684, 0.684

idea: you can use sgn to randomly pick a side with sgn(random_once(0,-1,1))

also see sample_and_hold(seed, duration, min, max, ease)]]
Tutorials["lerp"] = [[lerp(fraction, min, max) interpolates linearly between min and max, by the fraction provided. It is ike an adjustable middle point

fraction is how far in the interpolation we are at. it is implicitly 0 if not provided
min is the start or minimum, it is optional, implicitly -1 if not specified
max is the end or maximum, it is optional, implicitly 1 if not specified

the formula is (max - min) * frac + min

e.g. you might have lerp(ezfade(),0,10) which would move from 0 to 10 in 1 second]]

Tutorials["ease"] = [[eases are interpolations, but more special.
eases are fun.

eases have several variations.
a typical ease is easeInSine(fraction, min, max)
it would be the same as ease_InSine(fraction, min, max) and InSine(fraction, min, max)
they interpolate between min and max, by the fraction provided, but with more dynamic curves.

fraction is how far in the interpolation we are at.
min is the start or minimum, it is optional, implicitly 0 if not specified
max is the end or maximum, it is optional, implicitly 1 if not specified

ease "flavors": Sine, Quad, Cubic, Quart, Circ, Expo, Sine, Back, Bounce, Elastic
For every ease "flavor", there is an "In", an "Out" and an "InOut" version.
you'll have eases written like easeOutBack, ease_InOutSine, InCirc etc.

here's a quick tip. use ezfade to easily get a transition going. you can even multiply outside instead of putting your min and max inside the function.
e.g.20*easeInSine(ezfade())]]

for ease,f in pairs(math.ease) do
	if string.find(ease,"In") or string.find(ease,"Out") then
		Tutorials[ease] = Tutorials["ease"]
		Tutorials["ease_"..ease] = Tutorials["ease"]
		Tutorials["ease"..ease] = Tutorials["ease"]
	end
end

Tutorials["sample_and_hold"] = [[sample_and_hold(seed, duration, min, max, ease) or samplehold or drift or random_drift

it's a type of regularly-refreshing random emitter with extra steps.

seed is like a RNG seed so you can decide whether you want a shared source or independent ones.
duration is how often in seconds the value should move to a new random value. it is 1 if not specified.
min and max are self-explanatory
ease is a string corresponding to the ease name. we expect quotes like "InSine" or "linear". without that argument, it is a sample and hold (no easing)

reminder there are many variations of eases. here are some examples showing some flavors, the In\Out types and the different alternative ways of writing them.
"easeInSine", "ease_OutBack", "InOutQuad"
the full list of ease "flavors": Sine, Quad, Cubic, Quart, Circ, Expo, Sine, Back, Bounce, Elastic]]
Tutorials["samplehold"] = Tutorials["sample_and_hold"]
Tutorials["drift"]  = Tutorials["sample_and_hold"]
Tutorials["random_drift"]  = Tutorials["sample_and_hold"]


--voice
Tutorials["voice_volume"] = [[voice_volume() reads your voice volume, it has ranges of [0,1], but 1 is an absurdly high volume. please don't scream into the mic.]]
Tutorials["voice_volume_scale"] = [[voice_volume_scale() reads your voice volume scale setting which affects how much volume you transmit, it has ranges of [0,1].]]


--statistics
Tutorials["sum"] = [[sum(...) adds all the arguments]]
Tutorials["product"] = [[product(...) takes the product of the arguments]]
Tutorials["average"] = [[average(...) or mean takes the average of the arguments
it is the sum of the arguments divided by the number of arguments]]
Tutorials["mean"] = Tutorials["average"]
Tutorials["median"] = [[median(...) takes the median of the arguments

it is like the middle element in a list when sorted
if there are an even number of arguments, the median is the average of the two middle elements]]
Tutorials["event_alternative"] = [[event_alternative(uid1, num1, num2) or if_event or if_else_event finds out whether an event is active, and returns num1 or num2 depending on whether it's on or off

uid1 is a string (text), we expect quotes like "w_button", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

num1 is the value to return if the event is acive (hiding parts), it is optional, 0 by default.
num2 is the value to return if the event is inactive (showing parts), it is optional, 1 by default

those default values are useful for boolean (true/false) variables if you want to link them to an event. they will reflect the state of the event without any fuss]]
Tutorials["if_event"] = Tutorials["event_alternative"]
Tutorials["if_else_event"] = Tutorials["event_alternative"]


--aim, eye position, visibility
Tutorials["owner_fov"] = [[owner_fov() gets your field of view in degrees]]
Tutorials["visible"] =
[[visible(radius) gives you whether the physical target is visible or not.

radius is an optional argument. it is implicitly 16 if not specified.

the physical target is usually the parent model, the visibility is considered if a radius circle would be "pixel-visible".
it will give 1 if visible, 0 if not visible. being non-visible happens with world objects, being outside of FOV and with pac drawables]]
Tutorials["eye_position_distance"] = [[eye_position_distance() takes the distance from the part's physical target (target or parent) to the viewer eye position

it is not very suitable for fading camera effects based on distance, since if you put something in front of the eyes, it will be at near-zero distance

see also part_distance(uid1,uid2)]]

Tutorials["eye_angle_distance"] = [[eye_angle_distance() tells you how much of an "angle" you have, from the viewer eye angle to the line from the physical target (target or parent) eye position

it's using a normalized vector dot products for this

usually you'll have 0.5 if the viewer is looking straight at the target, down to 0 if looking away at 45 degrees or so]]

Tutorials["aim_length"] = [[aim_length() takes the distance to the traced aimed point. It's how far you look.]]
Tutorials["aim_length_fraction"] = [[aim_length_fraction() takes the fractional distance to the traced aimed point. It's how far you look, but as a proportion of 16000.]]

Tutorials["flat_dot_forward"] = [[flat_dot_forward() takes the dot product of the yaw of the owner/part's angles, against the forward angle from the viewer to the owner/part.

to break it down, it just means to compare how the subject is oriented relative to the viewer.

-1 is facing away from the viewer
0 is right angled orientation (left/right)
1 is facing toward the viewer

a similar idea is used in the south park example pac for picking different 2D sprites based on where we're looking]]

Tutorials["flat_dot_right"] = [[flat_dot_right() takes the dot product of the yaw of the owner/part's angles, against the right angle from the viewer to the owner/part.

to break it down, it just means to compare how the subject is oriented relative to the viewer.

0 is facing away or toward the viewer
-1 is when the subject is facing left
1 is when the subject is facing right

a similar idea is used in the south park example pac for picking different 2D sprites based on where we're looking]]

Tutorials["owner_eye_angle_pitch"] = [[owner_eye_angle_pitch() takes the upward eye angle
the ranges are about [0,1].
you'll usually have root owner checked for this.]]
Tutorials["owner_eye_angle_yaw"] = [[owner_eye_angle_yaw() takes the sideways eye angle
the ranges are about [-2,2].
you'll usually have root owner checked for this.]]
Tutorials["owner_eye_angle_roll"] = [[owner_eye_angle_roll() takes the tilt of eye angle.
you'll usually have root owner checked for this.
you normally won't have a roll in your eye angles.]]


--position, velocity, vectors
Tutorials["part_distance"] = [[part_distance(uid1, uid2) takes the distance between two base_movable parts like models

uid1 and uid2 are strings (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid2 is optional, it is implicitly using the proxy's parent model for example.
that's useful if you have something spawned from a projectile, because projectile creates new parts with new uids, which meant the set uid would match the old base part otherwise]]

Tutorials["Vector"] = [[Vector(x,y,z) creates a vector. It has access to vector functions like Vector(0,0,1):Dot(Vector(2,0,0))]]

Tutorials["owner_position"] = [[owner_position() gets the owner's world position.
the owner is either the parent model or the owning entity i.e. your player]]
Tutorials["owner_position_x"] = [[owner_position_x() gets the owner's world position on x.
the owner is either the parent model or the owning entity i.e. your player]]
Tutorials["owner_position_y"] = [[owner_position_y() gets the owner's world position on y.
the owner is either the parent model or the owning entity i.e. your player]]
Tutorials["owner_position_z"] = [[owner_position_z() gets the owner's world position on z. the owner is either the parent model or the owning entity i.e. your player]]

Tutorials["part_pos"] = [[part_pos(uid1) takes the position of a base_movable part like models

uid1 is a string (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid1 is optional, it is implicitly using the proxy's parent model for example]]
Tutorials["part_pos_x"] = [[part_pos_x(uid1) takes the X (perhaps north/south) world position of a base_movable part like models

uid1 is a string (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid1 is optional, it is implicitly using the proxy's parent model for example]]

Tutorials["part_pos_y"] = [[part_pos_y(uid1) takes the Y (perhaps east/west) world position of a base_movable part like models

uid1 is a string (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid1 is optional, it is implicitly using the proxy's parent model for example]]

Tutorials["part_pos_z"] = [[part_pos_z(uid1) takes the Z (up/down) world position of a base_movable part like models

uid1 is a string (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid1 is optional, it is implicitly using the proxy's parent model for example]]

Tutorials["delta_pos"] = [[delta_pos(uid1, uid2) takes the difference of world positions as a vector, between two base_movable parts like models.
mind the order. it is doing (pos2 - pos1) like a standard delta

uid1 and uid2 are strings (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid2 is optional, it is implicitly using the proxy's parent model for example.
that's useful if you have something spawned from a projectile, because projectile creates new parts with new uids, which means the set uid would match the old part otherwise]]

Tutorials["delta_x"] = [[delta_x(uid1, uid2) takes the difference of X (perhaps north/south) world coordinates, between two base_movable parts like models
mind the order. it is doing (pos2.x - pos1.x) like a standard delta

uid1 and uid2 are strings (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid2 is optional, it is implicitly using the proxy's parent model for example.
that's useful if you have something spawned from a projectile, because projectile creates new parts with new uids, which means the set uid would match the old part otherwise]]

Tutorials["delta_y"] = [[delta_y(uid1, uid2) takes the difference of Y (perhaps east/west) world coordinates, between two base_movable parts like models
mind the order. it is doing (pos2.y - pos1.y) like a standard delta

uid1 and uid2 are strings (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid2 is optional, it is implicitly using the proxy's parent model for example.
that's useful if you have something spawned from a projectile, because projectile creates new parts with new uids, which means the set uid would match the old part otherwise]]

Tutorials["delta_z"] = [[delta_z(uid1, uid2) takes the difference of Z world coordinates (height), between two base_movable parts like models
mind the order. it is doing (pos2.z - pos1.z) like a standard delta

uid1 and uid2 are strings (text), we expect quotes like "center_pos", you have to get their uid or name to identify the parts. please avoid having multiple parts bearing the same name if that's the case.
full UID can be copied from the part in the copy menu

uid2 is optional, it is implicitly using the proxy's parent model for example.
that's useful if you have something spawned from a projectile, because projectile creates new parts with new uids, which means the set uid would match the old part otherwise]]

Tutorials["owner_velocity_length_increase"] = [[owner_velocity_length_increase() takes overall speed and takes it to gradually increase in value
it builds up, making it good for wheels and such, although the velocity is taken at its length so it won't go backwards. see owner_velocity_forward_increase.]]

Tutorials["owner_velocity_forward_increase"] = [[owner_velocity_forward_increase() takes forward speed (velocity dotted with eye angles) and takes it to gradually increase or decrease in value
it builds up, making it good for wheels and such. although the wheels' angles would constantly change, so it might be weird with the dot product
so maybe you should use an invalidbone model as a source for the "mileage" variable and make it an extra expression updated at invalidbone and read on the wheels]]
Tutorials["owner_velocity_right_increase"] = [[owner_velocity_right_increase() takes right speed (velocity dotted with eye angles) and takes it to gradually increase or decrease in value
it builds up, making it good for wheels and such. although the wheels' angles would constantly change, so it might be weird with the dot product
so maybe you should use an invalidbone model as a source for the "mileage" variable and make it an extra expression updated at invalidbone and read on the wheels]]
Tutorials["owner_velocity_up_increase"] = [[owner_velocity_up_increase() takes up speed (velocity dotted with eye angles) and takes it to gradually increase or decrease in value
it builds up, making it good for wheels and such. although the wheels' angles would constantly change, so it might be weird with the dot product
so maybe you should use an invalidbone model as a source for the "mileage" variable and make it an extra expression updated at invalidbone and read on the wheels]]

Tutorials["owner_velocity_world_forward_increase"] = [[owner_velocity_world_forward_increase() takes X speed (world coordinates) and takes it to gradually increase or decrease in value
it builds up, making it good for wheels and such. although we're in global coordinates so maybe not.]]
Tutorials["owner_velocity_world_right_increase"] = [[owner_velocity_world_right_increase() takes Y speed (world coordinates) and takes it to gradually increase or decrease in value
it builds up, making it good for wheels and such. although we're in global coordinates so maybe not.]]
Tutorials["owner_velocity_world_up_increase"] = [[owner_velocity_world_up_increase() takes X speed (world coordinates) and takes it to gradually increase or decrease in value.]]

Tutorials["parent_velocity_length"] = [[parent_velocity_length() takes the physical target (target part or parent) overall speed]]
Tutorials["parent_velocity_forward"] = [[parent_velocity_forward() takes the physical target (target part or parent) velocity dotted against the forward of its angle]]
Tutorials["parent_velocity_right"] = [[parent_velocity_right() takes the physical target (target part or parent) velocity dotted against the right of its angle]]
Tutorials["parent_velocity_up"] = [[parent_velocity_up() takes the physical target (target part or parent) velocity dotted against the up of its angle]]

Tutorials["owner_velocity_length"] = [[owner_velocity_length() takes owner's overall speed.
normal running will usually be 4.5, sprinting is 9, crouching is 1.3, walking is 2.2

this function uses the velocity roughness and reset velocities on hide from the behavior section
more roughness means less frame-by-frame smoothing and more direct readouts, although these readouts will be unreliable if the FPS varies.
reset velocities on hide clears the smoothing memory]]
Tutorials["owner_velocity_forward"] = [[owner_velocity_forward() takes owner's forward speed compared to the eye angles.
it's made "forward" by doing a dot product with the eye angles. it will be reduced if you look up or down.
if you want to ignore eye angles, you could set it up on a model part located on invalidbone while not using root owner, and use an extra expression to outsource the result elsewhere

normal running will usually be -4.5, sprinting is -9, crouching is -1.3, walking is -2.2. going back will make these positive.

this function uses the velocity roughness and reset velocities on hide from the behavior section
more roughness means less frame-by-frame smoothing and more direct readouts, although these readouts will be unreliable if the FPS varies.
reset velocities on hide clears the smoothing memory]]
Tutorials["owner_velocity_right"] = [[owner_velocity_right() takes owner's right speed compared to the eye angles.
it's made "right" by doing a dot product with the eye angles. it will be reduced if you look away, but normally it shouldn't happen if you're actively moving. it can happen if you fling yourself with noclip and look around.
if you want to ignore eye angles, you could set it up on a model part located on invalidbone while not using root owner, and use an extra expression to outsource the result elsewhere

normal running will usually be -4.5, sprinting is -9, crouching is -1.3, walking is -2.2. going left will make these positive.

this function uses the velocity roughness and reset velocities on hide from the behavior section
more roughness means less frame-by-frame smoothing and more direct readouts, although these readouts will be unreliable if the FPS varies.
reset velocities on hide clears the smoothing memory]]
Tutorials["owner_velocity_up"] = [[owner_velocity_up() takes owner's up speed compared to the eye angles.
it's made "up" by doing a dot product with the eye angles. it will be reduced if you look up or down.
if you want to ignore eye angles, you could set it up on a model part located on invalidbone while not using root owner, and use an extra expression to outsource the result elsewhere

normal noclipping going up will usually be -12, falling at terminal velocity will usually be 20.

this function uses the velocity roughness and reset velocities on hide from the behavior section
more roughness means less frame-by-frame smoothing and more direct readouts, although these readouts will be unreliable if the FPS varies.
reset velocities on hide clears the smoothing memory]]

Tutorials["owner_velocity_world_forward"] = [[owner_velocity_world_forward() takes owner's X (north/south?) speed in terms of world (global) coordinates
not that it matters, but going to +X, normal running will usually be 4.5, sprinting is 9, crouching is 1.3, walking is 2.2.]]
Tutorials["owner_velocity_world_right"] = [[owner_velocity_world_right() takes owner's Y (east/west?) speed in terms of world (global) coordinates
not that it matters, but going to +Y, normal running will usually be 4.5, sprinting is 9, crouching is 1.3, walking is 2.2.]]
Tutorials["owner_velocity_world_up"] = [[owner_velocity_world_up() takes owner's Z (up/down) speed in terms of world (global) coordinates
normal noclipping going up will usually be -12, falling at terminal velocity will usually be 20.]]


--model parameters
Tutorials["pose_parameter"] = [[pose_parameter(name) takes the value of the owner's pose parameter. it can be in weird ranges.

name is the name of the pose parameter to read. it's a string, we expect quotes e.g. pose_parameter("head_pitch")

keep in mind most non-biped and most models not made as playermodels do not have the usual pose parameters.
if you're using a monster-type model as a PM, stay in your usual humanoid PM.
make the monster a model on invalidbone and use use root owner for your pose parameters

also see pose_parameter_true for an alternative adjusted output that more accurately reflects the value of the pose parameter.
e.g. while pose_parameter("head_yaw") might range from [0.2,0.8], pose_parameter_true("head_yaw") would range from [-45,45].
since most people want a symmetrical thing, they'd need a 45*(-1 + 2*pose_parameter("head_yaw")) style setup
I think it's more convenient to use pose_parameter_true("head_yaw")]]

Tutorials["pose_parameter_true"] = [[pose_parameter_true(name) takes the value of the owner's pose parameter adjusted to get its "true value".

name is the name of the pose parameter to read. it's a string, we expect quotes e.g. pose_parameter("head_pitch")

keep in mind most non-biped and most models not made as playermodels do not have the usual pose parameters.
if you're using a monster-type model as a PM, stay in your usual humanoid PM.
make the monster a model on invalidbone and use use root owner for your pose parameters

e.g. while pose_parameter("head_yaw") might range from [0.2,0.8], pose_parameter_true("head_yaw") would range from [-45,45].
since most people want a symmetrical thing, they'd need a 45*(-1 + 2*pose_parameter("head_yaw")) style setup
I think it's more convenient to use pose_parameter_true("head_yaw")]]

Tutorials["bodygroup"] = [[bodygroup(name, uid) or model_bodygroup reads the parent or the referenced part's bodygroup.

name is the name of the bodygroup, it's a string, we expect quotes.
uid is the Unique ID or name of a part, it's a string, we expect quotes again]]
Tutorials["model_bodygroup"] = Tutorials["bodygroup"]

Tutorials["parent_scale_x"] = [[parent_scale_x() takes the X scale (with size) of the physical target (target part or parent)]]
Tutorials["parent_scale_y"] = [[parent_scale_y() takes the Y scale (with size) of the physical target (target part or parent)]]
Tutorials["parent_scale_z"] = [[parent_scale_z() takes the Z scale (with size) of the physical target (target part or parent)]]

Tutorials["owner_scale_x"] = [[owner_scale_x() takes owner's model scale on x.
it combines the Size and Scale from pac. if owner.pac_model_scale does not exist, it may use owner.GetModelScale
e.g. with a size of 2 and a scale of (3,2,1), it will be 6.]]
Tutorials["owner_scale_y"] = [[owner_scale_y() takes owner's model scale on y.
it combines the Size and Scale from pac. if owner.pac_model_scale does not exist, it may use owner.GetModelScale
e.g. with a size of 2 and a scale of (3,2,1), it will be 4.]]
Tutorials["owner_scale_z"] = [[owner_scale_z() takes owner's model scale on z.
it combines the Size and Scale from pac. if owner.pac_model_scale does not exist, it may use owner.GetModelScale
e.g. with a size of 2 and a scale of (3,2,1), it will be 2.]]


--lighting and color
Tutorials["light_amount"] = [[light_amount() reads the physical target (target part or parent) nearby lighting as a color-vector. components are in ranges of [0,1].]]
Tutorials["light_amount_r"] = [[light_amount_r() reads the physical target (target part or parent) nearby lighting's red component, ranges are [0,1].]]
Tutorials["light_amount_g"] = [[light_amount_g() reads the physical target (target part or parent) nearby lighting's green component, ranges are [0,1].]]
Tutorials["light_amount_b"] = [[light_amount_b() reads the physical target (target part or parent) nearby lighting's blue component, ranges are [0,1].]]
Tutorials["light_value"] = [[light_value() reads the physical target (target part or parent) nearby lighting and takes its value (brightness), ranges are [0,1].]]
Tutorials["ambient_light"] = [[ambient_light() reads the global ambient lighting as a color-vector (255,255,255). it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ambient_light_r"] = [[ambient_light_r() reads the global ambient lighting's red component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ambient_light_g"] = [[ambient_light_g() reads the global ambient lighting's green component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ambient_light_b"] = [[ambient_light_b() reads the global ambient lighting's blue component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["hsv_to_color"] = [[hsv_to_color(h,s,v) reads a hue, saturation and value and expands it into an RGB color-vector.

h is the hue, it's the color in terms of an angle, ranging from 0 to 360, it will take the remainder of 360 to loop back.
0 = red
30 = orange
60 = yellow
90 = lime green
120 = green
150 = teal
180 = cyan
210 = light blue
240 = dark blue
270 = purple
300 = magenta
330 = magenta-red
360 = red

s is the saturation. at 0 it is white. at more than 1 it distorts the color

v is the value, the brightness. at 0 it is black. at more than 1 it distorts the color]]

--health and armor
Tutorials["owner_health"] = [[owner_health() reads your current player health.]]
Tutorials["owner_max_health"] = [[owner_max_health() reads your maximum player health.]]
Tutorials["owner_health_fraction"] = [[owner_health_fraction() reads your health as a fraction between your current health and maximum health. 50 of 200 is 0.25, 100 of 100 is 1]]
Tutorials["owner_armor"] = [[owner_armor() reads your current player HEV suit armor.]]
Tutorials["owner_max_armor"] = [[owner_max_armor() reads your maximum player HEV suit armor.]]
Tutorials["owner_armor_fraction"] = [[owner_armor_fraction() reads your HEV suit armor as a fraction between your current armor and maximum armor. 50 of 200 is 0.25, 100 of 100 is 1]]


--entity colors
Tutorials["player_color"] = [[player_color() reads the player color as a color-vector (255,255,255). it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["player_color_r"] = [[player_color_r() reads the player color's red component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["player_color_g"] = [[player_color_g() reads the player color's green component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["player_color_b"] = [[player_color_b() reads the player color's blue component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["weapon_color"] = [[weapon_color() reads the weapon color as a color-vector (255,255,255). it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["weapon_color_r"] = [[weapon_color_r() reads the weapon color's red component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["weapon_color_g"] = [[weapon_color_g() reads the weapon color's green component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["weapon_color_b"] = [[weapon_color_b() reads the weapon color's blue component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ent_color"] = [[ent_color() reads the entity (root owner (true entity) or parent/target part (pac entity)) color as a color-vector (255,255,255). it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ent_color_r"] = [[ent_color_r() reads the entity (root owner (true entity) or parent/target part (pac entity)) color's red component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ent_color_g"] = [[ent_color_g() reads the entity (root owner (true entity) or parent/target part (pac entity)) color's green component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ent_color_b"] = [[ent_color_b() reads the entity (root owner (true entity) or parent/target part (pac entity)) color's blue component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]
Tutorials["ent_color_a"] = [[ent_color_b() reads the entity (root owner (true entity) or parent/target part (pac entity)) color's alpha component. it may adjust to Proper Color ranges (1,1,1) depending on the part.]]


--ammo
Tutorials["owner_total_ammo"] = [[owner_total_ammo(id) reads an ammo type's current ammo reserves.
id is a string for the ammo name. it's a string, we expect quotes. it is a name like "Pistol", "357", "SMG1", "SMG1_Grenade", "AR2", "AR2AltFire", etc.]]
Tutorials["weapon_primary_ammo"] = [[weapon_primary_ammo() reads your current clip's primary ammo on your active weapon.]]
Tutorials["weapon_primary_total_ammo"] = [[weapon_primary_total_ammo() reads your current primary ammo reserves on your active weapon.]]
Tutorials["weapon_primary_clipsize"] = [[weapon_primary_clipsize() reads your primary clip size on your active weapon.]]
Tutorials["weapon_secondary_ammo"] = [[weapon_secondary_ammo() reads your current clip's secondary ammo on your active weapon.]]
Tutorials["weapon_secondary_total_ammo"] = [[weapon_secondary_total_ammo() reads your current secondary ammo reserves on your active weapon.]]
Tutorials["weapon_secondary_clipsize"] = [[weapon_secondary_clipsize() reads your secondary clip size on your active weapon.]]


--server population
Tutorials["server_maxplayers"] = [[server_maxplayers() gets the server capacity.]]
Tutorials["server_playercount"] = [[server_playercount() or server_population, gets the server population (number of players).]]
Tutorials["server_population"] = Tutorials["server_playercount"]
Tutorials["server_botcount"] = [[server_botcount() gets the number of bot players connected to the server.]]
Tutorials["server_humancount"] = [[server_botcount() gets the number of human players connected to the server.]]


--health modifier extra health bars
Tutorials["pac_healthbars_total"] = [[pac_healthbars_total() or healthmod_bar_total gets the total amount of "extra health" granted by your health modifiers.]]
Tutorials["healthmod_bar_total"] = Tutorials["pac_healthbars_total"]
Tutorials["pac_healthbars_layertotal"] = [[pac_healthbars_layertotal(layer) or healthmod_bar_layertotal gets the total amount of "extra health" granted by your health modifiers on a certain layer.
layer should be a number, they are usually whole numbers from 0 to 15, with bigger numbers being damaged first]]
Tutorials["healthmod_bar_layertotal"] = Tutorials["healthmod_bar_layertotal"]
Tutorials["pac_healthbar_uidvalue"] = [[pac_healthbar_uidvalue(uid) or healthmod_bar_uidvalue gets the amount of "extra health" granted by one of your health modifier parts.
uid is a string corresponding to the name or Unique ID of the part, we expect quotes.]]
Tutorials["healthmod_bar_uidvalue"] = Tutorials["pac_healthbar_uidvalue"]
Tutorials["pac_healthbar_remaining_bars"] = [[healthmod_bar_remaining_bars(uid) or pac_healthbar_remaining_bars gets the remaining number of "extra health" bars granted by one of your health modifier parts.
uid is a string corresponding to the name or Unique ID of the part, we expect quotes.]]
Tutorials["healthmod_bar_remaining_bars"] = Tutorials["pac_healthbar_remaining_bars"]

return Tutorials
