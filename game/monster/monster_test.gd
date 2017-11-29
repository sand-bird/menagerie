extends KinematicBody2D

var speed = 10
var target = Vector2(50, 50)
var velocity = Vector2(0, 0)

func _ready():
	set_fixed_process(true)
	move_to(target)
	pass
	
func _fixed_process(delta):
    #move towards target destination
    move(velocity*delta)
   
    #once target destination is reached
    if(get_pos().distance_to(target) <= 20):
        #calculate new destination
        target.x = rand_range(xMin, xMax)       #set new random target destination
        target.y = rand_range(yMin, yMax)
        var angle = get_angle_to(target)        #calc angle to target
        velocity.x = speed*sin(angle)           #convert linear speed into x and y components
        velocity.y = speed*cos(angle)