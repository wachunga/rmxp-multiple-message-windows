Multiple Message Windows (v 1.1)
===

A script for [RPG Maker XP](http://en.wikipedia.org/wiki/RPG_Maker_XP), which uses Ruby. Written years ago and posted on some now-defunct forums, but may still be useful to folks.

This custom message system adds numerous features on top of the default message system, the most notable being the ability to have multiple message windows open at once. The included features are mostly themed around turning messages into speech (and thought) bubbles, but default-style messages are of course still possible.

[Screenshot](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/hands_off.png)

[Screenshot](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/thought_bubble.png)

[Relative positioning](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/bubble_locations.png)

Everything works during battle too:

[Screenshot](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/smacktalk.jpg)

[Screenshot](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/thought_bubble_battle.png)

[Screenshot](http://s88387243.onlinehome.us/rmxp/multiple_message_windows/comeback.jpg)


Features
---

* multiple message windows
* speech bubbles
   * position over player/event (follows movement and scrolling)
   * optional message tail (for speech or thought bubbles)
   * can specify location relative to player/event (top, bottom, left, right)
* thought bubbles
   * can use different windowskin, message tail and font color
* letter-by-letter mode
   * variable speed (and delays)
   * skippable on button press
* autoresize messages
* player movement allowed during messages
   * if speaker moves offscreen, message closes (like ChronoTrigger)
* everything also works during battle
* settings configurable at anytime

Demo
---

See `demo` directory. Requires RMXP, of course.

Installation
---
Copy the script in `src`, and open the Script Editor within RMXP. At the bottom of the list of classes on the left side of the new window, you'll see one called "Main". Right click on it and select "Insert". In the newly created entry in the list, paste this script.

The following files must be in the Graphics/Windowskins folder: `blue-speech_tail.png`, `white-thought_tail.png` and `white-windowskin.png`. You can, of course, just change the filename constant to use your own.

Usage
---

Full list of options (all case *insensitive*):
  
```
  =============================================================================
   Local (specified in message itself and resets at message end)
  =============================================================================
  - \L = letter-by-letter mode toggle
  - \S[n] = set speed at which text appears in letter-by-letter mode
  - \D[n] = set delay (in frames) before next text appears
  - \P[n] = position message over event with id n
            * use n=0 for player
            * in battle, use n=a,b,c,d for actors (e.g. \P[a] for first actor)
              and n=1,...,n for enemies (e.g. \P[1] for first enemy)
              where order is actually the reverse of troop order (in database)
  - \P = position message over current event (default for floating messages)
  - \^ = message appears directly over its event
  - \v = message appears directly below its event
  - \< = message appears directly to the left of its event
  - \> = message appears directly to the right of its event
  - \B = bold text
  - \I = italic text
  - \! = message autoclose
  - \? = wait for user input before continuing
  - \+ = make message appear at same time as preceding one
         * note: must be at the start of message to work
  - \@ = thought bubble
  - \N[en] = display name of enemy with id n (note the "e")
  - \MAP = display the name of the current map

  These are, of course, in addition to the default options:
  - \Var[n] = display value of variable n (note change from \V[n])
  - \N[n] = display name of actor with id n
  - \C[n] = change colour
  - \G = display gold window
  - \\ = show the '\' character
  
  =============================================================================
   Global (specified below or by Call Script and persist until changed)
  =============================================================================
  Miscellaneous:
  - message.move_during = true/false
    * allow/disallow player to move during messages
  - message.show_pause = true/false
    * show/hide "waiting for player" pause graphic
  - message.autocenter = true/false
    * enable/disable automatically centering text within messages
  
  Speech/thought bubble related:
  - message.resize = true/false
    * enable/disable automatic resizing of messages (only as big as necessary)
  - message.floating = true/false
    * enable/disable positioning messages above current event by default
      (i.e. equivalent to including \P in every message)
  - message.location = TOP, BOTTOM, LEFT or RIGHT
    * set default location for floating messages relative to their event
  - message.show_tail = true/false
    * show/hide message tail for speech/thought bubbles

  Letter-by-letter related:
  - message.letter_by_letter = true/false
    * enable/disable letter-by-letter mode (globally)
  - message.text_speed = 0-20
    * set speed at which text appears in letter-by-letter mode (globally)
  - message.skippable = true/false
    * allow/disallow player to skip to end of message with button press

  Font:
  - message.font_name = font
    * set font to use for text
  - message.font_size = size
    * set size of text  (default 22)
  - message.font_color = color
    * set color of regular text (same 0-7 as for \C[n])
  - message.font_color_thought = color
    * set color of text used in thought bubbles (same 0-7 as for \C[n])

```  

Credits
---

Thanks to XRXS for the self-close wait for input functionality, Slipknot for a convenient approach to altering settings in-game and SephirothSpawn for (reliable!) bitmap rotate method.
