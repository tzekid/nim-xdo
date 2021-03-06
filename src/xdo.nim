## Nim-Xdo
## =======
##
## - Nim GUI Automation Linux, simulate user interaction, mouse and keyboard control from Nim code, procs for common actions.
# Ideally Xdo can be ported to pure Nim someday, since is 1 C file, meanwhile this is a wrapper.

import os, osproc, ospaths, strformat, strutils, terminal, random, json, times, tables

# Check if the xdo dep is met
if hostOS != "linux":
  echo "ERR: xdo is only available for the Linux platform."
  quit(1)

if not xdo_exists:
  echo "ERR: could not find xdo..."
  install_xdo()

const
  xdo_version* = staticExec("xdo -v")  ## XDo Version (SemVer) when compiled.
  char2keycode* = {
    "A":65,"B":66,"C":67,"D":68,"E":69,"F":70,"G":71,"H":72,"I":73,"J":74,
    "K":75,"L":76,"M":77,"N":78,"O":78,"P":80,"Q":81,"R":82,"S":83,"U":85,
    "V":86,"W":87,"X":88,"Y":89,"Z":90,"0":48,"1":49,"2":50,"3":51,"4":52,
    "5":53,"6":54,"7":55,"8":56,"9":57,"a":65,"b":66,"c":67,"d":68,"e":69,
    "f":70,"g":71,"h":72,"i":73,"j":74,"k":75,"l":76,"m":77,"n":78,"o":79,
    "p":80,"q":81,"r":82,"s":83,"t":84,"u":85,"v":86,"w":87,"x":88,"y":89,
    "z":90," ":32,";":186,"=":187,",":188,"-":189,".":190,"/":191,"`":192,
    "[":219,"\\":220,"]":221,"'":222
  }.toTable  ## Statically compiled JSON that maps Keys strings Versus KeyCodes integers.
  keycode2char* = {
    "8":"backspace","9":"tab","13":"enter","16":"shift","17":"ctrl","18":"alt",
    "19":"pause/break","20":"caps lock","27":"esc","32":"space","33":"page up",
    "34":"page down","35":"end","36":"home","37":"left","38":"up","39":"right",
    "40":"down","45":"insert","46":"delete","48":"0","49":"1","50":"2","51":"3",
    "52":"4","53":"5","54":"6","55":"7","56":"8","57":"9","65":"a","66":"b",
    "67":"c","68":"d","69":"e","70":"f","71":"g","72":"h","73":"i","74":"j",
    "75":"k","76":"l","77":"m","78":"n","79":"o","80":"p","81":"q","82":"r",
    "83":"s","84":"t","85":"u","86":"v","87":"w","88":"x","89":"y","90":"z","91":"windows",
    "93":"right click","96":"numpad 0","97":"numpad 1","98":"numpad 2",
    "99":"numpad 3","100":"numpad 4","101":"numpad 5","102":"numpad 6",
    "103":"numpad 7","104":"numpad 8","105":"numpad 9","106":"numpad *",
    "107":"numpad +","109":"numpad -","110":"numpad .","111":"numpad /",
    "112":"f1","113":"f2","114":"f3","115":"f4","116":"f5","117":"f6",
    "118":"f7","119":"f8","120":"f9","121":"f10","122":"f11","123":"f12",
    "144":"num lock","145":"scroll lock","182":"my computer",
    "183":"my calculator","186":";","187":"=","188":",","189":"-","190":".",
    "191":"/","192":"`","219":"[","220":"\\","221":"]","222":"'"
  }.toTable  ## Statically compiled JSON that maps KeyCodes integers Versus Keys strings.
  valid_actions* = [
   "close",           ## Close the window.
    "kill",           ## Kill the client.
    "hide",           ## Unmap the window.
    "show",           ## Map the window.
    "raise",          ## Raise the window.
    "lower",          ## Lower the window.
    "below",          ## Put the window below the target.
    "above",          ## Put the window above the target.
    "move",           ## Move the window.
    "resize",         ## Resize the window.
    "activate",       ## Activate the window.
    "id",             ## Print the window’s ID.
    "pid",            ## Print the window PID.
    "key_press",      ## Simulate a key press event.
    "key_release",    ## Simulate a key release event.
    "button_press",   ## Simulate a button press event.
    "button_release", ## Simulate a button release event.
    "pointer_motion", ## Simulate a pointer motion event.
  ]  ## Static list of all XDo Valid Actions as strings.
