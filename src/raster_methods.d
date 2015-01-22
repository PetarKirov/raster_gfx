module raster_methods;

import core.thread : Fiber;
import std.math : abs;

import frame_buf, primitives;

private @system:

void yieldIfOnFiber()
{
	if (Fiber.getThis())
		Fiber.yield();
}

void each(R, F)(R range, F func)
{
	foreach (elem; range)
		func(elem);
}

void PutPixel(FrameBuf img, Color color, Point p)
{
	if (img.metrics.screenSize.inRange(p))
		img[p.x, p.y] = color;
}

void PutPixel(FrameBuf img, uint x, uint y, Color color)
{
	PutPixel(img, color, Point(x, y));
}

public void PutPixels(FrameBuf img, Color color, Point[] points)
{
	foreach (p; points)
		img.PutPixel(p.x, p.y, color);
}

Color GetPixel(FrameBuf img, uint x, uint y)
{
	return img[x, y];
}

Color GetPixel(FrameBuf img, const ref Point p)
{
	return img.GetPixel(p.x, p.y);
}

void FourSymmetric(alias drawFunc = PutPixel)(FrameBuf img, Point c, Point d, Color color)
{
	drawFunc(img, color, Point(c.x + d.x, c.y + d.y));
	drawFunc(img, color, Point(c.x - d.x, c.y - d.y));
	drawFunc(img, color, Point(c.x - d.x, c.y + d.y));
	drawFunc(img, color, Point(c.x + d.x, c.y - d.y));
}

void EightSymmetric(alias drawFunc = PutPixel)(FrameBuf img, Point c, Point d, Color color)
{
	img.FourSymmetric!drawFunc(c, d, color);
	img.FourSymmetric!drawFunc(c, d.swap(), color);
}

public @trusted:

void DrawBresenhamCircle(alias drawFunc = PutPixel)(FrameBuf img, const ref Point c, uint R, Color color)
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

		Point p = Point(x, y);
		img.FourSymmetric!drawFunc(c, p, color);

		yieldIfOnFiber();
	}
}

void DrawMichenerCircle(FrameBuf img, const ref Point c, uint R, Color color)
{
	if (R == 0)
		return;

	const int xc = c.x;
	const int yc = c.y;

	int y = R;
	int d = 3 - 2 * R;

	img.EightSymmetric(Point(xc, yc), Point(0, R), color);
	foreach (x; 0 .. y)
	{
		yieldIfOnFiber();

		if (d >= 0)
			d += 10 + 4 * x -4 * (y--);
		else
			d += 6 + 4 * x;

		img.EightSymmetric(Point(xc, yc), Point(x, y), color);
	}
}

private alias Predicate = bool function(Color current, Color c1, Color c2);

import std.algorithm : map, equal, filter;
import std.array : array;

private void fill_impl(alias pred, alias drawFunc = PutPixels, Args...)
		(FrameBuf img, Point[] points, Color newC, Color otherC, Args funcs)
{
	Point center = points[0];

	auto remaining = points.filter!( x => img.metrics.screenSize.inRange(x) &&
					 pred(img.GetPixel(x), newC, otherC)).array;

	if (remaining.length == 0)
		return;

	drawFunc(img, newC, points);

	yieldIfOnFiber();

	foreach (func; funcs)
	{
		Point[] newP2;
		remaining.each((ref Point x) { newP2 ~= func(x); });

		img.fill_impl!pred(newP2, newC, otherC, funcs);
	}
}

void SimpleFloodFill_4(FrameBuf img, const ref Point p, Color newValue, Color oldValue)
{
	img.fill_impl!((curC, newC, innerC) => curC == innerC)
				  ([p], newValue, oldValue, &left, &right, &up, &down);
}

void SimpleFloodFill_8(FrameBuf img, const ref Point p, Color newValue, Color oldValue)
{
	auto points = [p, p.up(), p.down(), p.left(), p.right(),
		p.upLeft(), p.upRight(), p.downLeft(), p.downRight()];

	img.fill_impl!((curC, newC, innerC) => curC == innerC)
		(points, newValue, oldValue, &left, &right, &up, &down, &upLeft, &upRight, &downLeft, &downRight);
}

void SimpleBoundryFill_4(FrameBuf img, const ref Point p, Color newValue, Color borderValue)
{
	img.fill_impl!((curC, newC, borderC) => curC != newC && curC != borderC)
				  ([p], newValue, borderValue, &left, &right, &up, &down);
}

void drawBresenhamLine(alias drawFunc = PutPixel)(FrameBuf img, const ref Point p1, const ref Point p2, Color color)
{
	import std.math : abs;
	import std.algorithm : swap;

	int x1 = p1.x, y1 = p1.y;
	int x2 = p2.x, y2 = p2.y;

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
        if(reverse)
			drawFunc(img, color, Point(y, x));
        else
           drawFunc(img, color, Point(x, y));

		yieldIfOnFiber();

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

void drawBresenhamLine_FromEndToEnd(alias drawFunc = PutPixel)(FrameBuf img, const ref Point p1, const ref Point p2, Color color1, Color color2)
{
	import std.algorithm : swap;

	int x1 = p1.x, y1 = p1.y;
	int x2 = p2.x, y2 = p2.y;

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
			drawFunc(img, color1, Point(y, x));
			drawFunc(img, color2, Point(y_krai, x_krai));
        }
        else
        {
			drawFunc(img, color1, Point(x, y));
			drawFunc(img, color2, Point(x_krai, y_krai));
        }

		yieldIfOnFiber();

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

void drawGradient(FrameBuf img)
{
	foreach (y; 0 .. img.h)
		foreach (x; 0 .. img.w)
			img[x, y] =
				Color.Purple.gradient(Color.Orange, cast(float)x / img.w)
							.gradient(Color.Black, cast(float)y / img.h);
}
