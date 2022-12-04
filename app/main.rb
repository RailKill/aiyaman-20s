def tick args
  # Initialize state of interactable sprites in the game. The "||=" operator sets the value only if uninitialized.
  # Which means, it will only run once at the beginning of the game.
  args.state.angles ||= {}
  args.state.angles['gas'] ||= [0, -90]
  args.state.angles['lightbowl'] ||= [0, -45, 45]
  args.state.angles['magnet'] ||= [0, -90, -180, -270]
  args.state.angles['magnetbroken'] ||= [0, -90, -180, -270]
  args.state.angles['table'] ||= [0, -45, 45]
  args.state.birdflip ||= 0

  # Define the path the bullet can take during the shootout phase.
  args.state.bullet_phase ||= 0

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
  draw_interactable(args, 'magnet' + (args.state.is_magnet_destroyed ? 'broken' : ''), {x: 230, y: 470, w: 78, h: 88})
  draw_interactable(args, 'pizzamonster', {x: 903, y: 484, w: 154, h: 130}, 'frame')
  draw_interactable(args, 'table', {x: 540, y: args.state.rotations['table'] == 0 ? 60 : 120, w: 248, h: 165})
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
    cause = get_cause args
    color = args.state.explosion && args.state.failure ? { r: 255, g: 255, b: 255 } : { r: 0, g: 0, b: 0 }

    args.outputs.labels << { x: 640, y: 374, text: message,
        alignment_enum: 1, vertical_alignment_enum: 1 }.merge(color)
    args.outputs.labels << { x: 640, y: 346, text: cause,
        alignment_enum: 1, vertical_alignment_enum: 1, size_enum: -2 }.merge(color)
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
    # Interpolate the x and y positions given the bullet path of the current bullet phase.
    interpolation = args.state.bullet_bounce.ease(3, :identity)
    path = args.state.bullet_paths[args.state.bullet_phase]
    current_x = path.start_x + (path.end_x - path.start_x) * interpolation
    current_y = path.start_y + (path.end_y - path.start_y) * interpolation

    # If the bullet is still travelling, draw the bullet sprite moving to its path.
    if current_x != path.end_x || current_y != path.end_y
      args.outputs.sprites << { x: current_x, y: current_y, w: 108, h: 12, angle: path.angle,
          path: 'sprites/bullet-0.png' }
    # Otherwise, go to next bullet path and play ricochet impact sound.
    elsif args.state.bullet_phase + 1 < args.state.bullet_paths.length
      args.state.bullet_phase += 1
      args.state.bullet_bounce = args.state.tick_count
      args.outputs.sounds << "sounds/metal-impact-#{rand(3)}.wav"
    # The bullet reached the end of its path.
    else
      # It reached aiyaman. End the game in failure.
      if current_x == 400 && current_y <= 360
        kill_aiyaman args
      # It reached the magnet. Destroy it.
      elsif current_x == 260 && current_y == 490
        args.state.is_magnet_destroyed = true
        args.state.rotations['magnetbroken'] = args.state.rotations['magnet']
        args.state.shuriken_throw ||= args.state.tick_count
        if args.state.shuriken_throw == args.state.tick_count
          args.outputs.sounds << 'sounds/mini-woosh.wav'
          args.outputs.sounds << 'sounds/metal-break.wav'
        end
        # TODO: Introduce delay to dropped to make it more natural.
        args.state.shuriken_dropped ||= args.state.tick_count
      # It reached jimmy. Remove sunglasses.
      elsif current_x == 860 && current_y == 380
        args.state.sunglasses_removed ||= args.state.tick_count
        if args.state.sunglasses_removed == args.state.tick_count
          args.outputs.sounds << 'sounds/wham.wav'
        end
      # It reached the shuriken. Drop it.
      elsif current_x == 1000 && current_y == 400
        args.state.shuriken_dropped ||= args.state.tick_count
        if args.state.shuriken_dropped == args.state.tick_count
          args.outputs.sounds << 'sounds/wham.wav'
        end
      end
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
      args.state.is_ending = true

      # Calculate for how long should the gun be animated.
      gun_index = args.state.shootout_start.frame_index(2, 4, false)

      # Play gunshot sound only once.
      if args.state.shootout_start == args.state.tick_count
        args.outputs.sounds << 'sounds/gunshot.wav'

        # Define bullet paths.
        base_to_lamp = {start_x: 690, end_x: 630, start_y: 230, end_y: 520, angle: -77}
        gun_to_aiyaman = {start_x: 700, end_x: 400, start_y: 304, end_y: 304}
        gun_to_table = {start_x: 700, end_x: 650, start_y: 304, end_y: 304}
        table_to_aiyaman = {start_x: 540, end_x: 400, start_y: 280, end_y: 280}
        table_to_lamp = {start_x: 620, end_x: 620, start_y: 340, end_y: 520, angle: -90}
        table_to_base = {start_x: 660, end_x: 685, start_y: 270, end_y: 230, angle: 120}
        lamp_to_aiyaman = {start_x: 580, end_x: 400, start_y: 540, end_y: 360, angle: 45}
        lamp_to_jimmy = {start_x: 630, end_x: 860, start_y: 550, end_y: 380, angle: 140}
        lamp_to_magnet = {start_x: 570, end_x: 260, start_y: 560, end_y: 490, angle: 15}
        lamp_to_shuriken = {start_x: 660, end_x: 1000, start_y: 550, end_y: 400, angle: 155}
        lamp_to_table = {start_x: 608, end_x: 588, start_y: 520, end_y: 320, angle: 80}

        # If the table is not rotated, set first path to aiyaman, else to table.
        bang = args.state.rotations['table'] == 0 ? [gun_to_aiyaman] : [gun_to_table]

        # Depending on the rotation of the table, either there is no ricochet or deflect to lamp.
        table = [[nil], [table_to_lamp], [table_to_base, base_to_lamp]][args.state.rotations['table']]

        # Depending on the rotation of the table, set the bullet paths for lamp.
        lamp = [[nil], [lamp_to_aiyaman], [lamp_to_jimmy]]
        lamp_skewed = [[lamp_to_table, table_to_aiyaman], [lamp_to_magnet], [lamp_to_shuriken]]
        lamp_select = [[[nil]], lamp, lamp_skewed][args.state.rotations['table']][args.state.rotations['lightbowl']]

        # Determine the paths which the bullet will take based on table and lamp configurations.
        args.state.bullet_paths = (bang + table + lamp_select).compact

        # Set bullet bounce time to start from now.
        args.state.bullet_bounce = args.state.tick_count
      end
    end
    
    # Reset gun index to 0.
    gun_index ||= 0

    # Determine if jimmy is playing animation to throw shuriken.
    if args.state.shuriken_throw
      sprite_index = args.state.shuriken_throw.frame_index(3, 4, false)
    end
    sprite_index ||= args.state.shuriken_throw ? 4 : 0

    # Draw the sprite at the interpolated position.
    args.outputs.sprites << { x: current_x, y: current_y, w: 312, h: 386,
        path: "sprites/jimmy/throw-#{sprite_index}.png" }

    # Draw jimmy's gun.
    args.outputs.sprites << { x: current_x - 40, y: current_y + 230, w: 76, h: 46,
        path: "sprites/gun-#{gun_index}.png" }

    # Draw shuriken.
    draw_shuriken(args, current_x, current_y)

    # Draw sunglasses.
    draw_sunglasses(args, current_x, current_y)
    
  end