randomize()


proc xdo*(action: string, move: tuple[x: string, y: string] = (x: "0", y: "0"),
          instance_name = "", class_name = "", wm_name = "", pid = 0,
          wait4window = false, same_desktop = true, same_class = true, same_id = true): tuple =
  ## XDo proc is a very low level wrapper for XDo for advanced developers, almost all arguments are supported.
  assert action in valid_actions, fmt"Invalid argument for Action, got {action} must be one of {valid_actions}"
  let
    a = if wait4window: "m" else: ""
    b = if same_id: "" else: "r"
    c = if same_desktop: 'd' else: 'D'
    d = if same_class: 'c' else: 'C'
    e = if instance_name != "": fmt" -n {instance_name} " else: ""
    f = if class_name != "": fmt" -N {class_name} " else: ""
    g = if wm_name != "": fmt" -a {wm_name} " else: ""
    h = if pid != 0: fmt" -p {pid} " else: ""
    i = if move != ("0", "0"): fmt" -x {move.x} -y {move.y} " else: ""
    cmd = fmt"xdo {action} -{a}{b}{c}{d}{e}{f}{g}{h}{i}"
  execCmdEx(cmd)

proc xdo_move_mouse*(move: tuple[x: string, y: string]): tuple =
  ## Move mouse to move position pixel coordinates (X, Y).
  execCmdEx(fmt"xdo pointer_motion -x {move.x} -y {move.y}")

proc xdo_move_window*(move: tuple[x: string, y: string], pid: int): tuple =
  ## Move window to move position pixel coordinates (X, Y).
  execCmdEx(fmt"xdo move -x {move.x} -y {move.y} -p {pid}")

proc xdo_resize_window*(move: tuple[x: string, y: string], pid: int): tuple =
  ## Resize window up to move position pixel coordinates (X, Y).
  execCmdEx(fmt"xdo resize -w {move.x} -h {move.y} -p {pid}")

proc xdo_close_focused_window*(): tuple =
  ## Close the current focused window.
  execCmdEx("xdo close -c")

proc xdo_hide_focused_window*(): tuple =
  ## Hide the current focused window. This is NOT Minimize.
  execCmdEx("xdo hide -c")

proc xdo_show_focused_window*(): tuple =
  ## Hide the current focused window. This is NOT Maximize.
  execCmdEx("xdo show -c")

proc xdo_raise_focused_window*(): tuple =
  ## Raise up the current focused window.
  execCmdEx("xdo raise -c")

proc xdo_lower_focused_window*(): tuple =
  ## Lower down the current focused window.
  execCmdEx("xdo lower -c")

proc xdo_activate_this_window*(pid: int): tuple =
  ## Force to Activate this window by PID.
  execCmdEx(fmt"xdo activate -p {pid}")

proc xdo_hide_all_but_focused_window*(): tuple =
  ## Hide all other windows but leave the current focused window visible.
  execCmdEx("xdo hide -dr")

proc xdo_close_all_but_focused_window*(): tuple =
  ## Close all other windows but leave the current focused window open.
  execCmdEx("xdo close -dr")

proc xdo_raise_all_but_focused_window*(): tuple =
  ## Raise up all other windows but the current focused window.
  execCmdEx("xdo raise -dr")

proc xdo_lower_all_but_focused_window*(): tuple =
  ## Lower down all other windows but the current focused window.
  execCmdEx("xdo lower -dr")

proc xdo_show_all_but_focused_window*(): tuple =
  ## Show all other windows but the current focused window.
  execCmdEx("xdo show -dr")

proc xdo_move_mouse_top_left*(): tuple =
  ## Move mouse to Top Left limits (X=0, Y=0).
  execCmdEx("xdo pointer_motion -x 0 -y 0")

proc xdo_move_mouse_random*(maxx = 1024, maxy = 768, repetitions: int8 = 0): tuple =
  ## Move mouse to Random positions, repeat 0 to repetitions times.
  if repetitions != 0:
    for i in 0..repetitions:
      result = execCmdEx(fmt"xdo pointer_motion -x {rand(maxx)} -y {rand(maxy)}")
  else:
    result = execCmdEx(fmt"xdo pointer_motion -x {rand(maxx)} -y {rand(maxy)}")

