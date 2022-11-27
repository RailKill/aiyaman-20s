def tick args
  # Initialize state of interactable sprites in the game. The "||=" operator sets the value only if uninitialized.
  # Which means, it will only run once at the beginning of the game.
  args.state.angles ||= {}
  args.state.angles["gas"] ||= [0, -90]
  args.state.angles["lightbowl"] ||= [0, -45, 45]
  args.state.angles["magnet"] ||= [0, -90, -180, -270]
  args.state.angles["table"] ||= [0, -45, 45]
  args.state.birdflip ||= 0
  args.state.highlights ||= {}
  args.state.rotations ||= {}
  args.state.timer ||= args.state.tick_count

  # Draw static sprites.
  args.outputs.sprites << {x: 0, y: 120, w: 1280, h: 660, path: "sprites/wall.png"}
  args.outputs.sprites << {x: 0, y: 60, w: 300, h: 342, path: "sprites/lab.png"}
  
  # Draw interactables.
  draw_interactable(args, "birdstand", {x: 420, y: 592, w: 90, h: 128})
  draw_interactable(args, "birdy", {x: 440, y: 616, w: 56, h: 82}, "birdstand")
  draw_interactable(args, "clock", {x: 148, y: 262, w: 140, h: 66})
  draw_interactable(args, "frame", {x: 890, y: 440, w: 184, h: 220})
  draw_interactable(args, "gas", {x: 1050, y: 60, w: 128, h: 260, angle_anchor_y: 0.2})
  draw_interactable(args, "lightbowl", {x: 635, y: 550, w: 70, h: 48, angle_anchor_y: 0.7})
  draw_interactable(args, "lightfixture", {x: 660, y: 580, w: 21, h: 140})
  draw_interactable(args, "magnet", {x: 230, y: 470, w: 78, h: 88})
  draw_interactable(args, "pizzamonster", {x: 903, y: 484, w: 154, h: 130}, "frame")
  draw_interactable(args, "table", {x: 540, y: 60, w: 248, h: 165})
  draw_interactable(args, "tnp", {x: 905, y: 481, w: 140, h: 164}, "frame")

  # Draw aiyaman.
  draw_aiyaman args

  # Draw jimmy.
  draw_jimmy args

  # Draw timer.
  args.outputs.labels << {x: 170, y: 312, text: "%05.2f" % countdown(args).to_s, size_enum: 8,
      r: args.state.highlights["clock"] == 1 ? 225 : 0}

  # Prompts player to start the game.
  start_game args
end


# Returns the time remaining in seconds from args.state.timer.
def countdown args
  countdown = 20
  return args.state.is_playing ? [countdown - args.state.timer.elapsed_time / 60, 0].max : countdown
end


# Draws the main protagonist on to the screen.
def draw_aiyaman args
  # Number of sprites in the animation.
  number_of_sprites = 7
  # Number of frames to hold the sprite for.
  frames_per_sprite = 4
  # Set if the animation is looping or not. The frame_index function returns nil if animation time has passed.
  is_looping = false

  # Calculate the index for the sprite to be displayed based on animation_start.
  sprite_index = args.state.animation_start.frame_index(number_of_sprites, frames_per_sprite, is_looping)

  # When sprite_index is nil due to animation end, set it to the second last sprite.
  sprite_index ||= args.state.is_playing ? number_of_sprites - 2 : 0

  # Present the sprite.
  args.outputs.sprites << { x: 300, y: 40, w: 255, h: 435, path: "sprites/aiyaman/stand-#{sprite_index}.png" }
end


# This draws an interactable sprite where it can be selected by the player to change its state in the game.
def draw_interactable(args, id, rect, combine = id)
  # Highlight sprite when mouse is inside the sprite's rectangle.
  args.state.highlights[id] = args.state.is_playing && args.inputs.mouse.inside_rect?(rect) ? 1 : 0

  # Update the rotation of the sprite.
  rotated = rotate(args, id, rect)

  # Draw the sprite.
  args.outputs.sprites << rotated.merge({path: "sprites/#{id}-#{args.state.highlights[combine]}.png"})
end


# Draws the main antagonist onto the screen.
def draw_jimmy args
  if args.state.is_playing
    # Get a normalized value from 0 to 1 of the progress of the ease function (tweening).
    progress = args.state.animation_start.ease(0.5.seconds, :flip, :quad, :flip)

    # Calculate current position.
    start_x = 1300
    end_x = 800
    current_x = start_x + (end_x - start_x) * progress
    current_y = 40

    # Draw the sprite at the interpolated position.
    args.outputs.sprites << { x: current_x, y: current_y, w: 312, h: 386, path: "sprites/jimmy/throw-0.png"}

    # Draw jimmy's equipments together with him as well.
    args.outputs.sprites << { x: current_x - 40, y: current_y + 230, w: 76, h: 46, path: "sprites/gun-0.png" }
    args.outputs.sprites << { x: current_x + 270, y: current_y + 310, w: 56, h: 66, path: "sprites/shuriken.png" }
    args.outputs.sprites << { x: current_x + 130, y: current_y + 310, w: 60, h: 20, path: "sprites/sunglasses.png" }
  end
end


# Rotate a given rect of an interactable if interact button is triggered.
def rotate(args, id, rect)
  # Declare initial variables for interactables' angles and rotations.
  args.state.angles[id] ||= []
  args.state.rotations[id] ||= 0

  # Get the maximum index of the rotation angles available for the given id.
  limit = args.state.angles[id].length - 1

  # Increment the rotation index by one if there is a mouse click on the interactable.
  is_mouse_over = args.inputs.mouse.inside_rect? rect
  increment = args.state.rotations[id] + (args.state.is_playing && is_mouse_over && args.inputs.mouse.click ? 1 : 0)

  # Try to increment the index now, but reset to 0 if exceeds the length of the limit array.
  next_index = args.state.angles[id] && increment <= limit ? increment : 0
  
  # Update the rotation index state in args.
  args.state.rotations[id] = next_index

  # Merge the angle into the rect hash so that it can be drawn.
  return rect.merge({angle: args.state.angles[id][next_index]})
end


# Game start check.
def start_game args
  if !args.state.is_playing
    # If the game has not started yet, display instructions.
    args.outputs.labels <<  { x: 640, y: 360, text: "Press 'Space' to Start",
        alignment_enum: 1, vertical_alignment_enum: 1 }
    
    if args.inputs.keyboard.key_down.space
      # If the player press space, set the game started flag to true.
      args.state.is_playing = true

      # Reset animation and timers.
      args.state.animation_start = args.state.timer = args.state.tick_count
    end
  end
end