end

# Draws jimmy's shuriken based on his position.
def draw_shuriken(args, jimmy_x, jimmy_y)
  # Declare shuriken position.
  args.state.spin.shuriken ||= 0
  args.state.spin.shuriken += args.state.shuriken_dropped ? 30 : 0
  shuriken_x = jimmy_x + 270
  shuriken_y = jimmy_y + 310

  # If the shuriken is being dropped or shot out of hand, determine its path.
  if args.state.shuriken_dropped
    # Check if the table and lamp are rotated in the right way for shuriken to be dropped.
    shuriken_condition = args.state.rotations['table'] == 2  && args.state.rotations['lightbowl'] == 2
    # Calculate current time interpolation from the dropped time.
    ease_method = shuriken_condition ? [:flip, :quad, :flip] : [:identity]
    duration = shuriken_condition ? 0.7 : 0.3
    shuriken_time = args.state.shuriken_dropped.ease(duration.seconds, ease_method)
    # Calculate the shuriken curve.
    shuriken_curve_x = shuriken_condition ? shuriken_x + 10 : shuriken_x - 335
    shuriken_end_x = shuriken_condition ? shuriken_x + 20 : shuriken_x - 670
    shuriken_curve_y = shuriken_condition ? shuriken_y + 100 : shuriken_y + 200
    shuriken_end_y = shuriken_condition ? shuriken_y - 200 : shuriken_y - 50
    # Apply changes to shuriken position based on quadratic bezier curve.
    shuriken_x = quadratic_bezier(shuriken_time, shuriken_x, shuriken_curve_x, shuriken_end_x)
    shuriken_y = quadratic_bezier(shuriken_time, shuriken_y, shuriken_curve_y, shuriken_end_y)
  end

  # Check if shuriken needs to be drawn or trigger any event.
  is_magnetized = args.state.rotations['magnet'] == 1 && !args.state.is_magnet_destroyed
  if shuriken_x == jimmy_x - 400 && shuriken_y == jimmy_y + 260 && !is_magnetized
    # Shuriken reached aiyaman.
    kill_aiyaman args
  elsif shuriken_x == jimmy_x + 290 && shuriken_y == jimmy_y + 110
    # Shuriken reached gas tank.
    explode args
  else
    # If shuriken is mid-flight and magnet is in the right position, change its course.
    if shuriken_x < jimmy_x - 200 && is_magnetized
      args.state.shuriken_magnetized ||= args.state.tick_count
      change_time = args.state.shuriken_magnetized.ease(0.7.seconds, :flip, :quad, :flip)
      change_start_x = 620
      change_start_y = 380
      change_curve_x = change_start_x
      change_curve_y = change_start_y + 150
      change_end_x = 300
      change_end_y = 480
      shuriken_x = quadratic_bezier(change_time, change_start_x, change_curve_x, change_end_x)
      shuriken_y = quadratic_bezier(change_time, change_start_y, change_curve_y, change_end_y)
    end
    # Shuriken is stationary or in-flight, draw it normally.
    args.outputs.sprites << { x: shuriken_x, y: shuriken_y, w: 56, h: 66, angle: args.state.spin.shuriken,
        path: 'sprites/shuriken.png' }
  end