proc xdo_move_window_random*(pid: int, maxx = 1024, maxy = 768): tuple =
  ## Move Window to Random positions.
  execCmdEx(fmt"xdo move -x {maxx.rand} -y {maxy.rand} -p {pid}")

proc xdo_move_mouse_terminal_size*(): tuple =
  ## Move mouse to the detected current Terminal Size.
  execCmdEx(fmt"xdo pointer_motion -x {terminalWidth()} -y {terminalHeight()}")

proc xdo_move_mouse_top_100px*(repetitions: int8): tuple =
  ## Move mouse to Top Y=0, then repeat move Bottom on jumps of 100px each.
  result = execCmdEx("xdo pointer_motion -y 0")
  for i in 0..repetitions:
    result = execCmdEx("xdo pointer_motion -y +100")

proc xdo_move_mouse_left_100px*(repetitions: int8): tuple =
  ## Move mouse to Left X=0, then repeat move Right on jumps of 100px each.
  result = execCmdEx("xdo pointer_motion -x 0")
  for i in 0..repetitions:
    result = execCmdEx("xdo pointer_motion -x +100")

proc xdo_get_pid*(): string =
  ## Get PID of a window, integer type.
  execCmdEx("xdo pid").output.strip

proc xdo_get_id*(): string =
  ## Get ID of a window, integer type.
  execCmdEx("xdo id").output.strip

proc xdo_mouse_move_alternating*(move: tuple[x: int, y: int], repetitions: int8): tuple =
  ## Move mouse alternating to Left/Right Up/Down, AKA Zig-Zag movements.
  var xx, yy: string
  for i in 0..repetitions:
    xx = if i mod 2 == 0: "+" else: "-" & $move.x
    yy = if i mod 2 == 0: "+" else: "-" & $move.y
    result = execCmdEx(fmt"xdo pointer_motion -x {xx} -y {yy}") # TODO: foo

proc xdo_mouse_left_click*(): tuple =
  ## Mouse Left Click.
  execCmdEx("xdo button_press -k 1; xdo button_release -k 1")

proc xdo_mouse_middle_click*(): tuple =
  ## Mouse Middle Click.
  execCmdEx("xdo button_press -k 2; xdo button_release -k 2")

proc xdo_mouse_right_click*(): tuple =
  ## Mouse Right Click.
  execCmdEx("xdo button_press -k 3; xdo button_release -k 3")

proc xdo_mouse_double_left_click*(): tuple =
  ## Mouse Double Left Click.
  execCmdEx("xdo button_press -k 1; xdo button_release -k 1; xdo button_press -k 1; xdo button_release -k 1")

proc xdo_mouse_double_middle_click*(): tuple =
  ## Mouse Double Middle Click.
  execCmdEx("xdo button_press -k 2; xdo button_release -k 2; xdo button_press -k 2; xdo button_release -k 2")

proc xdo_mouse_double_right_click*(): tuple =
  ## Mouse Double Right Click.
  execCmdEx("xdo button_press -k 3; xdo button_release -k 3; xdo button_press -k 3; xdo button_release -k 3")

proc xdo_mouse_triple_left_click*(): tuple =
  ## Mouse Triple Left Click.
  execCmdEx("xdo button_press -k 1; xdo button_release -k 1; xdo button_press -k 1; xdo button_release -k 1; xdo button_press -k 1; xdo button_release -k 1")

proc xdo_mouse_triple_middle_click*(): tuple =
  ## Mouse Triple Middle Click.
  execCmdEx("xdo button_press -k 2; xdo button_release -k 2; xdo button_press -k 2; xdo button_release -k 2; xdo button_press -k 2; xdo button_release -k 2")

proc xdo_mouse_triple_right_click*(): tuple =
  ## Mouse Triple Right Click.
  execCmdEx("xdo button_press -k 3; xdo button_release -k 3; xdo button_press -k 3; xdo button_release -k 3; xdo button_press -k 3; xdo button_release -k 3")

proc xdo_mouse_spamm_left_click*(repetitions: int8): tuple =
  ## Spamm Mouse Left Click as fast as possible.
  for i in 0..repetitions:
    result = execCmdEx("xdo button_press -k 1; xdo button_release -k 1")

