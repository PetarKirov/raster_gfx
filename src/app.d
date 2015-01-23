import core.thread;
import std.datetime;
import std.stdio;

import primitives, raster_methods;
import frame_buf, frame_watch, sdl_gui;

@safe @property
Duration fps(long x) { return (1000 / x).msecs; }

alias DrawFunc = void function(FrameBuf img, SdlGui gui);

void main()
{
	uint w = 640, h = 480;
	uint ps = 3; // pixel size
	auto fw = FrameWatch();
	auto gui = new SdlGui(w, h, "Task 1");
	auto image = new FrameBuf(w, h, ps, ps);
	
	@trusted Fiber fiber(DrawFunc func, size_t fiberStackSize = 64 * 1024 * 1024)
	{
		return new Fiber({ func(image, gui); }, fiberStackSize);
	}

	@trusted void drawWithFiber(DrawFunc func, Duration frameTime)
	{
		gui.drawWithFiber(image, fiber(func), fw, frameTime);
	}

	@trusted void drawWithFunc(DrawFunc func, Duration frameTime)
	{
		gui.drawWithFunc(image, { func(image, gui); }, fw, frameTime);
	}

	fw.start();
	fw.throttleBack(500.msecs);

	//drawWithFunc(&drawFastStuff, 60.fps);
	drawWithFiber(&task4_var3, 0.msecs);

	gui.waitForExit();
}

