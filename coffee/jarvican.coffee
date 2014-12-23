$(() ->

  ctx = $("#canvas")[0].getContext("2d")

  # Game states
  #  - running
  #  - paused
  #  - spash
  #  - over

  # Mouse click events

  $("#canvas").click((e) ->
    switch game.state
      when "running"
        game.state = "hidden"
    return
  )

  $("pre.reg-banner").click((e) ->
    switch game.state
      when "hidden"
        $("pre.reg-banner").hide()
        $(".canvas-wrapper").show()

        $("#canvas")[0].width = 810
        $("#canvas")[0].height = 400

        # initial speed
        game.dx = 4
        game.dy = 8
        # initial position
        game.x = 150
        game.y = 150

        game.height = $("#canvas").height()
        game.width =  $("#canvas").width()

        game.mouse_min_x = $("#canvas").offset().left
        game.mouse_max_x = game.mouse_min_x + game.width - cfg.paddle_width
        game.paddle_x = game.width / 2

        ctx.font = "#{cfg.font_size}px #{cfg.font_name}"
        cfg.char_width = Math.round(ctx.measureText(".").width)

        $.ajax({
          url: '/jarv.json',
          datatype: "json", # load from github - "jsonp",
          success: (data) ->
            game.state = "running"
            game.disp_data = data
            setTimeout(game_loop, 10)
        })

    return
  )

  # Keyboard events
  
  $(document).keydown((evt) ->
    switch game.state
      when "running"
        if (evt.keyCode == 39) # ->
          game.right_down = true
        else if (evt.keyCode == 37) # <-
          game.left_down = true

    return
  )

  $(document).keyup((evt) ->
    switch game.state
      when "running"
        if (evt.keyCode == 39)
          game.right_down = false
        else if (evt.keyCode == 37)
          game.left_down = false
    return
  )

  # Mouse control for the paddles

  $(document).mousemove((evt) ->
    switch game.state
      when "running"
        if (evt.pageX > game.mouse_min_x and evt.pageX < game.mouse_max_x)
          game.paddle_x = evt.pageX - game.mouse_min_x
  )

  draw_circle = (x, y, r) ->
    ctx.beginPath()
    ctx.arc(x, y, r, 0, Math.PI*2, true)
    ctx.closePath()
    ctx.fill()
    return

  draw_rect = (x, y, w, h) ->
    ctx.beginPath()
    ctx.rect(x, y, w, h)
    ctx.closePath()
    ctx.fill()
    return

  clear_board = () ->
    ctx.clearRect(0, 0, game.width, game.height)
    return

  

  collision = (brick_x, brick_y) ->

    # center brick
    c_brick_x = brick_x + Math.round(cfg.char_width / 2)
    c_brick_y = brick_y + Math.round(cfg.font_size / 2)

    #
    #   ------- 
    #  | \ b / |
    #  |c \ / a|  
    #  |  / \  |
    #  | / d \ |  
    #  --------
    #
    # a = PI/4 to -PI/4
    # b = -PI/4 to -3PI/4
    # c = -3PI/4 to -PI or 3PI/4 to PI
    # d = PI/4 to 3PI/4
    
    # angle of (brick) attack
    game.aoa = Math.atan2((game.y - c_brick_y), (game.x - c_brick_x))

    switch
      when  game.aoa <=  Math.PI / 4 and game.aoa > -Math.PI / 4 # (a)
        if (game.dx <= 0)
          game.dx = -game.dx
      when  game.aoa <= -Math.PI / 4 and game.aoa > -3 * Math.PI / 4 # (b)
        if (game.dy >= 0)
          game.dy = -game.dy
      when (game.aoa <= -3 * Math.PI and game.aoa > -Math.PI) or (game.aoa <= Math.PI and game.aoa > 3 * Math.PI / 4) # (c)
        if (game.dx >= 0)
          game.dx = -game.dx
      when  game.aoa <= 3 * Math.PI / 4 and game.aoa > Math.PI / 4 # (d)
        if (game.dy <= 0)
          game.dy = -game.dy

    return

  game_loop = () ->

    clear_board()

    ypos = Math.round(cfg.font_size * 1.1)
    line_offset = (game.disp_data.length * cfg.font_size)
    for row, row_index in game.disp_data
      line_cnt = 0
      line_width = row.length
      xpos = Math.round((game.width / 2) - ( line_width * cfg.char_width / 2))

      for column, column_index in row

        brick_x = xpos
        brick_y = ypos

        if column != " "
            if ! ((game.x - game.ball_radius > brick_x + cfg.char_width) \
                or (game.x + game.ball_radius < brick_x) \
                or (game.y - game.ball_radius > brick_y + cfg.font_size) \
                or (game.y + game.ball_radius < brick_y))
              
              collision(brick_x, brick_y)
              game.disp_data[row_index][column_index] = " "
        ctx.fillStyle = '#939393'
        ctx.fillText(column, brick_x, brick_y)
        xpos += cfg.char_width
      ypos += cfg.font_size

    if game.state == "running"
      draw_circle(game.x, game.y, game.ball_radius)

      if game.right_down
        if game.paddle_x + cfg.paddle_width < game.width
          game.paddle_x += 5
      else if game.left_down
        if game.paddle_x > 0
          game.paddle_x -= 5

      draw_rect(game.paddle_x, game.height - cfg.paddle_height, cfg.paddle_width, cfg.paddle_height)

      # handle wall collisions
      if (game.x + game.ball_radius > game.width or game.x - game.ball_radius < 0)
        game.dx = -game.dx
      if (game.y - game.ball_radius < 0)
        game.dy = -game.dy
      else if (game.y + game.ball_radius > game.height - cfg.paddle_height)
        # ball is at the bottom of the board
        if (game.x + game.ball_radius > game.paddle_x and game.x - game.ball_radius < (game.paddle_x + cfg.paddle_width))
          # paddle collision
          game.dy = -game.dy
        else
          if game.state == "running"
            game.state = "hidden"

      game.x += game.dx
      game.y += game.dy

    switch game.state
      when "running"
        setTimeout(game_loop, 10)
      when "hidden"
        $("pre.reg-banner").show()
        $(".canvas-wrapper").hide()
        
    return

  cfg_defaults = {
    # cfg have vars that remain the same
    # through a single game
    paddle_height: 10
    paddle_width: 75
    font_size: 16
    font_name: "'Courier New', Monospace"
    figlet_font: "doh"
  }

  game_defaults = {
    # text to display
    str: "jarv",
    # initial speed
    dx: 4
    dy: 8
    # initial position
    x: 150
    y: 150
    right_down: false
    left_down: false

    state: "hidden"
    paddle_x: 0

    # raw data for words on the canvas
    disp_data: []

    # list of indexes where word
    # boundaries (used for word wrapping)
    word_boundaries: []
    # with of a space character, also
    # needed for word wrappering
    space_width: 0
    # Where lines are broken which varies
    # depending on the window size
    line_breaks: []

    ball_radius: 20

    debug: false

    # overridden by width of fullscreen
    width: 0
    height: 0
    mouse_min_x: 0
    mouse_max_x: 0

    # angle of attack
    aoa: 0
  }
  # update game state vars with defaults
  game = $.extend({}, game_defaults)
  # update config with defaults
  cfg = $.extend({}, cfg_defaults)

  return
)