proc xdo_mouse_spamm_middle_click*(repetitions: int8): tuple =
  ## Spamm Mouse Middle Click as fast as possible.
  for i in 0..repetitions:
    result = execCmdEx("xdo button_press -k 2; xdo button_release -k 2")

proc xdo_mouse_spamm_right_click*(repetitions: int8): tuple =
  ## Spamm Mouse Right Click as fast as possible.
  for i in 0..repetitions:
    result = execCmdEx("xdo button_press -k 3; xdo button_release -k 3")

proc xdo_mouse_swipe_horizontal*(x: string): tuple =
  ## Mouse Swipe to Left or Right, Hold Left Click+Drag Horizontally+Release Left Click.
  execCmdEx("xdo button_press -k 1; xdo pointer_motion -x {x}; xdo button_release -k 1")

proc xdo_mouse_swipe_vertical*(y: string): tuple =
  ## Mouse Swipe to Up or Down, Hold Left Click+Drag Vertically+Release Left Click.
  execCmdEx("xdo button_press -k 1; xdo pointer_motion -y {y}; xdo button_release -k 1")

proc xdo_key_backspace*(): tuple =
  ## Keyboard Key Backspace.
  execCmdEx("xdo key_press -k 8; xdo key_release -k 8")

proc xdo_key_tab*(): tuple =
  ## Keyboard Key Tab.
  execCmdEx("xdo key_press -k 9; xdo key_release -k 9")

proc xdo_key_enter*(): tuple =
  ## Keyboard Key Enter.
  execCmdEx("xdo key_press -k 13; xdo key_release -k 13")

proc xdo_key_shift*(): tuple =
  ## Keyboard Key Shift.
  execCmdEx("xdo key_press -k 16; xdo key_release -k 16")

proc xdo_key_ctrl*(): tuple =
  ## Keyboard Key Ctrl.
  execCmdEx("xdo key_press -k 17; xdo key_release -k 17")

proc xdo_key_alt*(): tuple =
  ## Keyboard Key Alt.
  execCmdEx("xdo key_press -k 18; xdo key_release -k 18")

proc xdo_key_pause*(): tuple =
  ## Keyboard Key Pause.
  execCmdEx("xdo key_press -k 19; xdo key_release -k 19")

proc xdo_key_capslock*(): tuple =
  ## Keyboard Key Caps Lock.
  execCmdEx("xdo key_press -k 20; xdo key_release -k 20")

proc xdo_key_esc*(): tuple =
  ## Keyboard Key Esc.
  execCmdEx("xdo key_press -k 27; xdo key_release -k 27")

proc xdo_key_space*(): tuple =
  ## Keyboard Key Space.
  execCmdEx("xdo key_press -k 32; xdo key_release -k 32")

proc xdo_key_pageup*(): tuple =
  ## Keyboard Key Page Up.
  execCmdEx("xdo key_press -k 33; xdo key_release -k 33")

proc xdo_key_pagedown*(): tuple =
  ## Keyboard Key Page Down.
  execCmdEx("xdo key_press -k 34; xdo key_release -k 34")

proc xdo_key_end*(): tuple =
  ## Keyboard Key End.
  execCmdEx("xdo key_press -k 35; xdo key_release -k 35")

proc xdo_key_home*(): tuple =
  ## Keyboard Key Home.
  execCmdEx("xdo key_press -k 36; xdo key_release -k 36")

proc xdo_key_arrow_left*(): tuple =
  ## Keyboard Key Arrow Left.
  execCmdEx("xdo key_press -k 37; xdo key_release -k 37")

proc xdo_key_arrow_up*(): tuple =
  ## Keyboard Key Arrow Up.
  execCmdEx("xdo key_press -k 38; xdo key_release -k 38")

proc xdo_key_arrow_right*(): tuple =
  ## Keyboard Key Arrow Right.
  execCmdEx("xdo key_press -k 39; xdo key_release -k 39")

proc xdo_key_arrow_down*(): tuple =
  ## Keyboard Key Arrow Down.
  execCmdEx("xdo key_press -k 40; xdo key_release -k 40")

proc xdo_key_insert*(): tuple =
  ## Keyboard Key Insert.
  execCmdEx("xdo key_press -k 45; xdo key_release -k 45")

proc xdo_key_delete*(): tuple =
  ## Keyboard Key Delete.
  execCmdEx("xdo key_press -k 46; xdo key_release -k 46")

