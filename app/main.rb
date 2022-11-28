def tick args
  # Initialize state of interactable sprites in the game. The "||=" operator sets the value only if uninitialized.
  # Which means, it will only run once at the beginning of the game.
  args.state.angles ||= {}
  args.state.angles['gas'] ||= [0, -90]
  args.state.angles['lightbowl'] ||= [0, -45, 45]
  args.state.angles['magnet'] ||= [0, -90, -180, -270]
  args.state.angles['table'] ||= [0, -45, 45]
  args.state.birdflip ||= 0

  # Define the path the bullet can take during the shootout phase.
  args.state.bullet_phase = 0
  args.state.bullet_paths = [
    [{start_x: 700, end_x: 400, start_y: 304, end_y: 304}]
  ]

  args.state.highlights ||= {}
  args.state.rotations ||= {}
  args.state.seconds_to_live ||= 20
  args.state.timer ||= args.state.tick_count

  # Draw static sprites.
  args.outputs.sprites << {x: 0, y: 120, w: 1280, h: 660, path: 'sprites/wall.png'}
  args.outputs.sprites << {x: 0, y: 60, w: 300, h: 342, path: 'sprites/lab.png'}
  
  # Draw interactables.
  draw_interactable(args, 'birdstand', {x: 420, y: 592, w: 90, h: 128})
  draw_interactable(args, 'birdy', {x: 440, y: 616, w: 56, h: 82}, 'birdstand')
  draw_interactable(args, 'clock', {x: 148, y: 262, w: 140, h: 66})
  draw_interactable(args, 'frame', {x: 890, y: 440, w: 184, h: 220})
  draw_interactable(args, 'gas', {x: 1050, y: 60, w: 128, h: 260, angle_anchor_y: 0.2})
  draw_interactable(args, 'lightbowl', {x: 635, y: 550, w: 70, h: 48, angle_anchor_y: 0.7})
  draw_interactable(args, 'lightfixture', {x: 660, y: 580, w: 21, h: 140})
  draw_interactable(args, 'magnet', {x: 230, y: 470, w: 78, h: 88})
  draw_interactable(args, 'pizzamonster', {x: 903, y: 484, w: 154, h: 130}, 'frame')
  draw_interactable(args, 'table', {x: 540, y: 60, w: 248, h: 165})
  draw_interactable(args, 'tnp', {x: 905, y: 481, w: 140, h: 164}, 'frame')

  # Draw characters.
  draw_aiyaman args
  draw_bullet args
  draw_jimmy args

  # Draw timer.
  args.outputs.labels << {x: 170, y: 312, text: "%05.2f" % countdown(args).to_s, size_enum: 8,
      r: args.state.highlights['clock'] == 1 ? 225 : 0}

  # Prompts player to start the game, or show failure message if game ended.
  check_game_state args
end


# Game start, fail state and music check.
def check_game_state args
  if !args.state.is_playing
    # If the game has not started yet, display instructions.
    args.outputs.labels <<  { x: 640, y: 360, text: 'Press "Space" to Start',
        alignment_enum: 1, vertical_alignment_enum: 1 }

    # Start a music loop at the beginning of the game. By default, .ogg files are looped forever.
    args.audio[:music] ||= { input: 'sounds/reverse-time.ogg', looping: true, gain: 0.2 }
    
    if args.inputs.keyboard.key_down.space
      # If the player press space, set the game started flag to true.
      args.state.is_playing = true

      # Stop currently playing music and load the time-stop music.
      args.audio.delete :music
      args.audio[:music] = { input: 'sounds/time-stop.ogg',  gain: 0.2 }

      # Reset animation and timers.
      args.state.animation_start = args.state.timer = args.state.tick_count
    end
  end

  # If the player has failed, show failure label.
  if args.state.failure
    message = 'You have died. Press "Space" or "R" to restart.'
    cause = 'Try clicking various objects in the environment.'

    args.outputs.labels << { x: 640, y: 374, text: message, alignment_enum: 1, vertical_alignment_enum: 1 }
    args.outputs.labels << { x: 640, y: 346, text: cause, alignment_enum: 1, vertical_alignment_enum: 1, size_enum: -2 }
  end

  # Allow game reset.
  if args.inputs.keyboard.key_down.r || args.state.failure && args.inputs.keyboard.key_down.space
    args.gtk.reset
  end
end


