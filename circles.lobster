import vec
import imgui
import color
import gl
import std

// set constants
let WINDOW_HEIGHT = 250
let WINDOW_WIDTH  = WINDOW_HEIGHT
let WINDOW_SIZE   = float2 { WINDOW_WIDTH, WINDOW_HEIGHT }
let WORLDSIZE     = 2.75

// set circle stuff
class Circle:
    radius : float
    pos    : float2

let circle = Circle{ 1.0  , float2_0 }
let origin = Circle{ 0.025, float2 { 0.3, -0.37 } }
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

    return [float2 {p1.x, p1.y}, float2 {p2.x, p2.y}]
    

// detects if a point is in a circle
def sum_vec(v: float2) -> float: return v.x + v.y

def mouse_in_circle(mouse_pos: float2, c : Circle):
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
        gl.color(color_red)
        gl.line(p1, p2, 0.01)


def sum_chord_distances(points):
    return sum(
        map(points) x : magnitude(x[0]-x[1])
    )

// start display
fatal(gl.window("untitled", WINDOW_WIDTH, WINDOW_HEIGHT))
check(gl.set_font_name("data/fonts/US101/US101.ttf") and gl.set_font_size(32), "cannot load gl font")

// graphics loop
while gl.frame():
    if gl.button("escape") or gl.button("q"): return
    if gl.button("r"): origin.pos = float2_0
    gl.clear(color_black)
    let scale = float(gl.window_size()) / WORLDSIZE


    // display text stuff
    gl.translate(float(gl.window_size()) * 0.05):
        let unit = min(floor((float(gl.window_size()) / float2 { 25, 25 })))
        gl.set_font_size(unit)
        gl.text("n = {n}")
        gl.translate(float2 {0, unit}):
            gl.text("r_sum = {float(round(total_r*100))/100}")
            gl.translate(float2 {0, unit})
            gl.text("r_avg = {float(round(avg_r*10000))/10000}")
            gl.translate(float2 {0, unit})
            gl.text("d_avg = {float(round(avg_r*2*10000))/10000}")
            gl.translate(float2 {0, unit})
            // gl.text("approx= {float(round(sqrt(-2.*(pow(origin.pos.x,2.) + pow(origin.pos.y,2.) - 2.))*10000))/10000}")
            gl.text("approx= {float(round(sqrt((-2.*(pow(origin.pos.x,2.) + pow(origin.pos.y,2) - 2.))/n)*10000))/10000}")
        gl.translate(float2 {15*unit, 0}):
            gl.text("center: ({float(round(origin.pos.x*100))/100}, {(if origin.pos.x == 0: 1 else: -1)*float(round(origin.pos.y*100))/100})")

    // draw the rest from the center of the screen...
    gl.translate(float(gl.window_size()) / 2.0)

    // ...and at a size according to world size
    gl.scale(scale) 

    // draw lines
    let points = circular_points(n)
    total_r = sum_chord_distances(points)
    avg_r   = total_r/(2*n)
    draw_lines(points)
    if gl.button("="): n++
    if gl.button("-"): n = max(1, n-1)
    if gl.button("left"):
        if (gl.time() - time_since) > .1: 
            n = max(1,n-1)
            time_since = gl.time()
    if gl.button("right"):
        if (gl.time() - time_since) > .1: 
            n++
            time_since = gl.time()

    // draw circles
    gl.color(color_white)
    gl.translate(circle.pos):
        gl.open_circle(origin.radius, 20, 0.5) // always draw the true origin
    gl.translate(origin.pos):
        gl.circle(origin.radius, 20)

    gl.color(color_white)
    gl.translate(circle.pos):
        gl.open_circle(circle.radius, 100, 0.035)

    // let the user grab and reposition the origin
    if gl.button("mouse1") == 1 and mouse_in_circle(gl.local_mouse_pos(0), origin):
        reassign_origin = true
    elif gl.button("mouse1") > 1 and reassign_origin:
        if mouse_in_circle(gl.local_mouse_pos(0), circle):
            origin.pos = gl.local_mouse_pos(0)
    else:
        reassign_origin = false