void task1_var3(FrameBuf img, SdlGui gui)
{
	Line getLine()
	{
		return Line(gui.getLine("Click somewhere to set the starting point", "Click elsewhere to set the end point"), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Line line = getLine();
		img.drawBresenhamLine(line.start, line.end, Color.Orange);
		img.drawBresenhamLine!((img, color, point) =>
							   PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
							   point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
			(line.start, line.end, Color.CornflowerBlue);

		gui.draw(img);
	}
}

void task2_var3(FrameBuf img, SdlGui gui)
{
	Point getPoint(string msg)
	{
		return Point(gui.getPoint(msg), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Point center = getPoint("1: Click somewhere to set the center of the circle");
		Point end = getPoint("2: Click elsewhere to set the radius of the circle");
		int r = center.distanceTo(end);
		img.DrawBresenhamCircle(center, r, Color.CornflowerBlue);
		img.DrawBresenhamCircle!((img, color, point) =>
								 PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
								 point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
			(center, r, Color.CornflowerBlue);

		gui.draw(img);
	}
}

void task1_var2(FrameBuf img, SdlGui gui)
{
	Line getLine()
	{
		return Line(gui.getLine("Click somewhere to set the starting point", "Click elsewhere to set the end point"), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Line line = getLine();
		img.drawBresenhamLine(line.start, line.end, Color.Orange);
		img.drawBresenhamLine_FromEndToEnd(line.start, line.end, Color.Blue, Color.Pink);

		gui.draw(img);
	}
}

void task1_var2_no_overlay(FrameBuf img, SdlGui gui)
{
	Line getLine()
	{
		return Line(gui.getLine("1: Click somewhere to set the starting point", "2: Click elsewhere to set the end point"), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Line line = getLine();
		img.drawBresenhamLine(line.start, line.end, Color.Orange);

		gui.draw(img);

		line = getLine();
		img.drawBresenhamLine_FromEndToEnd(line.start, line.end, Color.Blue, Color.Pink);

		gui.draw(img);
	}
}

void task2_var2(FrameBuf img, SdlGui gui)
{
	Point getPoint(string msg)
	{
		return Point(gui.getPoint(msg), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Point center = getPoint("1: Click somewhere to set the center of the circle");
		Point end = getPoint("2: Click elsewhere to set the radius of the circle");
		int r = center.distanceTo(end);

		img.DrawBresenhamCircle(center, r, Color.CornflowerBlue);
		img.DrawMichenerCircle(center, r, Color.Brown);

		gui.draw(img);
	}
}

void task2_var2_no_overlay(FrameBuf img, SdlGui gui)
{
	Point getPoint(string msg)
	{
		return Point(gui.getPoint(msg), img.metrics);
	}

	while(!gui.isQuitRequested)
	{
		Point center = getPoint("1: Click somewhere to set the center of the Bresenham circle");
		Point end = getPoint("2: Click elsewhere to set the radius of the Bresenham circle");
		int r = center.distanceTo(end);
		img.DrawBresenhamCircle(center, r, Color.CornflowerBlue);

		gui.draw(img);

		center = getPoint("1: Click somewhere to set the center of the Michener circle");
		end = getPoint("2: Click elsewhere to set the radius of the Michener circle");
		r = center.distanceTo(end);
		img.DrawMichenerCircle(center, r, Color.Brown);

		gui.draw(img);
	}
}

void task3_var3(FrameBuf img, SdlGui gui)
{
	import std.string : format;

	Point getPoint(string msg)
	{
		return Point(gui.getPoint(msg), img.metrics);
	}

	// Get center and radius for 4 circles
	foreach (i; 0 .. 4)
	{
		Point center = getPoint(format("(%s/5)|(1/2) Click somewhere to set the center of the Bresenham circle", i + 1));
		Point end = getPoint(format("(%s/5)|(2/2) Click elsewhere to set the radius of the Bresenham circle", i + 1));
		img.DrawBresenhamCircle(center, center.distanceTo(end), Color.CornflowerBlue);

		gui.draw(img);
	}

	// Fill stuff till program quit
	while(!gui.isQuitRequested)
	{
		Point p = getPoint("(5/5)|(1/1) Click somewhere in the area between the circles to fill it");
		img.SimpleBoundryFill_4(p, Color.Yellow, Color.CornflowerBlue);

		gui.draw(img);
	}
}

void task4_var3(FrameBuf img, SdlGui gui)
{
	auto bounds = Rectangle(50, 50, 250, 250, img.metrics);
    img.DrawRectangle(bounds.min, bounds.max, Color.White);

	auto line = Line(50, 25, 250, 290, img.metrics);
    img.drawBresenhamLine(line, Color.White);

    img.CohenSuttherland(line, bounds, Color.Purple);

	gui.draw(img);
}

void task_fill_quadrangle(FrameBuf img, SdlGui gui)
{
	Point getPoint(string msg)
	{
		return Point(gui.getPoint(msg), img.metrics);
	}

	Point p1 = getPoint("Click somewhere to set the 1st vertex of the rectangle");
	Point p2 = getPoint("Click somewhere to set the 2nd vertex of the rectangle");
	img.drawBresenhamLine(p1, p2, Color.Blue);
	gui.draw(img);

	Point p3 = getPoint("Click somewhere to set the 3rd vertex of the rectangle");
	img.drawBresenhamLine(p2, p3, Color.Blue);
	gui.draw(img);

	Point p4 = getPoint("Click somewhere to set the 4th vertex of the rectangle");
	img.drawBresenhamLine(p3, p4, Color.Blue);
	gui.draw(img);
	
	img.drawBresenhamLine(p4, p1, Color.Blue);
	gui.draw(img);

	while(!gui.isQuitRequested)
	{
		Point centerFill = getPoint("Click somewhere inside the quadrangle to fill it");
		img.SimpleFloodFill_4(centerFill, Color.Red, Color.Black);
		gui.draw(img);
	}

	gui.setTitle("Done");
}

void drawFastStuff(FrameBuf img, SdlGui gui)
{
	//img.drawGradient();

	Point p1 = Point(50, 30, img.metrics);
	Point p2 = Point(620, 100, img.metrics);
	img.drawBresenhamLine(p1, p2, Color.Orange);

	p1 = Point(50, 40, img.metrics);
	p2 = Point(500, 200, img.metrics);
	img.drawBresenhamLine(p1, p2, Color.Orange);

	p1 = Point(50, 50, img.metrics);
	p2 = Point(400, 300, img.metrics);
	img.drawBresenhamLine(p1, p2, Color.Orange);

	p1 = Point(50, 60, img.metrics);
	p2 = Point(320, 450, img.metrics);
	img.drawBresenhamLine(p1, p2, Color.Orange);
	
	assert(img.metrics.pixelSize.x == img.metrics.pixelSize.y, "Pixels should be square");
	Point c = Point(150, 150, img.metrics);
	img.DrawBresenhamCircle(c, 100 / img.metrics.pixelSize.x, Color.CornflowerBlue);
}

void drawSlowStuff(FrameBuf img, SdlGui gui)
{
	Point p = Point(200, 300, img.metrics);
	img.SimpleFloodFill_4(p, Color.Yellow, Color.Black);
}
