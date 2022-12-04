# Plays the victory cutscene.
def play_cutscene args
  if args.state.cutscene_start
    # Calculate aiyaman's sprite index from cutscene_start.
    aiyaman_index = args.state.cutscene_start.frame_index(13, 2, false)
    # When animation ends, set it to the last sprite index.
    aiyaman_index ||= 12

    # Send aiyaman flying if failure state is reached.
    if aiyaman_index >= 7
      args.state.jimmy_knockback ||= args.state.tick_count
      jimmy_progress = args.state.jimmy_knockback.ease(0.2.seconds, :flip, :quad, :flip)
      jimmy_x = 1300 + -780 * jimmy_progress

      # Play hit sound.
      if args.state.jimmy_knockback == args.state.tick_count
        args.outputs.sounds << 'sounds/hit.wav'
      end

      if jimmy_x < 600
        args.state.jimmy_hurt ||= args.state.tick_count
        jimmy_index = args.state.jimmy_hurt.frame_index(4, 2, false)
        jimmy_index ||= 3
        gas_progress = (args.state.jimmy_hurt + 0.5.seconds).ease(0.2.seconds, :flip, :quad, :flip)
        gas_x = 1300 + -550 * gas_progress

        aiyaman_progress = args.state.jimmy_hurt.ease(0.3.seconds, :quad)
        aiyaman_x = 360 + -700 * aiyaman_progress
      end
    end

    # Set default values.
    aiyaman_x ||= 360
    gas_x ||= 1300
    jimmy_index ||= 0
    jimmy_x ||= 1300

    # Play charge sound.
    if args.state.cutscene_start + 1 == args.state.tick_count
      args.outputs.sounds << 'sounds/resume.wav'
    end
    
    # Present the sprite.
    if gas_x > 750
      args.outputs.sprites << { x: aiyaman_x, y: 100, w: 371, h: 302,
          path: "sprites/aiyaman/drive-#{aiyaman_index}.png" }

      args.outputs.sprites << { x: jimmy_x, y: 90, w: 270, h: 368,
          path: "sprites/jimmy/drive-#{jimmy_index}.png" }
      
      args.outputs.sprites << { x: gas_x, y: 100, w: 128, h: 260, path: 'sprites/gas-0.png'}
    else
      # Draw a center explosion.
      args.state.win_alpha ||= 255
      args.state.win_boom ||= { x: 640, y: 360, w: 100, h: 100 }
      args.state.win_time ||= args.state.tick_count
      args.state.win_boom = args.state.win_boom.w < 2000 ?
          args.state.win_boom.scale_rect(1.5, 0.5, 0.5) : args.state.win_boom
      args.state.win_alpha -= args.state.tick_count > args.state.win_time + 3.seconds && args.state.win_alpha > 0 ?
          4 : 0
          
      args.outputs.primitives << args.state.win_boom.merge(
          {primitive_marker: :solid, alignment_enum: 1, vertical_alignment_enum: 1, a: args.state.win_alpha})

      # Play explosion sound once.
      if args.state.win_time == args.state.tick_count
        args.outputs.sounds << 'sounds/explosion.wav'
      end

      # Draw burnt.
      if args.state.tick_count > args.state.win_time + 3.seconds
        args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 800, a: 100, path: 'sprites/jimmy/burnt.png' }
      end
    end
  end
end