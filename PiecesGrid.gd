extends Node2D

export (PackedScene) var Piece
export var piece_speed = 3
export var accelerated_speed = 18

signal lose_game
signal increase_counter

const SHAPES = [
	[[1,1],
	 [1,1]],
	[[1,0],
	 [1,1],
	 [1,0]],
	[[1,1],
	 [1,0],
	 [1,0]],
	[[1,1],
	 [0,1],
	 [0,1]],
	[[1,0],
	 [1,1],
	 [0,1]],
	[[0,1],
	 [1,1],
	 [1,0]],
	[[1],
	 [1],
	 [1],
	 [1]],
]
const COLORS = [
	Color(1, 0.757, 0.027), #yellow g
	Color(0, 0.737, 0.831), #blue g
	Color(0.937, 0.325, 0.314), #red g
	Color(0.467, 0.910, 0.345), #green g
	Color(0.961, 0.498, 0.090), #orange
	Color(0.918, 0.502, 0.988), #purple
]
var last_shape_index
var last_color_index

var block_texture = load("res://assets/images/piece-white.png")

var game_started = false
var full_rows = 0
var frames_count = 0
var acceleration_frames_count = 0

var pixel_size = 11
var width  = 10
var height = 20
var grid = []
var colors_grid = []

var active_piece
var next_piece = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if game_started:
		control_movement()
		frames_count += 1
		if is_update_frame():
			update_active_piece()
			print_grid_and_active_piece()

func create_grid():
	for i in range(height):
		var row = []
		for j in range(width):
			row.append(0)
		grid.append(row)
		colors_grid.append(row.duplicate())

func start():
	for n in get_children():
		remove_child(n)
		n.queue_free()
	next_piece = null
	full_rows = 0
	grid = []
	create_grid()
	create_new_piece()
	game_started = true

func create_new_piece():
	# Other pieces
	if next_piece:
		active_piece = next_piece
		random_start_active_piece()
		if active_piece_overlaps_squares():
			while active_piece_overlaps_squares():
				active_piece.i_position -= 1	
			lose_game()
	# First piece
	else:
		active_piece = Piece.instance()	
		active_piece.init(pixel_size, random_shape(), random_color())
		random_start_active_piece()
	next_piece = Piece.instance()
	next_piece.init(pixel_size, random_shape(), random_color())
	next_piece.i_position = 4
	next_piece.j_position = 11
	add_child(next_piece)
	add_child(active_piece)

func random_shape():
	randomize()
	var random_shape_index = randi() % len(SHAPES)
	while (last_shape_index == random_shape_index):
		randomize()
		random_shape_index = randi() % len(SHAPES)
	last_shape_index = random_shape_index
	return SHAPES[random_shape_index]

func random_color():
	randomize()
	var random_color_index = randi() % len(COLORS)
	while (last_color_index == random_color_index):
		randomize()
		random_color_index = randi() % len(COLORS)
	last_color_index = random_color_index
	return COLORS[random_color_index]

func random_start_active_piece():
	active_piece.i_position = 0
	randomize()
	active_piece.j_position = (randi() % (10 - active_piece.piece_width))

func active_piece_overlaps_squares():
	for i in range(len(active_piece.piece_shape)):
		for j in range(len(active_piece.piece_shape[i])):
			if active_piece.i_position + i >= 0:
				if grid[active_piece.i_position + i] \
					   [active_piece.j_position + j]:
					return true
	return false

func control_movement():
	if Input.is_action_just_pressed("ui_up"):
		if active_piece_can_rotate():
			active_piece.rotate_shape()
#			active_piece.j_position = clamp(active_piece.j_position, 0, 
#									width - active_piece.piece_width)
	if Input.is_action_just_pressed("ui_right"):
		if active_piece_right_free():
			active_piece.j_position += 1
	if Input.is_action_just_pressed("ui_left"):
		if active_piece_left_free():
			active_piece.j_position -= 1
	if Input.is_action_pressed("ui_down"):
		acceleration_frames_count += 1
		if (acceleration_frames_count % \
		   int(floor(Engine.get_iterations_per_second() / accelerated_speed))) == 0:
			update_active_piece()
			frames_count = 0
	if Input.is_action_just_released("ui_down"):
		acceleration_frames_count = 0
		
func active_piece_can_rotate():
	var possible_new_shape = active_piece.create_new_shape()
	for i in range(len(possible_new_shape)):
		for j in range(len(possible_new_shape[i])):
			if i + active_piece.i_position >= height or \
			   j + active_piece.j_position >= width or \
			   (possible_new_shape[i][j] and \
			   grid[i + active_piece.i_position][j + active_piece.j_position]):
				return false
	return true