# Returns the time remaining in seconds from args.state.timer.
def countdown args
  time = args.state.seconds_to_live
  return args.state.is_playing ? [time - args.state.timer.elapsed_time / 60, 0].max : time
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
  sprite_index ||= args.state.failure ? number_of_sprites : args.state.is_playing ? number_of_sprites - 2 : 0

  # Send aiyaman flying if failure state is reached.
  if args.state.failure
    knockback_progress = args.state.failure.ease(1.seconds, :flip, :quad, :flip)
    current_rotation = 90 * knockback_progress
    current_x = 300 + -680 * knockback_progress
    current_y = 40 + -20 * knockback_progress
  end

  # Set default x, y and rotation values.
  current_rotation ||= 0
  current_x ||= 300
  current_y ||= 40
  
  # Present the sprite.
  args.outputs.sprites << { x: current_x, y: current_y, w: 255, h: 435, angle: current_rotation,
      path: "sprites/aiyaman/stand-#{sprite_index}.png" }
end


# Draws the bullet, which only happens when during end-game shootout where 'args.state.is_ending' is true.
def draw_bullet args
  if args.state.is_ending && args.state.shootout_start
    interpolation = args.state.shootout_start.ease(3, :identity)
    start_x = 700
    end_x = 400
    current_x = start_x + (end_x - start_x) * interpolation

    if current_x != end_x
      # Draw the bullet sprite moving to its path.
      args.outputs.sprites << { x: current_x, y: 304, w: 108, h: 12, path: 'sprites/bullet-0.png' }
    else
      # The bullet reached aiyaman. End the game in failure.
      args.state.failure ||= args.state.tick_count
    end
  end
end


# This draws an interactable sprite where it can be selected by the player to change its state in the game.
def draw_interactable(args, id, rect, combine = id)
  # Highlight sprite if the game is active and when mouse is inside the sprite's rectangle.
  args.state.highlights[id] = args.state.is_playing && !args.state.is_ending &&
      args.inputs.mouse.inside_rect?(rect) ? 1 : 0

  # Update the rotation of the sprite.
  rotated = rotate(args, id, rect)

  # If clock is interacted with, trigger end game shootout.
  if id == 'clock' && !args.state.is_ending && args.state.is_playing &&
        args.inputs.mouse.inside_rect?(rect) && args.inputs.mouse.click
    args.state.is_ending = true
    args.state.seconds_to_live = 0
  end

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

    # Make jimmy shoot gun when countdown reaches zero.
    if countdown(args) == 0
      # Set the shootout start time to the current tick, once.
      args.state.shootout_start ||= args.state.tick_count

      # Calculate for how long should the gun be animated.
      gun_index = args.state.shootout_start.frame_index(2, 4, false)

      # Play gunshot sound only once.
      if args.state.shootout_start == args.state.tick_count
        args.outputs.sounds << 'sounds/gunshot.wav'
      end
    end
    
    gun_index ||= 0

    # Draw the sprite at the interpolated position.
    args.outputs.sprites << { x: current_x, y: current_y, w: 312, h: 386, path: 'sprites/jimmy/throw-0.png'}

    # Draw jimmy's equipments together with him as well.
    args.outputs.sprites << { x: current_x - 40, y: current_y + 230, w: 76, h: 46,
        path: "sprites/gun-#{gun_index}.png" }
    args.outputs.sprites << { x: current_x + 270, y: current_y + 310, w: 56, h: 66, path: 'sprites/shuriken.png' }
    args.outputs.sprites << { x: current_x + 130, y: current_y + 310, w: 60, h: 20, path: 'sprites/sunglasses.png' }
  end
end


# Rotate a given rect of an interactable if interact button is triggered.
def rotate(args, id, rect)
  # Declare initial variables for interactables' angles and rotations.
  args.state.angles[id] ||= []
  args.state.rotations[id] ||= 0

  # Get the maximum index of the rotation angles available for the given id.
  limit = args.state.angles[id].length - 1

  # Increment the rotation index by one if the game is active and there is a mouse click on the interactable.
  is_rotated = args.state.is_playing && !args.state.is_ending &&
      args.inputs.mouse.inside_rect?(rect) && args.inputs.mouse.click
  increment = args.state.rotations[id] + (is_rotated ? 1 : 0)
  
  # Play sound if interactable is being rotated.
  if is_rotated
    # Some sounds have the same filename as the id, use those sounds for those interactables.
    random_number = rand(3)
    random_name = id == 'clock' ? 'sounds/clock.wav' : "sounds/#{id}-#{random_number}.wav"
    
    # Otherwise, use the normal metal turn sound.
    sound_name = File.exists?("mygame/#{random_name}") ? random_name : "sounds/turn-#{random_number}.wav"

    # For some overlapping interactables, they will be excluded from playing any sounds.
    if !['tnp', 'pizzamonster', 'birdy'].include? id
      args.outputs.sounds << sound_name
    end
  end

  # Try to increment the index now, but reset to 0 if exceeds the length of the limit array.
  next_index = args.state.angles[id] && increment <= limit ? increment : 0
  
  # Update the rotation index state in args.
  args.state.rotations[id] = next_index

  # Merge the angle into the rect hash so that it can be drawn.
  return rect.merge({angle: args.state.angles[id][next_index]})
end
