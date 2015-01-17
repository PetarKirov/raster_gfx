module raster;

import core.thread : Fiber;

import ae.utils.graphics.image;
import color;

void each(Range, F)(Range range, F func)
{
	foreach (elem; range)
		func(elem);
}

bool IsInRange(Image!Color img, int x, int y)
{
	return (x >= 0 && x < img.w) &&
		(y >= 0 && y < img.h);
}

void PutPixel(Image!Color img, int x, int y, Color color)
{
	img[x, y] = color;
}

Color GetPixel(Image!Color img, int x, int y)
{
	return img[x, y];
}

void FourSymmetric(Image!Color img, int xc, int yc, int x, int y, Color color)
{
	img.PutPixel(xc + x, yc + y, color);
	img.PutPixel(xc - x, yc - y, color);
	img.PutPixel(xc - x, yc + y, color);
	img.PutPixel(xc + x, yc - y, color);
}

void DrawBresenhamCircle(Image!Color img, int xc, int yc, int R, Color color)
{
	int x = 0, y = R, d = 2 - 2*R;
	
	img.PutPixel(    xc,  yc + R, color);
	img.PutPixel(	 xc,  yc - R, color);
	img.PutPixel(xc + R,      yc, color);
	img.PutPixel(xc - R,      yc, color);
	
	while (true) {
		if (d > -y) { y--; d += 1 - 2 * y; }
		if (d <= x) { x++; d += 1 + 2 * x; }
		if (!y) return;
		img.FourSymmetric(xc, yc, x, y, color);
		
		Fiber.yield();
	}
}

void SimpleFloodFill_4(Image!Color img, int x, int y, Color newValue, Color oldValue)
{		
	if (!img.IsInRange(x, y))
		return;

	if (img.GetPixel (x,y) == oldValue)
	{
		img.PutPixel (x, y, newValue);

		Fiber.yield();

		img.SimpleFloodFill_4(x-1, y, newValue, oldValue);
		img.SimpleFloodFill_4(x+1, y, newValue, oldValue);
		img.SimpleFloodFill_4(x, y-1, newValue, oldValue);
		img.SimpleFloodFill_4(x, y+1, newValue, oldValue);
	}
}

void SimpleBoundryFill_4(Image!Color img, int x, int y, Color newValue, Color borderValue)
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

void drawBresenhamLine(Image!Color img, int x1, int y1, int x2, int y2, Color color)
{
	import std.math : abs;

	int dx = abs(x2 - x1),
		dy = abs(y2 - y1);
		
	bool reverse = dx < dy;
	if (reverse)
	{
		//d = X1;
		//X1 = Y1;
		//Y1 = d;
		//
		//d = X2;
		//X2 = Y2;
		//Y2 = d;
		//
		//d = dx;
		//dx = dy;
		//dy = d;
	}
	
	int incUp = 2 * dx + 2 * dy;
	int incDown = 2 * dy;	
		
	int incX = (x1 <= x2)? 1 : -1;
	int incY = (y1 <= y2)? 1 : -1;
	
	int d = -dx + 2 * dy;
	int x = x1, y = y1, n = dx + 1;
	
	while (n--)
	{
		Fiber.yield();

		if (reverse)
			img[y, x] = color;
		else
			img[x, y] = color;
		
		x += incX;
		
		if (d > 0)
		{
			d += incUp; y += incY;
		}
		else
			d += incDown;
	}
}



void drawGradient(Image!Color img)
{
	foreach (y; 0 .. img.h)
		foreach (x; 0 .. img.w)
			img[x, y] =
				Color.Purple.gradient(Color.Orange, cast(float)x / img.w)
							.gradient(Color.Black, cast(float)y / img.h);
}