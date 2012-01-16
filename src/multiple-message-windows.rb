#==============================================================================
# ** Multiple Message Windows
#------------------------------------------------------------------------------
# Wachunga
# 1.1
# 2006-11-10
# See https://github.com/wachunga/rmxp-multiple-message-windows for details
#==============================================================================

#==============================================================================
# Settings
#==============================================================================

  # filename of message tail used for speech bubbles
  # must be in the Graphics/Windowskins/ folder
  FILENAME_SPEECH_TAIL = "blue-speech_tail.png"
  # note that gradient windowskins aren't ideal for tails
  
  # filenames of message tail and windowskin used for thought bubbles
  # must also be in the Graphics/Windowskins/ folder
  FILENAME_THOUGHT_TAIL = "white-thought_tail.png"
  FILENAME_THOUGHT_WINDOWSKIN = "white-windowskin.png"
  
  # used for message.location
  TOP = 8
  BOTTOM = 2
  LEFT = 4
  RIGHT = 6

class Game_Message

  # Any of the below can be changed by a Call Script event during gameplay.
  # E.g. turn letter-by-letter mode off with: message.letter_by_letter = false
  
  attr_accessor :move_during
  attr_accessor :letter_by_letter
  attr_accessor :text_speed
  attr_accessor :skippable
  attr_accessor :resize
  attr_accessor :floating
  attr_accessor :autocenter
  attr_accessor :show_tail
  attr_accessor :show_pause
  attr_accessor :location
  attr_accessor :font_name
  attr_accessor :font_size
  attr_accessor :font_color
  attr_accessor :font_color_thought

  
  def initialize
    # whether or not messages appear one letter at a time
    @letter_by_letter = true
    # note: can also change within a single message with \L

    # the default speed at which text appears in letter-by-letter mode
    @text_speed = 1
    # note: can also change within a single message with \S[n]
    
    # whether or not players can skip to the end of (letter-by-letter) messages
    @skippable = true
    
    # whether or not messages are automatically resized based on the message
    @resize = true
    
    # whether or not message windows are positioned above
    # characters/events by default, i.e. without needing \P every message
    # (only works if resize messages enabled -- otherwise would look very odd)
    @floating = true
    
    # whether or not to automatically center lines within the message
    @autocenter = true
    
    # whether or not event-positioned messages have a tail (for speech bubbles)
    # (only works if floating and resized messages enabled -- otherwise would
    # look very odd indeed)
    @show_tail = true
    
    # whether or not to display "waiting for user input" pause graphic 
    # (probably want this disabled for speech bubbles)
    @show_pause = false

    # whether the player is permitted to move while messages are displayed
    @move_during = true
    
    # the default location for floating messages (relative to the event)
    # note that an off-screen message will be "flipped" automatically
    @location = TOP
    
    # name of font to use for text (any TrueType from Windows/Fonts folder)
    @font_name = Font.default_name
    # note that you can use an array of fonts to specify multiple
    # e.g. ['Verdana', 'MS PGothic']
    # (if Verdana is not available, MS PGothic will be used instead)
    
    # font size for text (default is 22)
    @font_size = Font.default_size
    
    # default font color (same 0-7 as for \c[n])
    @font_color = 0
    
    # font color used just for thought bubbles (\@)
    @font_color_thought = 1
  end
end
  
#------------------------------------------------------------------------------
  
