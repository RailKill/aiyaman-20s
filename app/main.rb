def tick args
  # Initialize state of interactable sprites in the game. The "||=" operator sets the value only if uninitialized.
  # Which means, it will only run once at the beginning of the game.
  args.state.table ||= 0

  one_time_animation args
  
  draw_interactable(args, {x: 400, y: 200, w: 185, h: 124, path: "sprites/table-#{args.state.table}.png"})
end


# This function shows how to animate a sprite that executes
# only once when the "f" key is pressed.
def one_time_animation args
  # This is just a label the shows instructions within the game.
  args.outputs.labels <<  { x: 220, y: 350, text: "(press f to animate)" }

  # If "f" is pressed on the keyboard...
  if args.inputs.keyboard.key_down.f
    # Print the frame that "f" was pressed on.
    puts "Hello from main.rb! The \"f\" key was in the down state on frame: #{args.state.tick_count}"

    # And MOST IMPORTANTLY set the point it time to start the animation,
    # equal to "now" which is represented as args.state.tick_count.

    # Also IMPORTANT, you'll notice that the value of when to start looping
    # is stored in `args.state`. This construct's values are retained across
    # executions of the `tick` method.
    args.state.start_looping_at = args.state.tick_count
  end

  # These are the same local variables that were defined
  # for the `looping_animation` function.
  number_of_sprites = 7
  number_of_frames_to_show_each_sprite = 4

  # Except this sprite does not loop again. If the animation time has passed,
  # then the frame_index function returns nil.
  does_sprite_loop = false

  sprite_index = args.state
                     .start_looping_at
                     .frame_index number_of_sprites,
                                  number_of_frames_to_show_each_sprite,
                                  does_sprite_loop

  # This line sets the frame index to zero, if
  # the animation duration has passed (frame_index returned nil).

  # Remeber: we are not looping forever here.
  sprite_index ||= 0

  # Present the sprite.
  args.outputs.sprites << { x: 322, y: 372, w: 170, h: 290, path: "sprites/aiyaman/stand-#{sprite_index}.png" }
end


# This is creates an interactable sprite where it can be selected by the player to change its state in the game.
def draw_interactable(args, sprite)
  if args.inputs.mouse.click and args.inputs.mouse.inside_rect? sprite
    puts "I have clicked inside!"
    args.state.table ^= 1
    puts "Table index is now: #{args.state.table}"
  end

  # Spawn the sprite.
  args.outputs.sprites << sprite
end