end

# Draws jimmy's sunglasses based on his position.
def draw_sunglasses(args, jimmy_x, jimmy_y)
  # Declare sunglasses position.
  args.state.spin.sunglasses ||= 0
  args.state.spin.sunglasses += args.state.sunglasses_removed ? -5 : 0
  glasses_x = jimmy_x + 130
  glasses_y = jimmy_y + 310

  if args.state.sunglasses_removed
    # Calculate time interpolation from when sunglasses were removed.
    time = args.state.sunglasses_removed.ease(0.7.seconds, :flip, :quad, :flip)
    curve_x = glasses_x + 10
    curve_y = glasses_y + 100
    end_x = glasses_x + 20
    end_y = glasses_y - 600
    glasses_x = quadratic_bezier(time, glasses_x, curve_x, end_x)
    glasses_y = quadratic_bezier(time, glasses_y, curve_y, end_y)

    # Once glasses fall to a certain height, trigger shuriken throw.
    if glasses_y < 400
      args.state.shuriken_throw ||= args.state.tick_count
      if args.state.shuriken_throw == args.state.tick_count
        args.outputs.sounds << 'sounds/mini-woosh.wav'
      end
    end

    # Delay shuriken travel to make it look more natural.
    if glasses_y < 350
      args.state.shuriken_dropped ||= args.state.tick_count
    end
  end

  args.outputs.sprites << { x: glasses_x, y: glasses_y, w: 60, h: 20, angle: args.state.spin.sunglasses,
      path: 'sprites/sunglasses.png' }
end


# Determines if a gas tank explosion has happened.
def explode args
  args.state.explosion ||= args.state.tick_count
  if args.state.explosion == args.state.tick_count
    args.outputs.sounds << 'sounds/explosion.wav'
    kill_aiyaman args
  end

  # Draw an expanding circle to represent the explosion.
  args.state.boom ||= { x: 1065, y: 80, w: 100, h: 100 }
  args.state.boom = args.state.boom.w < 2000 ? args.state.boom.scale_rect(1.5, 0.5, 0.5) : args.state.boom
  args.outputs.primitives << args.state.boom.merge({primitive_marker: :solid})
end


# Returns the cause of success or failure.
def get_cause args
  if args.state.explosion
    return 'You hit the gas tank and killed yourself.'
  elsif args.state.shuriken_throw
    return 'You deflected the bullet, but did not stop the shuriken.'
  else
    return 'Try clicking various objects in the environment.'
  end
end


# Trigger game over by killing aiyaman.
def kill_aiyaman args
  args.state.failure ||= args.state.tick_count
  if args.state.failure == args.state.tick_count
    args.outputs.sounds << 'sounds/stab.wav'
    args.outputs.sounds << 'sounds/aiyaa.wav'
  end
end


# Interpolate and draw a bezier curve for smooth movement.
# Reference: https://devforum.roblox.com/t/how-to-tweenlerp-a-bezier-curve/1174077
def quadratic_bezier(time, start, curve, endpoint)
  a = start + (curve - start) * time
  b = curve + (endpoint - curve) * time
  return a + (b - a) * time
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