proc xdo_key_numlock*(): tuple =
  ## Keyboard Key Num Lock.
  execCmdEx("xdo key_press -k 144; xdo key_release -k 144")

proc xdo_key_scrolllock*(): tuple =
  ## Keyboard Key Scroll Lock.
  execCmdEx("xdo key_press -k 145; xdo key_release -k 145")

proc xdo_key_mycomputer*(): tuple =
  ## Keyboard Key My Computer (HotKey thingy of some modern keyboards).
  execCmdEx("xdo key_press -k 182; xdo key_release -k 182")

proc xdo_key_mycalculator*(): tuple =
  ## Keyboard Key My Calculator (HotKey thingy of some modern keyboards).
  execCmdEx("xdo key_press -k 183; xdo key_release -k 183")

proc xdo_key_windows*(): tuple =
  ## Keyboard Key Windows (AKA Meta Key).
  execCmdEx("xdo key_press -k 91; xdo key_release -k 91")

proc xdo_key_rightclick*(): tuple =
  ## Keyboard Key Right Click (HotKey thingy, fake click from keyboard key).
  execCmdEx("xdo key_press -k 93; xdo key_release -k 93")

proc xdo_key_numpad0*(): tuple =
  ## Keyboard Key Numeric Pad 0.
  execCmdEx("xdo key_press -k 96; xdo key_release -k 96")

proc xdo_key_numpad1*(): tuple =
  ## Keyboard Key Numeric Pad 1.
  execCmdEx("xdo key_press -k 97; xdo key_release -k 97")

proc xdo_key_numpad2*(): tuple =
  ## Keyboard Key Numeric Pad 2.
  execCmdEx("xdo key_press -k 98; xdo key_release -k 98")

proc xdo_key_numpad3*(): tuple =
  ## Keyboard Key Numeric Pad 3.
  execCmdEx("xdo key_press -k 99; xdo key_release -k 99")

proc xdo_key_numpad4*(): tuple =
  ## Keyboard Key Numeric Pad 4.
  execCmdEx("xdo key_press -k 100; xdo key_release -k 100")

proc xdo_key_numpad5*(): tuple =
  ## Keyboard Key Numeric Pad 5.
  execCmdEx("xdo key_press -k 101; xdo key_release -k 101")

proc xdo_key_numpad6*(): tuple =
  ## Keyboard Key Numeric Pad 6.
  execCmdEx("xdo key_press -k 102; xdo key_release -k 102")

proc xdo_key_numpad7*(): tuple =
  ## Keyboard Key Numeric Pad 7.
  execCmdEx("xdo key_press -k 103; xdo key_release -k 103")

proc xdo_key_numpad8*(): tuple =
  ## Keyboard Key Numeric Pad 8.
  execCmdEx("xdo key_press -k 104; xdo key_release -k 104")

proc xdo_key_numpad9*(): tuple =
  ## Keyboard Key Numeric Pad 9.
  execCmdEx("xdo key_press -k 105; xdo key_release -k 105")

proc xdo_key_numpad_asterisk*(): tuple =
  ## Keyboard Key Numeric Pad ``*``.
  execCmdEx("xdo key_press -k 106; xdo key_release -k 106")

proc xdo_key_numpad_plus*(): tuple =
  ## Keyboard Key Numeric Pad ``+``.
  execCmdEx("xdo key_press -k 107; xdo key_release -k 107")

proc xdo_key_numpad_minus*(): tuple =
  ## Keyboard Key Numeric Pad ``-``.
  execCmdEx("xdo key_press -k 109; xdo key_release -k 109")

proc xdo_key_numpad_dot*(): tuple =
  ## Keyboard Key Numeric Pad ``.``.
  execCmdEx("xdo key_press -k 110; xdo key_release -k 110")

proc xdo_key_numpad_slash*(): tuple =
  ## Keyboard Key Numeric Pad ``/``.
  execCmdEx("xdo key_press -k 111; xdo key_release -k 111")

proc xdo_key_f1*(): tuple =
  ## Keyboard Key F1.
  execCmdEx("xdo key_press -k 112; xdo key_release -k 112")

proc xdo_key_f2*(): tuple =
  ## Keyboard Key F2.
  execCmdEx("xdo key_press -k 113; xdo key_release -k 113")

