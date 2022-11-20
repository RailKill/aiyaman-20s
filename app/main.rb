def tick args
  # Initialize state of interactable sprites in the game. The "||=" operator sets the value only if uninitialized.
  # Which means, it will only run once at the beginning of the game.
  args.state.highlights ||= {}
  args.state.timer ||= args.state.tick_count

  one_time_animation args

  args.outputs.labels << {x: 170, y: 312, text: "%05.2f" % countdown(args).to_s, size_enum: 8,
      r: args.state.highlights["clock"] == 1 ? 225 : 0}

  # Draw static sprites.
  args.outputs.sprites << {x: 0, y: 120, w: 1280, h: 660, path: "sprites/wall.png"}
  args.outputs.sprites << {x: 0, y: 60, w: 300, h: 342, path: "sprites/lab.png"}
  
  # Draw interactables.
  draw_interactable(args, "birdstand", {x: 420, y: 592, w: 90, h: 128})
  draw_interactable(args, "birdy", {x: 440, y: 616, w: 56, h: 82}, "birdstand")
  draw_interactable(args, "clock", {x: 148, y: 262, w: 140, h: 66})
  draw_interactable(args, "frame", {x: 890, y: 440, w: 184, h: 220})
  draw_interactable(args, "gas", {x: 1050, y: 60, w: 128, h: 260})
  draw_interactable(args, "lightbowl", {x: 635, y: 550, w: 70, h: 48})
  draw_interactable(args, "lightfixture", {x: 660, y: 580, w: 21, h: 140})
  draw_interactable(args, "magnet", {x: 230, y: 470, w: 78, h: 88})
  draw_interactable(args, "pizzamonster", {x: 903, y: 484, w: 154, h: 130}, "frame")
  draw_interactable(args, "table", {x: 540, y: 60, w: 248, h: 165})
  draw_interactable(args, "tnp", {x: 905, y: 481, w: 140, h: 164}, "frame")

end

# Returns the time remaining in seconds from args.state.timer.
def countdown args
  return [20 - args.state.timer.elapsed_time / 60, 0].max
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
    args.state.start_looping_at = args.state.timer = args.state.tick_count
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
  args.outputs.sprites << { x: 300, y: 40, w: 255, h: 435, path: "sprites/aiyaman/stand-#{sprite_index}.png" }
end


# This draws an interactable sprite where it can be selected by the player to change its state in the game.
def draw_interactable(args, id, rect, combine = id)
  # Highlight sprite when mouse is inside the sprite's rectangle.
  args.state.highlights[id] = (args.inputs.mouse.inside_rect? rect) ? 1 : 0

  # Draw the sprite.
  args.outputs.sprites << rect.merge({path: "sprites/#{id}-#{args.state.highlights[combine]}.png"})
end