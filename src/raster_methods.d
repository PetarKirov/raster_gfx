module raster_methods;

import core.thread : Fiber;
import std.math : abs;

import frame_buf, primitives;

private @system:

private void yieldIfOnFiber()
{
	if (Fiber.getThis())
		Fiber.yield();
}

private void each(R, F)(R range, F func)
{
	foreach (elem; range)
		func(elem);
}

private void PutPixel(FrameBuf img, Color color, ScreenPoint p)
{
	img.PutPixel(color, Point2(p.x, p.y));
}

private void PutPixel(FrameBuf img, Color color, Point2 p)
{
	if (img.metrics.inRange(p))
		img[p.x, p.y] = color;

	yieldIfOnFiber();
}

private void PutPixel(FrameBuf img, uint x, uint y, Color color)
{
	if (img.metrics.inRange(x, y))
		img[x, y] = color;

	yieldIfOnFiber();
}

private void PutPixels(FrameBuf img, Color color, Point2[] points)
{
	foreach (p; points)
		img.PutPixel(p.x, p.y, color);

	yieldIfOnFiber();
}

private Color GetPixel(FrameBuf img, uint x, uint y)
{
	return img[x, y];
}

private Color GetPixel(FrameBuf img, Point2 p)
{
	return img.GetPixel(p.x, p.y);
}

private void FourSymmetric(alias drawFunc = PutPixel)(FrameBuf img, Point2 c, Point2 d, Color color)
{
	drawFunc(img, color, Point2(c.x + d.x, c.y + d.y));
	drawFunc(img, color, Point2(c.x - d.x, c.y - d.y));
	drawFunc(img, color, Point2(c.x - d.x, c.y + d.y));
	drawFunc(img, color, Point2(c.x + d.x, c.y - d.y));
}

private void EightSymmetric(alias drawFunc = PutPixel)(FrameBuf img, Point2 c, Point2 d, Color color)
{
	img.FourSymmetric!drawFunc(c, d, color);
	img.FourSymmetric!drawFunc(c, d.swap(), color);
}

public @trusted:

void drawBresenhamCircleTick(FrameBuf img, ScreenPoint c, uint r, Color color)
{
	img.drawBresenhamCircle!((ref img, color, point) =>
	                         PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
		point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
		(c, r, Color.CornflowerBlue);
}

void drawBresenhamCircle(alias drawFunc = PutPixel)(FrameBuf img, ScreenPoint c, uint R, Color color)
{
	if (R == 0)
		return;

	int x = 0, y = R, d = 2 - 2*R;

	img.PutPixel(    c.x,  c.y + R, color);
	img.PutPixel(	 c.x,  c.y - R, color);
	img.PutPixel(c.x + R,      c.y, color);
	img.PutPixel(c.x - R,      c.y, color);

	while (true) {
		if (d > -y) { y--; d += 1 - 2 * y; }
		if (d <= x) { x++; d += 1 + 2 * x; }
		if (!y) return;

		auto p = Point2(x, y);
		
		img.FourSymmetric!drawFunc(c, p, color);
	}
}

void drawMichenerCircle(FrameBuf img, ScreenPoint c, uint R, Color color)
{
	if (R == 0)
		return;

	int xc = c.x, yc = c.y;
	int y = R;
	int d = 3 - 2 * R;

	img.EightSymmetric(Point2(xc, yc), Point2(0, R), color);
	foreach (x; 0 .. y)
	{
		if (d >= 0)
			d += 10 + 4 * x -4 * (y--);
		else
			d += 6 + 4 * x;

		img.EightSymmetric(c, Point2(x, y), color);
	}
}

private alias Predicate = bool function(Color current, Color c1, Color c2);

import std.algorithm : map, equal, filter;
import std.array : array;

private void fill_impl(alias pred, alias drawFunc = PutPixels, Args...)
		(FrameBuf img, Point2[] points, Color newC, Color otherC, Args funcs)
{
	auto center = points[0];

	auto remaining = points.filter!(x =>
			img.metrics.inRange(x) && pred(img.GetPixel(x), newC, otherC));

	if (remaining.empty)
		return;

	drawFunc(img, newC, points);

	foreach (func; funcs)
	{
		Point2[] newP2;
		foreach (x; remaining)
		{
			newP2 ~= func(x);
		}

		img.fill_impl!pred(newP2, newC, otherC, funcs);
	}
}

void SimpleFloodFill_4(FrameBuf img, ScreenPoint p, Color newValue, Color oldValue)
{
	img.fill_impl!((curC, newC, innerC) => curC == innerC)
				  ([p], newValue, oldValue, &left, &right, &up, &down);
}

void SimpleFloodFill_8(FrameBuf img, ScreenPoint p, Color newValue, Color oldValue)
{
	auto points = [p, p.up(), p.down(), p.left(), p.right(),
		p.upLeft(), p.upRight(), p.downLeft(), p.downRight()];

	img.fill_impl!((curC, newC, innerC) => curC == innerC)
		(points, newValue, oldValue, &left, &right, &up, &down, &upLeft, &upRight, &downLeft, &downRight);
}

void SimpleBoundryFill_4(FrameBuf img, ScreenPoint p, Color newValue, Color borderValue)
{
	img.fill_impl!((curC, newC, borderC) => curC != newC && curC != borderC)
				  ([p], newValue, borderValue, &left, &right, &up, &down);
}

void drawBresenhamLineTick(FrameBuf img, ScreenLine line, Color color)
{
	img.drawBresenhamLine!((ref img, color, Point2 point) =>
	                       PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
		point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
		(line, Color.CornflowerBlue);
}

void drawBresenhamLine(alias drawFunc = PutPixel)(FrameBuf img, ScreenLine l, Color color)
{
	img.drawBresenhamLine!drawFunc(Line2(Point2(l.x1, l.y1), Point2(l.x2, l.y2)), color);
}

private void drawBresenhamLine(alias drawFunc = PutPixel)(FrameBuf img, Line2 l, Color color)
{
	import std.math : abs;
	import std.algorithm : swap;
	
	int x1 = l.x1, y1 = l.y1;
	int x2 = l.x2, y2 = l.y2;
	
	int dx = abs(x2 - x1);
	int dy = abs(y2 - y1);
	
	bool reverse = dx < dy;
	
	if (reverse)
	{
		swap(x1, y1);
		swap(x2, y2);
		swap(dx, dy);
	}
	int incUP = -2 * dx +2 * dy;
	int incDN = 2 * dy;
	
	int incX = (x1 <= x2)? 1 : -1;
	int incY = (y1 <= y2)? 1 : -1;
	int d = -dx + 2 * dy;
	int x = x1;
	int y = y1;
	int n = dx + 1;
	while (n--)
	{		
		if (reverse)
			drawFunc(img, color, Point2(y, x));
		else
			drawFunc(img, color, Point2(x, y));
		
		x += incX;
		if (d > 0)
		{
			d += incUP;
			y += incY;
		}
		else
			d += incDN;
	}
}

void drawBresenhamLine_FromEndToEnd(alias drawFunc = PutPixel)(FrameBuf img, ScreenLine l, Color color1, Color color2)
{
	import std.algorithm : swap;

	int x1 = l.x1, y1 = l.y1;
	int x2 = l.x2, y2 = l.y2;

    int dx = abs(x2 - x1);
    int dy = abs(y2 - y1);

	bool reverse = dx < dy;

    if (reverse)
    {
		swap(x1, y1);
		swap(x2, y2);
		swap(dx, dy);
    }

    int incUP = -2 * dx +2 * dy;
    int incDN = 2 * dy;

    int incX = (x1 <= x2) ? 1 : -1;
    int incY = (y1 <= y2) ? 1 : -1;
    int d = -dx + 2 * dy;
    int x = x1;
    int y = y1;
    int n = (dx + 1)/2;
    int x_krai = x2;
    int y_krai = y2;

    while (n--)
    {
        if (reverse)
        {
			drawFunc(img, color1, Point2(y, x));
			drawFunc(img, color2, Point2(y_krai, x_krai));
        }
        else
        {
			drawFunc(img, color1, Point2(x, y));
			drawFunc(img, color2, Point2(x_krai, y_krai));
        }

        x += incX;
        x_krai -= incX;

        if (d > 0)
        {
            d += incUP;
            y += incY;
            y_krai -= incY;
        }
        else
            d += incDN;
    }

}

enum { TOP = 0x1, BOTTOM = 0x2, RIGHT = 0x4, LEFT = 0x8 }

alias Outcode = int;

Outcode ComputeOutcode(int x, int y, int xmin, int ymin, int xmax, int ymax)
{
    Outcode oc = 0;
    if (y > ymax)
        oc |= TOP;
    else if (y < ymin)
        oc |= BOTTOM;
    if (x > xmax)
        oc |= RIGHT;
    else if (x < xmin)
        oc |= LEFT;
    return oc;
}

void CohenSuttherland(FrameBuf img, ScreenLine l, ScreenRectangle boundingBox, Color color)
{
	int x1 = l.start.x, y1 = l.start.y;
	int x2 =   l.end.x,	y2 =   l.end.y;

	int xmin = boundingBox.min.x, ymin = boundingBox.min.y;
	int xmax = boundingBox.max.x, ymax = boundingBox.max.y;

    int accept = false;
    bool done = false;

    Outcode outcode1 = ComputeOutcode(x1, y1, xmin, ymin, xmax, ymax);
    Outcode outcode2 = ComputeOutcode(x2, y2, xmin, ymin, xmax, ymax);

    do
    {
        if (outcode1 == 0 && outcode2 == 0)
        {
            accept = true;
            done = true;
        }
        else if (outcode1 & outcode2)
        {
            done = true;
        }
        else
        {
            int x, y;
            Outcode outcode_ex = outcode1 ? outcode1 : outcode2;
            if (outcode_ex & TOP)
            {
                x = x1 + (x2 - x1) * (ymax - y1) / (y2 - y1);
                y = ymax;
            }

            else if (outcode_ex & BOTTOM)
            {
                x = x1 + (x2 - x1) * (ymin - y1) / (y2 - y1);
                y = ymin;
            }
            else if (outcode_ex & RIGHT)
            {
                y = y1 + (y2 - y1) * (xmax - x1) / (x2 - x1);
                x = xmax;
            }
            else
            {
                y = y1 + (y2 - y1) * (xmin - x1) / (x2 - x1);
                x = xmin;
            }
            if (outcode_ex == outcode1)
            {
                x1 = x;
                y1 = y;
                outcode1 = ComputeOutcode(x1, y1, xmin, ymin, xmax, ymax);
            }
            else
            {
                x2 = x;
                y2 = y;
                outcode2 = ComputeOutcode(x2, y2, xmin, ymin, xmax, ymax);
            }
        }
    } while (!done);

    if (accept == true)
	{
        img.drawBresenhamLine(Line2(Point2(x1, y1), Point2(x2, y2)), color);
	}
}

void drawRectangle(FrameBuf img, ScreenRectangle rect, Color color)
{
	auto v1 = Line2(Point2(rect.min.x, rect.min.y), Point2(rect.min.x, rect.max.y));
	auto v2 = Line2(Point2(rect.max.x, rect.min.y), Point2(rect.max.x, rect.max.y));
	auto h1 = Line2(Point2(rect.min.x, rect.min.y), Point2(rect.max.x, rect.min.y));
	auto h2 = Line2(Point2(rect.min.x, rect.max.y), Point2(rect.max.x, rect.max.y));
	
	img.drawBresenhamLine(v1, color);	
	img.drawBresenhamLine(v2, color);	
	img.drawBresenhamLine(h1, color);	
	img.drawBresenhamLine(h2, color);
}

void drawRectangle(FrameBuf img, ScreenPoint p1, ScreenPoint p2, Color color)
{
	auto rect = ScreenRectangle(p1, p2);
	img.drawRectangle(rect, color);
}

void drawGradient(FrameBuf img)
{
	foreach (y; 0 .. img.h)
		foreach (x; 0 .. img.w)
			img[x, y] =
				Color.Purple.gradient(Color.Orange, cast(float)x / img.w)
							.gradient(Color.Black, cast(float)y / img.h);
}