proc xdo_key_f3*(): tuple =
  ## Keyboard Key F3.
  execCmdEx("xdo key_press -k 114; xdo key_release -k 114")

proc xdo_key_f4*(): tuple =
  ## Keyboard Key F4.
  execCmdEx("xdo key_press -k 115; xdo key_release -k 115")

proc xdo_key_f5*(): tuple =
  ## Keyboard Key F5.
  execCmdEx("xdo key_press -k 116; xdo key_release -k 116")

proc xdo_key_f6*(): tuple =
  ## Keyboard Key F6.
  execCmdEx("xdo key_press -k 117; xdo key_release -k 117")

proc xdo_key_f7*(): tuple =
  ## Keyboard Key F7.
  execCmdEx("xdo key_press -k 118; xdo key_release -k 118")

proc xdo_key_f8*(): tuple =
  ## Keyboard Key F8.
  execCmdEx("xdo key_press -k 119; xdo key_release -k 119")

proc xdo_key_f9*(): tuple =
  ## Keyboard Key F9.
  execCmdEx("xdo key_press -k 120; xdo key_release -k 120")

proc xdo_key_f10*(): tuple =
  ## Keyboard Key F10.
  execCmdEx("xdo key_press -k 121; xdo key_release -k 121")

proc xdo_key_f11*(): tuple =
  ## Keyboard Key F11.
  execCmdEx("xdo key_press -k 122; xdo key_release -k 122")

proc xdo_key_f12*(): tuple =
  ## Keyboard Key F12.
  execCmdEx("xdo key_press -k 123; xdo key_release -k 123")

proc xdo_key_0*(): tuple =
  ## Keyboard Key 0.
  execCmdEx("xdo key_press -k 48; xdo key_release -k 48")

proc xdo_key_1*(): tuple =
  ## Keyboard Key 1.
  execCmdEx("xdo key_press -k 49; xdo key_release -k 49")

proc xdo_key_2*(): tuple =
  ## Keyboard Key 2.
  execCmdEx("xdo key_press -k 50; xdo key_release -k 50")

proc xdo_key_3*(): tuple =
  ## Keyboard Key 3.
  execCmdEx("xdo key_press -k 51; xdo key_release -k 51")

proc xdo_key_4*(): tuple =
  ## Keyboard Key 4.
  execCmdEx("xdo key_press -k 52; xdo key_release -k 52")

proc xdo_key_5*(): tuple =
  ## Keyboard Key 5.
  execCmdEx("xdo key_press -k 53; xdo key_release -k 53")

proc xdo_key_6*(): tuple =
  ## Keyboard Key 6.
  execCmdEx("xdo key_press -k 54; xdo key_release -k 54")

proc xdo_key_7*(): tuple =
  ## Keyboard Key 7.
  execCmdEx("xdo key_press -k 55; xdo key_release -k 55")

proc xdo_key_8*(): tuple =
  ## Keyboard Key 8.
  execCmdEx("xdo key_press -k 56; xdo key_release -k 56")

proc xdo_key_9*(): tuple =
  ## Keyboard Key 9.
  execCmdEx("xdo key_press -k 57; xdo key_release -k 57")

proc xdo_key_wasd*(repetitions: int8): tuple =
  ## Keyboard Keys W,A,S,D as fast as possible (in games,make circles).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 87; xdo key_release -k 87; xdo key_press -k 65; xdo key_release -k 65; xdo key_press -k 83; xdo key_release -k 83; xdo key_press -k 68; xdo key_release -k 68")

proc xdo_key_spamm_space*(repetitions: int8): tuple =
  ## Keyboard Key Space as fast as possible (in games,bunny hop).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 32; xdo key_release -k 32")

proc xdo_key_w_click*(repetitions: int8): tuple =
  ## Keyboard Key W and Mouse Left Click as fast as possible (in games,forward+hit).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 87; xdo key_release -k 87; xdo button_press -k 1; xdo button_release -k 1")

proc xdo_key_w_space*(repetitions: int8): tuple =
  ## Keyboard Keys W,Space as fast as possible (in games, forward+jump).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 87; xdo key_release -k 87; xdo key_press -k 32; xdo key_release -k 32")

