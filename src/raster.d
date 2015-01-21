module raster;

import core.thread : Fiber;

import frame_buf, primitives;

void each(Range, F)(Range range, F func)
{
	foreach (elem; range)
		func(elem);
}

bool IsInRange(FrameBuf img, int x, int y)
{
	return (x >= 0 && x < img.w) &&
		(y >= 0 && y < img.h);
}

bool IsInRange(FrameBuf img, Point p)
{
	return img.IsInRange(p.x, p.y);
}

void PutPixel(FrameBuf img, int x, int y, Color color)
{
	img[x, y] = color;
}

void PutPixel(FrameBuf img, Point p, Color color)
{
	img.PutPixel(p.x, p.y, color);
}

Color GetPixel(FrameBuf img, int x, int y)
{
	return img[x, y];
}

Color GetPixel(FrameBuf img, Point p)
{
	return img.GetPixel(p.x, p.y);
}

void FourSymmetric(FrameBuf img, Point c, Point d, Color color)
{
	img.PutPixel(c.x + d.x, c.y + d.y, color);
	img.PutPixel(c.x - d.x, c.y - d.y, color);
	img.PutPixel(c.x - d.x, c.y + d.y, color);
	img.PutPixel(c.x + d.x, c.y - d.y, color);
}

void DrawBresenhamCircle(FrameBuf img, Point c, int R, Color color)
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
		img.FourSymmetric(c, Point(x, y), color);
		
		Fiber.yield();
	}
}

void SimpleFloodFill_4(FrameBuf img, Point p, Color newValue, Color oldValue)
{
	uint x = p.x;
	uint y = p.y;

	//import std.stdio;

	//write(x, " ", y, " ");

	if (!img.IsInRange(x, y))
		return;

	//write("pass ");

	auto currentVal = img.GetPixel(x,y);


	if (currentVal == oldValue)
	{
		img.PutPixel(x, y, newValue);

		Fiber.yield();

		img.SimpleFloodFill_4(Point(x-1, y), newValue, oldValue);
		img.SimpleFloodFill_4(Point(x+1, y), newValue, oldValue);
		img.SimpleFloodFill_4(Point(x, y-1), newValue, oldValue);
		img.SimpleFloodFill_4(Point(x, y+1), newValue, oldValue);
	}
	else
	{
		//writeln("nop");
	}
}

void SimpleBoundryFill_4(FrameBuf img, int x, int y, Color newValue, Color borderValue)
{
	Color value;

	//if ((value = GetPixel(x, y)) != newValue && value != borderValue)
	//{
	//    img.PutPixel (x, y, newValue);
	//
	//    Fiber.yield();
	//
	//    img.SimpleBoundryFill_4(x-1, y, newValue, borderValue);
	//    img.SimpleBoundryFill_4(x+1, y, newValue, borderValue);
	//    img.SimpleBoundryFill_4(x, y-1, newValue, borderValue);
	//    img.SimpleBoundryFill_4(x, y+1, newValue, borderValue);
	//}
}

void drawBresenhamLine(FrameBuf img, Point p1, Point p2, Color color)
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

		Fiber.yield();

		error -= dy;
		if(error < 0)
		{
			y += ystep;
			error += dx;
		}
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