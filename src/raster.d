module raster;

import core.thread : Fiber;
import std.algorithm : swap;
import std.math : abs;

import frame_buf, primitives;

@trusted:

void yieldIfOnFiber()
{
	if (Fiber.getThis())
		Fiber.yield();
}

void each(Range, F)(Range range, F func)
{
	foreach (elem; range)
		func(elem);
}

void PutPixel(FrameBuf img, Point p, Color color)
{
	if (img.metrics.screenSize.inRange(p))
		img[p.x, p.y] = color;
}

@trusted void PutPixel(FrameBuf img, uint x, uint y, Color color)
{
	PutPixel(img, Point(x, y), color);
}

Color GetPixel(FrameBuf img, uint x, uint y)
{
	return img[x, y];
}

Color GetPixel(FrameBuf img, const ref Point p)
{
	return img.GetPixel(p.x, p.y);
}

private void FourSymmetric(FrameBuf img, Point c, Point d, Color color)
{
	img.PutPixel(c.x + d.x, c.y + d.y, color);
	img.PutPixel(c.x - d.x, c.y - d.y, color);
	img.PutPixel(c.x - d.x, c.y + d.y, color);
	img.PutPixel(c.x + d.x, c.y - d.y, color);
}

private void EightSymmetric(FrameBuf img, Point c, Point d, Color color)
{
	img.FourSymmetric(c, d, color);
	img.FourSymmetric(c, d.swap(), color);
}

void DrawBresenhamCircle(FrameBuf img, const ref Point c, uint R, Color color)
{
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
		img.FourSymmetric(c, p, color);
		
		yieldIfOnFiber();
	}
}

void DrawMichenerCircle(FrameBuf img, const ref Point c, uint R, Color color)
{
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


alias Predicate = bool function(Color current, Color c1, Color c2);

private void fill_impl(FrameBuf img, Point p, Color newC, Color otherC, Predicate func)
{
	if (!img.metrics.screenSize.inRange(p))
		return;

	auto currentC = img.GetPixel(p);

	if (func(currentC, newC, otherC))
	{
		img.PutPixel(p, newC);

		yieldIfOnFiber();

		img.fill_impl(p.left(), newC, otherC, func);
		img.fill_impl(p.right(), newC, otherC, func);
		img.fill_impl(p.up(), newC, otherC, func);
		img.fill_impl(p.down(), newC, otherC, func);
	}
}


void SimpleFloodFill_4(FrameBuf img, const ref Point p, Color newValue, Color oldValue)
{
	img.fill_impl(p, newValue, oldValue,
				  (curC, oldC, newC) => curC != oldC);
}

void SimpleBoundryFill_4(FrameBuf img, const ref Point p, Color newValue, Color borderValue)
{
	img.fill_impl(p, newValue, borderValue,
		(curC, newC, borderC) =>
			curC != newC && curC != borderC);
}

void drawBresenhamLine(FrameBuf img, const ref Point p1, const ref Point p2, Color color)
{
	import std.math : abs;
	import std.algorithm : swap;

	int x1 = p1.x, y1 = p1.y;
	int x2 = p2.x, y2 = p2.y;

	// Bresenham's line algorithm
	const bool steep = (abs(y2 - y1) > abs(x2 - x1));
	if(steep)
	{
		swap(x1, y1);
		swap(x2, y2);
	}

	if(x1 > x2)
	{
		swap(x1, x2);
		swap(y1, y2);
	}

	const float dx = x2 - x1;
	const float dy = abs(y2 - y1);

	float error = dx / 2.0f;
	const int ystep = (y1 < y2) ? 1 : -1;
	int y = y1;

	const int maxX = x2;

	for(int x = x1; x < maxX; x++)
	{
		if(steep)
		{
			img.PutPixel(y, x, color);
		}
		else
		{
			img.PutPixel(x, y, color);
		}

		yieldIfOnFiber();

		error -= dy;
		if(error < 0)
		{
			y += ystep;
			error += dx;
		}
	}
}

void drawBresenhamLine_FromEndToEnd(FrameBuf img, const ref Point p1, const ref Point p2, Color color1, Color color2)
{
   // int x , y , dx, dy, incX, incY, d,  incUP , incDN, n , reverse, x_krai,y_krai;

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
            img.PutPixel(y ,x, color1);
            img.PutPixel(y_krai, x_krai, color2);
        }
        else
        {
			img.PutPixel(x, y, color1);
			img.PutPixel(x_krai, y_krai, color2);
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