class Window_Message < Window_Selectable
  
  def initialize(msgindex) 
    super(80, 304, 480, 160)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.visible = false
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    self.z = 9000 + msgindex * 5 # permits messages to overlap legibly
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @fade_in = false
    @fade_out = false
    @contents_showing = false
    @cursor_width = 0
    self.active = false
    self.index = -1
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @msgindex = msgindex
    @tail = Sprite.new
    @tail.bitmap =
      if @msgindex == 0
        RPG::Cache.windowskin(FILENAME_SPEECH_TAIL)
      else
        # don't use cached version or else all tails
        # are rotated when multiple are visible at once
        Bitmap.new("Graphics/Windowskins/"+FILENAME_SPEECH_TAIL)
      end
    # keep track of orientation of tail bitmap
    if @tail.bitmap.orientation == nil
      @tail.bitmap.orientation = 0
    end
    # make origin the center, not top left corner
    @tail.ox = @tail.bitmap.width/2
    @tail.oy = @tail.bitmap.height/2
    @tail.z = 9999
    @tail.visible = false
    @windowskin = $game_system.windowskin_name
    @font_color = $game_system.message.font_color
    @update_text = true
    @letter_by_letter = $game_system.message.letter_by_letter
    @text_speed = $game_system.message.text_speed
    # id of character for speech bubbles
    @float_id = nil
    # location of box relative to speaker
    @location = $game_system.message.location
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
  end
  
  def dispose
    terminate_message
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # have to check all windows before claiming that no window is showing
    if $game_temp.message_text.compact.empty?
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      $game_temp.message_window_showing = false
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    if @input_number_window != nil
      @input_number_window.dispose
    end
    super
  end
  
  def terminate_message
    self.active = false
    self.pause = false
    self.index = -1
    self.contents.clear
    # Clear showing flag
    @contents_showing = false
    # Clear variables related to text, choices, and number input
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @tail.visible = false
    # note that these variables are now indexed arrays
    $game_temp.message_text[@msgindex] = nil
    # Call message callback
    if $game_temp.message_proc[@msgindex] != nil
      # make sure no message boxes are displaying
      if $game_temp.message_text.compact.empty?
        $game_temp.message_proc[@msgindex].call
      end
      $game_temp.message_proc[@msgindex] = nil
    end
    @update_text = true
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    $game_temp.choice_start = 99
    $game_temp.choice_max = 0
    $game_temp.choice_cancel_type = 0
    $game_temp.choice_proc = nil
    $game_temp.num_input_start = 99
    $game_temp.num_input_variable_id = 0
    $game_temp.num_input_digits_max = 0
    # Open gold window
    if @gold_window != nil
      @gold_window.dispose
      @gold_window = nil
    end
  end
  
  def refresh
    self.contents.clear
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @x = @y = 0 # now instance variables
    @float_id = nil
    @location = $game_system.message.location
    @windowskin = $game_system.windowskin_name
    @font_color = $game_system.message.font_color
    @line_widths = nil
    @wait_for_input = false
    @tail.bitmap =
      if @msgindex == 0
        RPG::Cache.windowskin(FILENAME_SPEECH_TAIL)
      else
        Bitmap.new("Graphics/Windowskins/"+FILENAME_SPEECH_TAIL)
      end
    RPG::Cache.windowskin(FILENAME_SPEECH_TAIL)
    @tail.bitmap.orientation = 0 if @tail.bitmap.orientation == nil
    @text_speed = $game_system.message.text_speed
    @letter_by_letter = $game_system.message.letter_by_letter
    @delay = @text_speed
    @player_skip = false
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @cursor_width = 0
    # Indent if choice
    if $game_temp.choice_start == 0
      @x = 8
    end
    # If waiting for a message to be displayed
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    if $game_temp.message_text[@msgindex] != nil
      @text = $game_temp.message_text[@msgindex] # now an instance variable
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # Control text processing
      begin
        last_text = @text.clone
        @text.gsub!(/\\[Vv][Aa][Rr]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
      end until @text == last_text
      @text.gsub!(/\\[Nn]\[([0-9]+)\]/) do
        $game_actors[$1.to_i] != nil ? $game_actors[$1.to_i].name : ""
      end
      # Change "\\\\" to "\000" for convenience
      @text.gsub!(/\\\\/) { "\000" }
      # Change "\\C" to "\001" and "\\G" to "\002"
      @text.gsub!(/\\[Cc]\[([0-9]+)\]/) { "\001[#{$1}]" }
      @text.gsub!(/\\[Gg]/) { "\002" }
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      @text.gsub!(/\\[Nn]\[[Ee]([0-9]+)\]/) do
        $data_enemies[$1.to_i] != nil ? $data_enemies[$1.to_i].name : ""
      end
      # Change "\\MAP" to map name
      @text.gsub!(/\\[Mm][Aa][Pp]/) { $game_map.name }
      # Change "\\L" to "\003" (toggle letter-by-letter)
      @text.gsub!(/\\[Ll]/) { "\003" }
      # Change "\\S" to "\004" (text speed)
      @text.gsub!(/\\[Ss]\[([0-9]+)\]/) { "\004[#{$1}]" }
      # Change "\\D" to "\005" (delay)
      @text.gsub!(/\\[Dd]\[([0-9]+)\]/) { "\005[#{$1}]" }
      # Change "\\!" to "\006" (self close)
      @text.gsub!(/\\[!]/) { "\006" }
      # Change "\\?" to "\007" (wait for user input)
      @text.gsub!(/\\[?]/) { "\007" }
      # Change "\\B" to "\010" (bold)
      @text.gsub!(/\\[Bb]/) { "\010" }
      # Change "\\I" to "\011" (italic)
      @text.gsub!(/\\[Ii]/) { "\011" }
      # Get rid of "\\@" (thought bubble)
      if @text.gsub!(/\\[@]/, "") != nil
        @windowskin = FILENAME_THOUGHT_WINDOWSKIN
        @font_color = $game_system.message.font_color_thought
        @tail.bitmap = 
          if @msgindex == 0
            RPG::Cache.windowskin(FILENAME_THOUGHT_TAIL)
          else
            Bitmap.new("Graphics/Windowskins/"+FILENAME_THOUGHT_TAIL)
          end
        @tail.bitmap.orientation = 0 if @tail.bitmap.orientation == nil
      end      
      # Get rid of "\\+" (multiple messages)
      @text.gsub!(/\\[+]/, "")
      # Get rid of "\\^", "\\v", "\\<", "\\>" (relative message location)
      if @text.gsub!(/\\\^/, "") != nil
        @location = 8
      elsif @text.gsub!(/\\[Vv]/, "") != nil
        @location = 2
      elsif @text.gsub!(/\\[<]/, "") != nil
        @location = 4
      elsif @text.gsub!(/\\[>]/, "") != nil
        @location = 6
      end
      # Get rid of "\\P" (position window to given character)
      if @text.gsub!(/\\[Pp]\[([0-9]+)\]/, "") != nil
        @float_id = $1.to_i
      elsif @text.gsub!(/\\[Pp]\[([a-zA-Z])\]/, "") != nil and
          $game_temp.in_battle
        @float_id = $1.downcase
      elsif @text.gsub!(/\\[Pp]/, "") != nil or
        ($game_system.message.floating and $game_system.message.resize) and
        !$game_temp.in_battle
        @float_id = $game_system.map_interpreter.event_id
      end
      if $game_system.message.resize or $game_system.message.autocenter
        # calculate length of lines
        text = @text.clone
        temp_bitmap = Bitmap.new(1,1)
        temp_bitmap.font.name = $game_system.message.font_name
        temp_bitmap.font.size = $game_system.message.font_size
        @line_widths = [0,0,0,0]
        for i in 0..3
          line = text.split(/\n/)[3-i]
          if line == nil
            next
          end
          line.gsub!(/[\001-\007](\[\w+\])?/, "")
          line.chomp.split(//).each do |c|
            case c
              when "\000"
                c = "\\"
              when "\010"
                # bold
                temp_bitmap.font.bold = !temp_bitmap.font.bold
                c = ''
              when "\011"
                # italics
                temp_bitmap.font.italic = !temp_bitmap.font.italic
                c = ''
            end
            @line_widths[3-i] += temp_bitmap.text_size(c).width
          end
          if (3-i) >= $game_temp.choice_start
            # account for indenting
            @line_widths[3-i] += 8 unless $game_system.message.autocenter
          end
        end
        if $game_temp.num_input_variable_id > 0
          # determine cursor_width as in Window_InputNumber
          # (can't get from @input_number_window because it doesn't exist yet)
          cursor_width = temp_bitmap.text_size("0").width + 8
          # use this width to calculate line width (+8 for indent)
          input_number_width = cursor_width*$game_temp.num_input_digits_max
          input_number_width += 8 unless $game_system.message.autocenter
          @line_widths[$game_temp.num_input_start] = input_number_width
        end
        temp_bitmap.dispose
      end
      resize
      reposition if @float_id != nil
      self.contents.font.name = $game_system.message.font_name
      self.contents.font.size = $game_system.message.font_size
      self.contents.font.color = text_color(@font_color)
      self.windowskin = RPG::Cache.windowskin(@windowskin)
      # autocenter first line if enabled
      # (subsequent lines are done as "\n" is encountered)
      if $game_system.message.autocenter and @text != ""
        @x = (self.width-40)/2 - @line_widths[0]/2
      end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    end
  end

  #--------------------------------------------------------------------------
  # * Resize Window
  #-------------------------------------------------------------------------- 
  def resize
    if !$game_system.message.resize
      # reset to defaults
      self.width = 480
      self.height = 160
      self.contents = Bitmap.new(width - 32, height - 32)
      self.x = 80 # undo any centering
      return
    end
    max_x = @line_widths.max
    max_y = 4
    @line_widths.each do |line|
      max_y -= 1 if line == 0 and max_y > 1
    end
    if $game_temp.choice_max  > 0
      # account for indenting
      max_x += 8 unless $game_system.message.autocenter
    end
    self.width = max_x + 40
    self.height = max_y * 32 + 32
    self.contents = Bitmap.new(width - 32, height - 32)
    self.x = 320 - (self.width/2) # center
  end

  #--------------------------------------------------------------------------
  # * Reposition Window
  #-------------------------------------------------------------------------- 
  def reposition
    if $game_temp.in_battle
      if "abcd".include?(@float_id) # must be between a and d
        @float_id = @float_id[0] - 97 # a = 0, b = 1, c = 2, d = 3
        return if $scene.spriteset.actor_sprites[@float_id] == nil
        sprite = $scene.spriteset.actor_sprites[@float_id]
      else
        @float_id -= 1 # account for, e.g., player entering 1 for index 0
        return if $scene.spriteset.enemy_sprites[@float_id] == nil
        sprite = $scene.spriteset.enemy_sprites[@float_id]
      end
      char_height = sprite.height
      char_width = sprite.width
      char_x = sprite.x
      char_y = sprite.y - char_height/2
    else # not in battle...
      char = (@float_id == 0 ? $game_player : $game_map.events[@float_id])
      if char == nil
        # no such character
        @float_id = nil
        return 
      end
      # close message (and stop event processing) if speaker is off-screen
      if char.screen_x <= 0 or char.screen_x >= 640 or
         char.screen_y <= 0 or char.screen_y > 480
        terminate_message
        $game_system.map_interpreter.command_115
        return
      end
      char_height = RPG::Cache.character(char.character_name,0).height / 4
      char_width = RPG::Cache.character(char.character_name,0).width / 4
      # record coords of character's center
      char_x = char.screen_x
      char_y = char.screen_y - char_height/2
    end
    params = [char_height, char_width, char_x, char_y]
    # position window and message tail
    vars = new_position(params)
    x = vars[0]
    y = vars[1]
    # check if any window locations need to be "flipped"
    if @location == 4 and x < 0
      # switch to right
      @location = 6
      vars = new_position(params)
      x = vars[0]
      if (x + self.width) > 640
        # right is no good either...
        if y >= 0
          # switch to top
          @location = 8
          vars = new_position(params)
        else
          # switch to bottom
          @location = 2
          vars = new_position(params)
        end
      end
    elsif @location == 6 and (x + self.width) > 640
      # switch to left
      @location = 4
      vars = new_position(params)
      x = vars[0]
      if x < 0
        # left is no good either...
        if y >= 0
          # switch to top
          @location = 8
          vars = new_position(params)
        else
          # switch to bottom
          @location = 2
          vars = new_position(params)
        end
      end
    elsif @location == 8 and y < 0
      # switch to bottom
      @location = 2
      vars = new_position(params)
      y = vars[1]
      if (y + self.height) > 480
        # bottom is no good either...
        # note: this will probably never occur given only 3 lines of text
        x = vars[0]
        if x >= 0
          # switch to left
          @location = 4
          vars = new_position(params)
        else
          # switch to right
          @location = 6
          vars = new_position(params)
        end
      end
    elsif @location == 2 and (y + self.height) > 480
      # switch to top
      @location = 8
      vars = new_position(params)
      y = vars[1]
      if y < 0
        # top is no good either...
        # note: this will probably never occur given only 3 lines of text
        x = vars[0]
        if x >= 0
          # switch to left
          @location = 4
          vars = new_position(params)
        else
          # switch to right
          @location = 6
          vars = new_position(params)
        end
      end
    end
    x = vars[0]
    y = vars[1]
    tail_x = vars[2]
    tail_y = vars[3]    
    # adjust windows if near edge of screen
    if x < 0
      x = 0
    elsif (x + self.width) > 640
      x = 640 - self.width
    end
    if y < 0
      y = 0
    elsif (y + self.height) > 480
      y = 480 - self.height
    elsif $game_temp.in_battle and @location == 2 and (y > (320 - self.height))
      # when in battle, prevent enemy messages from overlapping battle status
      # (note that it could still happen from actor messages, though)
      y = 320 - self.height
      tail_y = y
    end
    # finalize positions
    self.x = x
    self.y = y
    @tail.x = tail_x
    @tail.y = tail_y
  end
  
  #--------------------------------------------------------------------------
  # * Determine New Window Position
  #--------------------------------------------------------------------------  
  def new_position(params)
    char_height = params[0]
    char_width = params[1]
    char_x = params[2]
    char_y = params[3]
    if @location == 8
      # top
      x = char_x - self.width/2
      y = char_y - char_height/2 - self.height - @tail.bitmap.height/2
      @tail.bitmap.rotation(0)
      tail_x = x + self.width/2 
      tail_y = y + self.height
    elsif @location == 2
      # bottom
      x = char_x - self.width/2
      y = char_y + char_height/2 + @tail.bitmap.height/2
      @tail.bitmap.rotation(180)
      tail_x = x + self.width/2
      tail_y = y
    elsif @location == 4
      # left
      x = char_x - char_width/2 - self.width - @tail.bitmap.width/2
      y = char_y - self.height/2
      @tail.bitmap.rotation(270)
      tail_x = x + self.width
      tail_y = y + self.height/2
    elsif @location == 6
      # right
      x = char_x + char_width/2 + @tail.bitmap.width/2
      y = char_y - self.height/2
      @tail.bitmap.rotation(90)
      tail_x = x
      tail_y = y + self.height/2
    end
    return [x,y,tail_x,tail_y]
  end
      
  #--------------------------------------------------------------------------
  # * Update Text
  #--------------------------------------------------------------------------  
  def update_text
    if @text != nil
      # Get 1 text character in c (loop until unable to get text)
      while ((c = @text.slice!(/./m)) != nil)
        # If \\
        if c == "\000"
          # Return to original text
          c = "\\"
        end
        # If \C[n]
        if c == "\001"
          # Change text color
          @text.sub!(/\[([0-9]+)\]/, "")
          color = $1.to_i
          if color >= 0 and color <= 7
            self.contents.font.color = text_color(color)
          end
          # go to next text
          next
        end
        # If \G
        if c == "\002"
          # Make gold window
          if @gold_window == nil
            @gold_window = Window_Gold.new
            @gold_window.x = 560 - @gold_window.width
            if $game_temp.in_battle
              @gold_window.y = 192
            else
              @gold_window.y = self.y >= 128 ? 32 : 384
            end
            @gold_window.opacity = self.opacity
            @gold_window.back_opacity = self.back_opacity
          end
          # go to next text
          next
        end
        # If \L
        if c == "\003"
          # toggle letter-by-letter mode
          @letter_by_letter = !@letter_by_letter
          # go to next text
          next
        end
        # If \S[n]
        if c == "\004"
          @text.sub!(/\[([0-9]+)\]/, "")
          speed = $1.to_i
          if speed >= 0
            @text_speed = speed
            # reset player skip after text speed change
            @player_skip = false            
          end
          return
        end
        # If \D[n]
        if c == "\005"
          @text.sub!(/\[([0-9]+)\]/, "")
          delay = $1.to_i
          if delay >= 0
            @delay += delay
            # reset player skip after delay
            @player_skip = false
          end
          return
        end   
        # If \!
        if c == "\006"
          # close message and return from method
          terminate_message
          return
        end
        # If \?
        if c == "\007"
          @wait_for_input = true
          return
        end
        if c == "\010"
          # bold
          self.contents.font.bold = !self.contents.font.bold
        end
        if c == "\011"
          # italics
          self.contents.font.italic = !self.contents.font.italic
        end
        # If new line text
        if c == "\n"
          # Update cursor width if choice
          if @y >= $game_temp.choice_start
            width = $game_system.message.autocenter ? @line_widths[@y]+8 : @x
            @cursor_width = [@cursor_width, width].max
          end
          # Add 1 to y
          @y += 1
          if $game_system.message.autocenter and @text != ""
            @x = (self.width-40)/2 - @line_widths[@y]/2
          else
            @x = 0
            # Indent if choice
            if @y >= $game_temp.choice_start
              @x = 8
            end
          end
          # go to next text
          next
        end
        # Draw text
        self.contents.draw_text(4 + @x, 32 * @y, 40, 32, c)
        # Add x to drawn text width
        @x += self.contents.text_size( c ).width
        # add text speed to time to display next character
        @delay += @text_speed unless !@letter_by_letter or @player_skip
        return if @letter_by_letter and !@player_skip
      end
    end
    # If choice
    if $game_temp.choice_max > 0
      @item_max = $game_temp.choice_max
      self.active = true
      self.index = 0
    end
    # If number input
    if $game_temp.num_input_variable_id > 0
      digits_max = $game_temp.num_input_digits_max
      number = $game_variables[$game_temp.num_input_variable_id]
      @input_number_window = Window_InputNumber.new(digits_max)
      @input_number_window.number = number
      @input_number_window.x =
        if $game_system.message.autocenter
          offset = (self.width-40)/2-@line_widths[$game_temp.num_input_start]/2
          self.x + offset + 4
        else
          self.x + 8
        end
      @input_number_window.y = self.y + $game_temp.num_input_start * 32
    end
    @update_text = false
  end
  
  #--------------------------------------------------------------------------
  # * Set Window Position and Opacity Level
  #--------------------------------------------------------------------------
  def reset_window
    if $game_temp.in_battle
      self.y = 16
    else
      case $game_system.message_position
      when 0  # up
        self.y = 16
      when 1  # middle
        self.y = 160
      when 2  # down
        self.y = 304
      end
    end
    if $game_system.message_frame == 0
      self.opacity = 255
    else
      self.opacity = 0
    end
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # transparent speech bubbles don't look right, so keep opacity at 255
    # self.back_opacity = 160
    @tail.opacity = 255
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
  end
  
  def update
    super
    # If fade in
    if @fade_in
      self.contents_opacity += 24
      if @input_number_window != nil
        @input_number_window.contents_opacity += 24
      end
      if self.contents_opacity == 255
        @fade_in = false
      end
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # return
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    end
    # If inputting number
    if @input_number_window != nil
      @input_number_window.update
      # Confirm
      if Input.trigger?(Input::C)
        $game_system.se_play($data_system.decision_se)
        $game_variables[$game_temp.num_input_variable_id] =
          @input_number_window.number
        $game_map.need_refresh = true
        # Dispose of number input window
        @input_number_window.dispose
        @input_number_window = nil
        terminate_message
      end
      return
    end
    # If message is being displayed
    if @contents_showing
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # Confirm or cancel finishes waiting for input or message
      if Input.trigger?(Input::C) or Input.trigger?(Input::B)
        if @wait_for_input
          @wait_for_input = false
          self.pause = false
        elsif $game_system.message.skippable
          @player_skip = true
        end
      end
      if need_reposition?
        reposition # update message position for character/screen movement
        if @contents_showing == false
          # i.e. if char moved off screen
          return 
        end
      end
      if @update_text and !@wait_for_input
        if @delay == 0
          update_text
        else
          @delay -= 1
        end
        return
      end

      # If choice isn't being displayed, show pause sign
      if !self.pause and ($game_temp.choice_max == 0 or @wait_for_input)
        self.pause = true unless !$game_system.message.show_pause
      end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # Cancel
      if Input.trigger?(Input::B)
        if $game_temp.choice_max > 0 and $game_temp.choice_cancel_type > 0
          $game_system.se_play($data_system.cancel_se)
          $game_temp.choice_proc.call($game_temp.choice_cancel_type - 1)
          terminate_message
        end
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
        # personal preference: cancel button should also continue
        terminate_message 
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      end
      # Confirm
      if Input.trigger?(Input::C)
        if $game_temp.choice_max > 0
          $game_system.se_play($data_system.decision_se)
          $game_temp.choice_proc.call(self.index)
        end
        terminate_message
      end
      return
    end
    # If display wait message or choice exists when not fading out
    if @fade_out == false and $game_temp.message_text[@msgindex] != nil
      @contents_showing = true
      $game_temp.message_window_showing = true
      reset_window
      refresh
      Graphics.frame_reset
      self.visible = true
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      if show_message_tail?
        @tail.visible = true
      elsif @tail.visible
        @tail.visible = false
      end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      self.contents_opacity = 0
      if @input_number_window != nil
        @input_number_window.contents_opacity = 0
      end
      @fade_in = true
      return
    end
    # If message which should be displayed is not shown, but window is visible
    if self.visible
      @fade_out = true
      self.opacity -= 48
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      @tail.opacity -= 48 if @tail.opacity > 0
      if need_reposition?
        reposition # update message position for character/screen movement
      end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      if self.opacity == 0
        self.visible = false
        @fade_out = false
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
        @tail.visible = false if @tail.visible
        # have to check all windows before claiming that no window is showing
        if $game_temp.message_text.compact.empty?
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
          $game_temp.message_window_showing = false  
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
        end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      end
      return
    end
  end
  
  #--------------------------------------------------------------------------
  # * Repositioning Determination
  #--------------------------------------------------------------------------
  def need_reposition?
    if !$game_temp.in_battle and $game_system.message.floating and
        $game_system.message.resize and @float_id != nil
      if $game_system.message.move_during and @float_id == 0 and
          (($game_player.last_real_x != $game_player.real_x) or
          ($game_player.last_real_y != $game_player.real_y))
          # player with floating message moved
          # (note that relying on moving? leads to "jumpy" message boxes)
          return true
      elsif ($game_map.last_display_y != $game_map.display_y) or
         ($game_map.last_display_x != $game_map.display_x)
        # player movement or scroll event caused the screen to scroll
        return true
      else
        char = $game_map.events[@float_id]
        if char != nil and 
          ((char.last_real_x != char.real_x) or
          (char.last_real_y != char.real_y))
          # character moved
          return true
        end
      end    
    end
    return false
  end
  
  #--------------------------------------------------------------------------
  # * Show Message Tail Determination
  #--------------------------------------------------------------------------
  def show_message_tail?
    if $game_system.message.show_tail and $game_system.message.floating and
      $game_system.message.resize and $game_system.message_frame == 0 and
      @float_id != nil
      return true
    end
    return false
  end
  
  def update_cursor_rect
    if @index >= 0
      n = $game_temp.choice_start + @index
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      if $game_system.message.autocenter
        x = 4 + (self.width-40)/2 - @cursor_width/2
      else
        x = 8
      end
      self.cursor_rect.set(x, n * 32, @cursor_width, 32)
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    else
      self.cursor_rect.empty
    end
  end

end

#------------------------------------------------------------------------------

class Game_Character
  attr_reader   :last_real_x                   # last map x-coordinate
  attr_reader   :last_real_y                   # last map y-coordinate
  alias wachunga_game_char_update update
  def update
    @last_real_x = @real_x
    @last_real_y = @real_y
    wachunga_game_char_update
  end
end

#------------------------------------------------------------------------------

class Game_Player < Game_Character

  alias wachunga_mmw_game_player_update update
  def update
   # The conditions are changed so the player can move around while messages
   # are showing (if move_during is true), but not if user is making a
   # choice or inputting a number
   # Note that this check overrides the default one (later in the method)
   # because it is more general
    unless moving? or
      @move_route_forcing or
      ($game_system.map_interpreter.running? and
      !$game_temp.message_window_showing) or
      ($game_temp.message_window_showing and
      !$game_system.message.move_during) or 
      ($game_temp.choice_max > 0 or $game_temp.num_input_digits_max > 0)
      case Input.dir4
      when 2
        move_down
      when 4
        move_left
      when 6
        move_right
      when 8
        move_up
      end
    end
    wachunga_mmw_game_player_update    
  end
  
end
  
#------------------------------------------------------------------------------

class Game_Temp
  alias wachunga_mmw_game_temp_initialize initialize
  def initialize
    wachunga_mmw_game_temp_initialize
    @message_text = [] 
    @message_proc = [] 
  end
end

#------------------------------------------------------------------------------
  
class Sprite_Battler < RPG::Sprite
  # necessary for positioning messages relative to battlers
  attr_reader :height
  attr_reader :width
end

#------------------------------------------------------------------------------

class Scene_Battle
  # necessary for accessing actor/enemy sprites in battle
  attr_reader :spriteset
end

#------------------------------------------------------------------------------

class Spriteset_Battle
  # necessary for accessing actor/enemy sprites in battle
  attr_reader :actor_sprites
  attr_reader :enemy_sprites
end

#------------------------------------------------------------------------------

class Scene_Map

  # can't alias these methods unfortunately
  # (SDK would help compatibility a little)
  
  def main
    # Make sprite set
    @spriteset = Spriteset_Map.new
    # Make message window
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @message_window = []
    @message_window[0] = Window_Message.new(0)
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # Transition run
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of sprite set
    @spriteset.dispose
    # Dispose of message window
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    for mw in @message_window
      mw.dispose
    end  
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # If switching to title screen
    if $scene.is_a?(Scene_Title)
      # Fade out screen
      Graphics.transition
      Graphics.freeze
    end
  end


  def update
    # Loop
    loop do
      # Update map, interpreter, and player order
      # (this update order is important for when conditions are fulfilled 
      # to run any event, and the player isn't provided the opportunity to
      # move in an instant)
      $game_map.update
      $game_system.map_interpreter.update
      $game_player.update
      # Update system (timer), screen
      $game_system.update
      $game_screen.update
      # Abort loop if player isn't place moving
      unless $game_temp.player_transferring
        break
      end
      # Run place move
      transfer_player
      # Abort loop if transition processing
      if $game_temp.transition_processing
        break
      end
    end
    # Update sprite set
    @spriteset.update
    # Update message window
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    for mw in @message_window
      mw.update
    end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # If game over
    if $game_temp.gameover
      # Switch to game over screen
      $scene = Scene_Gameover.new
      return
    end
    # If returning to title screen
    if $game_temp.to_title
      # Change to title screen
      $scene = Scene_Title.new
      return
    end
    # If transition processing
    if $game_temp.transition_processing
      # Clear transition processing flag
      $game_temp.transition_processing = false
      # Execute transition
      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" +
          $game_temp.transition_name)
      end
    end
    # If showing message window
    if $game_temp.message_window_showing
      return
    end
    # If encounter list isn't empty, and encounter count is 0
    if $game_player.encounter_count == 0 and $game_map.encounter_list != []
      # If event is running or encounter is not forbidden
      unless $game_system.map_interpreter.running? or
             $game_system.encounter_disabled
        # Confirm troop
        n = rand($game_map.encounter_list.size)
        troop_id = $game_map.encounter_list[n]
        # If troop is valid
        if $data_troops[troop_id] != nil
          # Set battle calling flag
          $game_temp.battle_calling = true
          $game_temp.battle_troop_id = troop_id
          $game_temp.battle_can_escape = true
          $game_temp.battle_can_lose = false
          $game_temp.battle_proc = nil
        end
      end
    end
    # If B button was pressed
    if Input.trigger?(Input::B)
      # If event is running, or menu is not forbidden
      unless $game_system.map_interpreter.running? or
             $game_system.menu_disabled
        # Set menu calling flag or beep flag
        $game_temp.menu_calling = true
        $game_temp.menu_beep = true
      end
    end
    # If debug mode is ON and F9 key was pressed
    if $DEBUG and Input.press?(Input::F9)
      # Set debug calling flag
      $game_temp.debug_calling = true
    end
    # If player is not moving
    unless $game_player.moving?
      # Run calling of each screen
      if $game_temp.battle_calling
        call_battle
      elsif $game_temp.shop_calling
        call_shop
      elsif $game_temp.name_calling
        call_name
      elsif $game_temp.menu_calling
        call_menu
      elsif $game_temp.save_calling
        call_save
      elsif $game_temp.debug_calling
        call_debug
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * New Message Window Addition
  #--------------------------------------------------------------------------
  def new_message_window(index)
    if @message_window[index] != nil
      # clear message windows at and after this index
      last_index = @message_window.size - 1
      last_index.downto(index) do |i|
        if @message_window[i] != nil
          @message_window[i].dispose
          @message_window[i] = nil
        end
      end
      @message_window.compact!
    end
    @message_window.push(Window_Message.new(index))
  end

end

#------------------------------------------------------------------------------

class Scene_Battle

  # can't alias these methods unfortunately
  # (SDK would help compatibility a little)
  
  def main
    # Initialize each kind of temporary battle data
    $game_temp.in_battle = true
    $game_temp.battle_turn = 0
    $game_temp.battle_event_flags.clear
    $game_temp.battle_abort = false
    $game_temp.battle_main_phase = false
    $game_temp.battleback_name = $game_map.battleback_name
    $game_temp.forcing_battler = nil
    # Initialize battle event interpreter
    $game_system.battle_interpreter.setup(nil, 0)
    # Prepare troop
    @troop_id = $game_temp.battle_troop_id
    $game_troop.setup(@troop_id)
    # Make actor command window
    s1 = $data_system.words.attack
    s2 = $data_system.words.skill
    s3 = $data_system.words.guard
    s4 = $data_system.words.item
    @actor_command_window = Window_Command.new(160, [s1, s2, s3, s4])
    @actor_command_window.y = 160
    @actor_command_window.back_opacity = 160
    @actor_command_window.active = false
    @actor_command_window.visible = false
    # Make other windows
    @party_command_window = Window_PartyCommand.new
    @help_window = Window_Help.new
    @help_window.back_opacity = 160
    @help_window.visible = false
    @status_window = Window_BattleStatus.new
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    @message_window = [] 
    @message_window[0] = Window_Message.new(0) 
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # Make sprite set
    @spriteset = Spriteset_Battle.new
    # Initialize wait count
    @wait_count = 0
    # Execute transition
    if $data_system.battle_transition == ""
      Graphics.transition(20)
    else
      Graphics.transition(40, "Graphics/Transitions/" +
        $data_system.battle_transition)
    end
    # Start pre-battle phase
    start_phase1
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Refresh map
    $game_map.refresh
    # Prepare for transition
    Graphics.freeze
    # Dispose of windows
    @actor_command_window.dispose
    @party_command_window.dispose
    @help_window.dispose
    @status_window.dispose
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    for mw in @message_window
      mw.dispose
    end  
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    if @skill_window != nil
      @skill_window.dispose
    end
    if @item_window != nil
      @item_window.dispose
    end
    if @result_window != nil
      @result_window.dispose
    end
    # Dispose of sprite set
    @spriteset.dispose
    # If switching to title screen
    if $scene.is_a?(Scene_Title)
      # Fade out screen
      Graphics.transition
      Graphics.freeze
    end
    # If switching from battle test to any screen other than game over screen
    if $BTEST and not $scene.is_a?(Scene_Gameover)
      $scene = nil
    end
  end

  def update
    # If battle event is running
    if $game_system.battle_interpreter.running?
      # Update interpreter
      $game_system.battle_interpreter.update
      # If a battler which is forcing actions doesn't exist
      if $game_temp.forcing_battler == nil
        # If battle event has finished running
        unless $game_system.battle_interpreter.running?
          # Rerun battle event set up if battle continues
          unless judge
            setup_battle_event
          end
        end
        # If not after battle phase
        if @phase != 5
          # Refresh status window
          @status_window.refresh
        end
      end
    end
    # Update system (timer) and screen
    $game_system.update
    $game_screen.update
    # If timer has reached 0
    if $game_system.timer_working and $game_system.timer == 0
      # Abort battle
      $game_temp.battle_abort = true
    end
    # Update windows
    @help_window.update
    @party_command_window.update
    @actor_command_window.update
    @status_window.update
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    for mw in @message_window
      mw.update
    end 
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # Update sprite set
    @spriteset.update
    # If transition is processing
    if $game_temp.transition_processing
      # Clear transition processing flag
      $game_temp.transition_processing = false
      # Execute transition
      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(40, "Graphics/Transitions/" +
          $game_temp.transition_name)
      end
    end
    # If message window is showing
    if $game_temp.message_window_showing
      return
    end
    # If effect is showing
    if @spriteset.effect?
      return
    end
    # If game over
    if $game_temp.gameover
      # Switch to game over screen
      $scene = Scene_Gameover.new
      return
    end
    # If returning to title screen
    if $game_temp.to_title
      # Switch to title screen
      $scene = Scene_Title.new
      return
    end
    # If battle is aborted
    if $game_temp.battle_abort
      # Return to BGM used before battle started
      $game_system.bgm_play($game_temp.map_bgm)
      # Battle ends
      battle_end(1)
      return
    end
    # If waiting
    if @wait_count > 0
      # Decrease wait count
      @wait_count -= 1
      return
    end
    # If battler forcing an action doesn't exist,
    # and battle event is running
    if $game_temp.forcing_battler == nil and
       $game_system.battle_interpreter.running?
      return
    end
    # Branch according to phase
    case @phase
    when 1  # pre-battle phase
      update_phase1
    when 2  # party command phase
      update_phase2
    when 3  # actor command phase
      update_phase3
    when 4  # main phase
      update_phase4
    when 5  # after battle phase
      update_phase5
    end
  end
  
  #--------------------------------------------------------------------------
  # * New Message Window Addition
  #--------------------------------------------------------------------------
  def new_message_window(index)
    if @message_window[index] != nil
      # clear message windows at and after this index
      last_index = @message_window.size - 1
      last_index.downto(index) do |i|
        if @message_window[i] != nil
          @message_window[i].dispose
          @message_window[i] = nil
        end
      end
      @message_window.compact!
    end
    @message_window.push(Window_Message.new(index))
  end

end

#------------------------------------------------------------------------------

class Game_System
  attr_reader :message
  
  alias wachunga_mmw_game_system_init initialize
  def initialize
    wachunga_mmw_game_system_init
    @message = Game_Message.new
  end
end

#------------------------------------------------------------------------------

class Interpreter
  attr_reader :event_id
  
  alias wachunga_mmw_interp_setup setup
  def setup(list, event_id)
    wachunga_mmw_interp_setup(list, event_id)
    # index of window for the message
    @msgindex = 0
    # whether multiple messages are displaying
    @multi_message = false
  end
  
  def setup_choices(parameters)
    # Set choice item count to choice_max
    $game_temp.choice_max = parameters[0].size
    # Set choice to message_text
    for text in parameters[0]
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # just add index for array
      $game_temp.message_text[@msgindex] += text + "\n"
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    end
    # Set cancel processing
    $game_temp.choice_cancel_type = parameters[1]
    # Set callback
    current_indent = @list[@index].indent
    $game_temp.choice_proc = Proc.new { |n| @branch[current_indent] = n }
  end
  
  
  #--------------------------------------------------------------------------
  # * Show Text
  #--------------------------------------------------------------------------
  def command_101
    # If other text has been set to message_text
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    if $game_temp.message_text[@msgindex] != nil
      if @multi_message
        @msgindex += 1
        $scene.new_message_window(@msgindex)
      else
        # End
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
        return false
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
      end
    end
    @msgindex = 0 if !@multi_message
    @multi_message = false
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # Set message end waiting flag and callback
    @message_waiting = true
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # just adding indexes
    $game_temp.message_proc[@msgindex] = Proc.new { @message_waiting = false }
    # Set message text on first line
    $game_temp.message_text[@msgindex] = @list[@index].parameters[0] + "\n"
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    line_count = 1
    # Loop
    loop do
      # If next event command text is on the second line or after
      if @list[@index+1].code == 401
        # Add the second line or after to message_text
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
        # just adding index
        $game_temp.message_text[@msgindex]+=@list[@index+1].parameters[0]+"\n"
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
        line_count += 1
      # If event command is not on the second line or after
      else
        # If next event command is show choices
        if @list[@index+1].code == 102
          # If choices fit on screen
          if @list[@index+1].parameters[0].size <= 4 - line_count
            # Advance index
            @index += 1
            # Choices setup
            $game_temp.choice_start = line_count
            setup_choices(@list[@index].parameters)
          end
        # If next event command is input number
        elsif @list[@index+1].code == 103
          # If number input window fits on screen
          if line_count < 4
            # Advance index
            @index += 1
            # Number input setup
            $game_temp.num_input_start = line_count
            $game_temp.num_input_variable_id = @list[@index].parameters[0]
            $game_temp.num_input_digits_max = @list[@index].parameters[1]
          end
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
        # start multimessage if next line is "Show Text" starting with "\\+"
        elsif @list[@index+1].code == 101
          if @list[@index+1].parameters[0][0..1]=="\\+"
            @multi_message = true
            @message_waiting = false
          end
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
        end
        # Continue
        return true
      end
      # Advance index
      @index += 1
    end
  end
  
  #--------------------------------------------------------------------------
  # * Show Choices
  #--------------------------------------------------------------------------
  def command_102
    # If text has been set to message_text
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # just adding index
    if $game_temp.message_text[@msgindex] != nil
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # End
      return false
    end
    # Set message end waiting flag and callback
    @message_waiting = true
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # adding more indexes
    $game_temp.message_proc[@msgindex] = Proc.new { @message_waiting = false }
    # Choices setup
    $game_temp.message_text[@msgindex] = ""
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    $game_temp.choice_start = 0
    setup_choices(@parameters)
    # Continue
    return true
  end

  #--------------------------------------------------------------------------
  # * Input Number
  #--------------------------------------------------------------------------
  def command_103
    # If text has been set to message_text
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # just adding index
    if $game_temp.message_text[@msgindex] != nil
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
      # End
      return false
    end
    # Set message end waiting flag and callback
    @message_waiting = true
#------------------------------------------------------------------------------
# Begin Multiple Message Windows Edit
#------------------------------------------------------------------------------
    # adding more indexes
    $game_temp.message_proc[@msgindex] = Proc.new { @message_waiting = false }
    # Number input setup
    $game_temp.message_text[@msgindex] = ""
#------------------------------------------------------------------------------
# End Multiple Message Windows Edit
#------------------------------------------------------------------------------
    $game_temp.num_input_start = 0
    $game_temp.num_input_variable_id = @parameters[0]
    $game_temp.num_input_digits_max = @parameters[1]
    # Continue
    return true
  end
  
  #--------------------------------------------------------------------------
  # * Script
  #--------------------------------------------------------------------------
  # Fix for RMXP bug: call script boxes that return false hang the game
  # See, e.g., http://rmxp.org/forums/showthread.php?p=106639  
  #--------------------------------------------------------------------------
  def command_355
    # Set first line to script
    script = @list[@index].parameters[0] + "\n"
    # Loop
    loop do
      # If next event command is second line of script or after
      if @list[@index+1].code == 655
        # Add second line or after to script
        script += @list[@index+1].parameters[0] + "\n"
      # If event command is not second line or after
      else
        # Abort loop
        break
      end
      # Advance index
      @index += 1
    end
    # Evaluation
    result = eval(script)
    # If return value is false
    if result == false
      # End
#------------------------------------------------------------------------------
# Begin Edit
#------------------------------------------------------------------------------
      #return false
#------------------------------------------------------------------------------
# End Edit
#------------------------------------------------------------------------------
    end
    # Continue
    return true
  end
  
  def message
    $game_system.message
  end
  
end

#------------------------------------------------------------------------------

class Game_Map
  attr_accessor :last_display_x                # last display x-coord * 128
  attr_accessor :last_display_y                # last display y-coord * 128
  
  alias wachunga_mmw_game_map_update update
  def update
    @last_display_x = @display_x
    @last_display_y = @display_y
    wachunga_mmw_game_map_update
  end
  
  def name
    return load_data('Data/MapInfos.rxdata')[@map_id].name
  end
end
  
#------------------------------------------------------------------------------

class Bitmap
  
  attr_accessor :orientation

  #--------------------------------------------------------------------------
  # * Rotation Calculation
  #--------------------------------------------------------------------------
  def rotation(target)
    return if not [0, 90, 180, 270].include?(target) # invalid orientation
    if @rotation != target
      degrees = target - @orientation
      if degrees < 0
        degrees += 360
      end
      rotate(degrees)
    end    
  end
  
  #--------------------------------------------------------------------------
  # * Rotate Square (Clockwise)
  #--------------------------------------------------------------------------
  def rotate(degrees = 90)
    # method originally by SephirothSpawn
    # would just use Sprite.angle but its rotation is buggy
    # (see http://www.rmxp.org/forums/showthread.php?t=12044)
    return if not [90, 180, 270].include?(degrees)
    copy = self.clone
    if degrees == 90
      # Passes Through all Pixels on Dummy Bitmap
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(width - i - 1, j, copy.get_pixel(j, i))
        end
      end
    elsif degrees == 180
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(width - j - 1, height - i - 1, copy.get_pixel(j, i))
        end
      end      
    elsif degrees == 270
      for i in 0...self.height
        for j in 0...self.width
          self.set_pixel(i, height - j - 1, copy.get_pixel(j, i))
        end
      end
    end
    @orientation = (@orientation + degrees) % 360
  end

end