func active_piece_right_free():
	# Check right border
	if active_piece.j_position + active_piece.piece_width == width:
		return false
	# Check right of piece is filled
	for i in range(len(active_piece.piece_shape)):
		var most_right_square_index = 0
		for j in range(len(active_piece.piece_shape[i])):
			if active_piece.piece_shape[i][j]:
				most_right_square_index = j
		if grid[active_piece.i_position + i] \
			   [active_piece.j_position + most_right_square_index + 1]:
			return false
		
	return true

func active_piece_left_free():
	# Check left border
	if active_piece.j_position == 0:
		return false
	# Check left of piece is filled
	for i in range(len(active_piece.piece_shape)):
		var most_left_square_index = 0
		for j in range(len(active_piece.piece_shape[i])):
			if active_piece.piece_shape[i][j]:
				most_left_square_index = j
				break
		if grid[active_piece.i_position + i] \
			   [active_piece.j_position + most_left_square_index - 1]:
			return false
		
	return true
	
func is_update_frame():
	if (frames_count % \
		   int(floor(Engine.get_iterations_per_second() / piece_speed))) == 0:
		return true
	return false
	
func update_active_piece():
	if !blocks_below(active_piece) :
		active_piece.i_position += 1
	else:
		fix_active_piece()
		create_new_piece()
	
func blocks_below(piece):
	# End of the world
	if piece.i_position + piece.piece_height + 1 > height:
		return true
		
	# Check collision with other pieces
	for j in range(len(piece.piece_shape[0])):
		var column_bottom_piece = 0
		for i in range(len(piece.piece_shape)):
			if piece.piece_shape[i][j]:
				column_bottom_piece = i
		# Check square below bottom piece square of the column
		if grid[piece.i_position + column_bottom_piece + 1] \
			   [piece.j_position + j]:
			return true
	
	return false
	
func fix_active_piece():
	if active_piece.i_position == 0:
		lose_game()
		return
	for i in range(len(active_piece.piece_shape)):
		for j in range(len(active_piece.piece_shape[i])):
			if active_piece.piece_shape[i][j]:
				grid[active_piece.i_position + i] \
					[active_piece.j_position + j] = 1
				
				# Add to colors grid
				var sprite = Sprite.new()
				sprite.texture = block_texture
				var square = Node2D.new()
				sprite.modulate = active_piece.piece_color
				square.add_child(sprite)
				sprite.centered = false
				square.position.x = (active_piece.j_position + j) * \
					pixel_size * 3 
				square.position.y = (active_piece.i_position + i) * \
					pixel_size * 3
				add_child(square)
				colors_grid[active_piece.i_position + i] \
						   [active_piece.j_position + j] = square
						
				active_piece.queue_free()
				
	disappear_rows_if_full()
	
func disappear_rows_if_full():
	var row_still_full = true
	while row_still_full:
		row_still_full = false
		var first_full_row_index = 0
		for i in range(len(grid)):
			var row_full = true
			for j in range(len(grid[i])):
				if grid[i][j] == 0:
					row_full = false
			if row_full:
				first_full_row_index = i
				row_still_full = true
				break
		
		if row_still_full:
			full_rows += 1
			for i in range(first_full_row_index):
				var i_reverse = first_full_row_index - i
				grid[i_reverse] = grid[i_reverse - 1].duplicate()
				for j in range(len(grid[i_reverse])):
					if colors_grid[i_reverse][j]:
						colors_grid[i_reverse][j].queue_free()
					if colors_grid[i_reverse - 1][j]:
						colors_grid[i_reverse][j] = colors_grid[i_reverse - 1] \
							[j].duplicate()
						add_child(colors_grid[i_reverse][j])
						colors_grid[i_reverse][j].position.y = i_reverse * \
							pixel_size * 3
						colors_grid[i_reverse][j].position.x = j * \
							pixel_size * 3
					else:
						colors_grid[i_reverse][j] = colors_grid[i_reverse - 1] \
							[j]
			
			var first_grid_row = []
			for j in range(len(grid[0])):
				first_grid_row.append(0)
			grid[0] = first_grid_row
			colors_grid[0] = first_grid_row.duplicate()

func lose_game():
	game_started = false
	emit_signal("lose_game")

func print_grid_and_active_piece():
	for i in range(len(grid)):
		var row_text = ""
		for j in range(len(grid[i])):
			if i >= active_piece.i_position and \
			   i < active_piece.i_position + active_piece.piece_height and \
			   j >= active_piece.j_position and \
			   j < active_piece.j_position + active_piece.piece_width and \
			   active_piece.piece_shape[i - active_piece.i_position] \
									   [j - active_piece.j_position]:
				row_text += (" 1")
			else:
				row_text += (" " + str(grid[i][j]))
		print(row_text)
	print("\n\n")
			
