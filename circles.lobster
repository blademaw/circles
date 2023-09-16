import vec
import color
import gl
import std

// set constants
let WINDOW_HEIGHT = 500
let WINDOW_WIDTH  = WINDOW_HEIGHT
let WINDOW_SIZE   = xy_f { WINDOW_WIDTH, WINDOW_HEIGHT }
let WORLDSIZE     = 2.75


// set circle stuff
class Circle:
    radius : float
    pos    : xy_f

let circle = Circle{ 1.0  , xy_0 }
let origin = Circle{ 0.025, xy_f { 0.45, -0.45 } }
var reassign_origin = false


// set line stuff
class MutPoint:
    x: float
    y: float

def get_line_points(t: float):
    // do the math
    let c = (origin.pos.y - origin.pos.x*tan(t))
    let p1 = MutPoint { 0.0, 0.0 }
    let p2 = MutPoint { 0.0, 0.0 }
    
    // account for when tan(theta) is undefined
    if t == 0.0 or t == -90.0:
        p1.x = origin.pos.x
        p2.x = origin.pos.x

        p1.y = sqrt(1-pow(p1.x,2.0))
        p2.y = -sqrt(1-pow(p2.x,2.0))
    else:
        let shared = sqrt(-4*pow(c,2.0) + 4*pow(tan(t),2.0) + 4)
        p1.x = (shared - 2*c*tan(t))/(2*(pow(tan(t),2.0) + 1))
        p2.x = (-shared - 2*c*tan(t))/(2*(pow(tan(t),2.0) + 1))

        p1.y = p1.x*tan(t) + c
        p2.y = p2.x*tan(t) + c

    return [xy_f {p1.x, p1.y}, xy_f {p2.x, p2.y}]
    

// detects if a point is in a circle
def sum_vec(v: xy_f) -> float: return v.x + v.y

def mouse_in_circle(mouse_pos: xy_f, c : Circle):
    let in_it = sqrt(sum_vec(pow(mouse_pos - c.pos, 2.0)))
    if in_it < c.radius:
        return true
    return false


// find angles, plot lines.
var n = 2
var total_r = 0.
var avg_r   = 0.
var time_since = 0.

def equidistant_points(num: int, start: float, stop: float) -> [float]:
    if num <= 1: return [start]
    let step = (stop - start) / (num - 1) // exclude endpoint
    return map(num) i: start + step*i


def equidistant_angles(num: int) -> [float]:
    return equidistant_points(num, 180/float(num), 180)


def circular_points(num: int):
    return map(equidistant_angles(num)) a: get_line_points(a)


def draw_lines(points):
    for(points) p:
        let p1 = p[0]
        let p2 = p[1]
        gl_color(color_red)
        gl_line(p1, p2, 0.01)


def sum_chord_distances(points):
    return sum(
        map(points) x : magnitude(x[0]-x[1])
    )

// start display
fatal(gl_window("untitled", WINDOW_WIDTH, WINDOW_HEIGHT))
check(gl_set_font_name("data/fonts/US101/US101.ttf") and gl_set_font_size(32), "cannot load gl font")

// graphics loop
while gl_frame():
    if gl_button("escape") or gl_button("q"): return
    if gl_button("r"): origin.pos = xy_0
    gl_clear(color_black)
    let scale = float(gl_window_size()) / WORLDSIZE


    // display text stuff
    gl_translate(float(gl_window_size()) * 0.05):
        let unit = min(floor((float(gl_window_size()) / xy_f { 25, 25 })))
        gl_set_font_size(unit)
        gl_text("n = {n}")
        gl_translate(xy_f {0, unit}):
            gl_text("r_sum = {float(round(total_r*100))/100}")
            gl_translate(xy_f {0, unit})
            gl_text("r_avg = {float(round(avg_r*10000))/10000}")
        gl_translate(xy_f {15*unit, 0}):
            gl_text("center: ({float(round(origin.pos.x*100))/100}, {(if origin.pos.x == 0: 1 else: -1)*float(round(origin.pos.y*100))/100})")

    // draw the rest from the center of the screen...
    gl_translate(float(gl_window_size()) / 2.0)

    // ...and at a size according to world size
    gl_scale(scale) 

    // draw lines
    let points = circular_points(n)
    total_r = sum_chord_distances(points)
    avg_r   = total_r/(2*n)
    draw_lines(points)
    if gl_button("="): n++
    if gl_button("-"): n = max(1, n-1)
    if gl_button("left"):
        if (gl_time() - time_since) > .1: 
            n = max(1,n-1)
            time_since = gl_time()
    if gl_button("right"):
        if (gl_time() - time_since) > .1: 
            n++
            time_since = gl_time()

    // draw circles
    gl_color(color_white)
    gl_translate(circle.pos):
        gl_open_circle(origin.radius, 20, 0.5) // always draw the true origin
    gl_translate(origin.pos):
        gl_circle(origin.radius, 20)

    gl_color(color_white)
    gl_translate(circle.pos):
        gl_open_circle(circle.radius, 100, 0.035)

    // let the user grab and reposition the origin
    if gl_button("mouse1") == 1 and mouse_in_circle(gl_local_mouse_pos(0), origin):
        reassign_origin = true
    elif gl_button("mouse1") > 1 and reassign_origin:
        if mouse_in_circle(gl_local_mouse_pos(0), circle):
            origin.pos = gl_local_mouse_pos(0)
    else:
        reassign_origin = false
