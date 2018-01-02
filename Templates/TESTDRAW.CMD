/* TESTDRAW.CMD */

'@echo off'
call RxFuncAdd 'VInit', 'VREXX', 'VINIT'
initcode = VInit()
if initcode = 'ERROR' then signal CLEANUP

signal on failure name CLEANUP
signal on halt name CLEANUP
signal on syntax name CLEANUP

/* set up marker types */

default      = 0
cross        = 1
plus         = 2
diamond      = 3
square       = 4
star6        = 5
star8        = 6
soliddiamond = 7
solidsquare  = 8
soliddot     = 9
circle       = 10

/* set up line types */

solid      = 0
dot        = 1
dash       = 2
dashdot    = 3
dotdot     = 4
longdash   = 5
dashdotdot = 6

/* set up fill types */

nofill    = 0
solidfill = 1
horz      = 2
vert      = 3
leftdiag  = 4
rightdiag = 5

/* create 2 windows for drawing some graphics */

win1.left   = 15
win1.bottom = 30
win1.right  = 55
win1.top    = 70
id1 = VOpenWindow('TESTDRAW.CMD Graphics Window 1', 'WHITE', win1)

win2.left   = 60
win2.bottom = 10
win2.right  = 95
win2.top    = 40
id2 = VOpenWindow('TESTDRAW.CMD Graphics Window 2', 'BLACK', win2)

/* draw a line graph in window 1 */

call VForeColor id1, 'BLACK'

x.1 = 100
y.1 = 600
x.2 = 400
y.2 = 600
call VDraw id1, 'LINE', x, y, 2         /* x axis */
x.1 = 100
y.1 = 600
x.2 = 100
y.2 = 900
call VDraw id1, 'LINE', x, y, 2         /* y axis */

a = -0.000222   /* construct a quadratic polynomial */
b = 0.861       /* Y = a*X*X + b*X + c */
c = 566

x.1 = 100
y.1 = a*100*100 + b*100 + c
do i = 2 to 5
   j = i - 1
   x.i = x.j + 75
   y.i = a * x.i * x.i + b * x.i + c
end

call VDrawParms id1, soliddiamond, dashdot, default
call VDraw id1, 'MARKER', x, y, 5
call VDraw id1, 'LINE', x, y, 5

/* draw a set of arcs in window 2 */

call VForeColor id2, 'YELLOW'

cx = 100
cy = 200
radius = 20
angle1 = 0
angle2 = 60

do i = 1 to 6
   call VArc id2, cx, cy, radius, angle1, angle2
   radius = radius + 20
   cx = cx + 150
   angle2 = angle2 + 60
end

/* draw a bar graph in window 1 */

call VDrawParms id1, default, default, default
x.1 = 550
y.1 = 600
x.2 = 950
y.2 = 600
call VDraw id1, 'LINE', x, y, 2         /* x axis */
x.1 = 550
y.1 = 600
x.2 = 550
y.2 = 900
call VDraw id1, 'LINE', x, y, 2         /* y axis */

px.1 = 600
py.1 = 600
px.2 = 600
py.2 = 650
px.3 = 650
py.3 = 650
px.4 = 650
py.4 = 600

call VForeColor id1, 'RED'
do i = 1 to 6
   /* draw bar with a new fill type */

   call VDrawParms id1, default, solid, i-1
   call VDraw id1, 'POLYGON', px, py, 4
   call VDraw id1, 'LINE', px, py, 4

   px.1 = px.1 + 50
   px.2 = px.1
   px.3 = px.3 + 50
   px.4 = px.3

   py.2 = py.2 + 45
   py.3 = py.2
end

/* draw some lines of different types in window 2 */

color.1 = 'WHITE'               /* set up color array */
color.2 = 'RED'
color.3 = 'GREEN'
color.4 = 'BLUE'
color.5 = 'CYAN'
color.6 = 'YELLOW'
color.7 = 'PINK'

x.1 = 200
y.1 = 950
x.2 = 800
y.2 = 950

do i = 1 to 7
   call VForeColor id2, color.i
   call VDrawParms id2, default, i-1, default
   call VDraw id2, 'LINE', x, y, 2

   y.1 = y.1 - 100
   y.2 = y.1
end

/* set up a spline in window 1, drawing the control points */
/* of the spline as markers, and labelling them with text  */

sx.1 = 350
sy.1 = 450
sx.2 = 700
sy.2 = 200
sx.3 = 200
sy.3 = 125
sx.4 = 650
sy.4 = 425

call VForeColor id1, 'BLUE'
call VDrawParms id1, soliddot, default, default
call VDraw id1, 'MARKER', sx, sy, 4
call VDraw id1, 'SPLINE', sx, sy, 4

call VForeColor id1, 'GREEN'
call VSetFont id1, 'HELVB', 12
call VSay id1, 300, 75, 'Spline Control Points'

/* put up a message box */

msg.0 = 1
msg.1 = 'Press OK to close the windows'
call VMsgBox 'TESTDRAW.CMD', msg, 1

call VCloseWindow id1
call VCloseWindow id2

/* end of CMD file */

CLEANUP:
   call VExit

exit