proc xdo_key_w_space_click*(repetitions: int8): tuple =
  ## Keyboard Keys W,Space and Mouse Left Click (in games, forward+jump+hit).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 87; xdo key_release -k 87; xdo key_press -k 32; xdo key_release -k 32; xdo button_press -k 1; xdo button_release -k 1")

proc xdo_key_wasd_random*(repetitions: int8): tuple =
  ## Keyboard Keys W,A,S,D,space Randomly as fast as possible.
  for i in 0..repetitions:
    var kycds = [87, 65, 83, 68, 32].rand
    result = execCmdEx(fmt"xdo key_press -k {kycds}; xdo key_release -k {kycds}")

proc xdo_key_w_e*(repetitions: int8): tuple =
  ## Keyboard Keys W,E as fast as possible (in games, forward+use).
  for i in 0..repetitions:
    result = execCmdEx("xdo key_press -k 87; xdo key_release -k 87; xdo key_press -k 69; xdo key_release -k 69")

proc xdo_key_numbers_click*(repetitions: int8): tuple =
  ## This function types the keys like: 1,10clicks,2,10clicks,3,10clicks,etc up to 9 (in games, shoot weapons 1 to 9).
  for repeat in 0..repetitions:
    for i in 49..57:
      discard execCmdEx(fmt"xdo key_press -k {i}; xdo key_release -k {i}")
      for x in 0..9:
        result = execCmdEx("xdo button_press -k 1; xdo button_release -k 1")

proc xdo_type*(letter: char): tuple =
  ## Type a single letter using keyboard keys from char argument.
  let keycodez = char2keycode[$letter]
  execCmdEx(fmt"xdo key_press -k {keycodez}; xdo key_release -k {keycodez}")

proc xdo_type_temp_dir*(): tuple =
  ## Type the system temporary directory full path using keyboard keys.
  for letter in getTempDir():
    result = xdo_type(letter)

proc xdo_type_current_dir*(): tuple =
  ## Type the current working directory full path using keyboard keys.
  for letter in getCurrentDir():
    result = xdo_type(letter)

proc xdo_type_hostOS*(): tuple =
  ## Type the hostOS using keyboard keys.
  for letter in hostOS:
    result = xdo_type(letter)

proc xdo_type_hostCPU*(): tuple =
  ## Type the hostCPU using keyboard keys.
  for letter in hostCPU:
    result = xdo_type(letter)

proc xdo_type_NimVersion*(): tuple =
  ## Type the current NimVersion using keyboard keys.
  for letter in NimVersion:
    result = xdo_type(letter)

proc xdo_type_CompileTime*(): tuple =
  ## Type the CompileDate & CompileTime using keyboard keys.
  for letter in CompileDate & CompileTime:
    result = xdo_type(letter)

proc xdo_type_enter*(words: string): tuple =
  ## Type the words then press Enter at the end using keyboard keys.
  for letter in words:
    discard xdo_type(letter)
  result = execCmdEx("xdo key_press -k 13; xdo key_release -k 13")

# proc xdo_type_datetime*(): tuple =
#   ## Type the current Date & Time (ISO-Format) using keyboard keys.
#   for letter in $now():
#     result = xdo_type(letter)


runnableExamples:
  ## XDo works on Linux OS.
  when defined(linux):
    ## Basic example of mouse and keyboard control from code.
    import os, osproc, ospaths, strformat, strutils, terminal, random, json, times, tables
    echo xdo_version
    echo xdo_get_id()
    echo xdo_get_pid()
    echo xdo_move_mouse_random()
    echo xdo_move_mouse_top_left()
    echo xdo_move_mouse((x: "+99", y: "+99"))
    echo xdo_move_mouse_left_100px(2)
    echo xdo_move_mouse_terminal_size()
    echo xdo_move_mouse_top_100px(2)
    echo xdo_mouse_move_alternating((x: 9, y: 5), 3)
    echo xdo_type('a')
    echo xdo_type_current_dir()
    echo xdo_type_temp_dir()
    # echo xdo_key_0()
    # echo xdo_key_1()
    # echo xdo_key_2()
    # echo xdo_key_3()
    # echo xdo_key_4()
    # echo xdo_key_5()
    # echo xdo_key_6()
    # echo xdo_key_7()
    # echo xdo_key_8()
    # echo xdo_key_9()
    # echo xdo_hide_all_but_focused_window()
    # echo xdo_hide_focused_window()
