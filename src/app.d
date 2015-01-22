import core.thread;
import std.datetime;
import std.stdio;

import primitives, frame_buf, sdl_gui, raster;

struct FrameWatch
{
	@trusted:

	private StopWatch sw;

	void start() { sw.start(); }

	void throttleBack(Duration frameTime)
	{
		auto timeLeft = frameTime - sw.peek();
		sw.reset();

		if (timeLeft > 1.msecs)
			Thread.sleep(timeLeft);
	}
}

@safe @property
Duration fps(long x) { return (1000 / x).msecs; }

void main()
{
	uint w = 640, h = 480;
	uint ps = 3; // pixel size
	auto gui = new SdlGui(w, h, "Task 1");

	FrameBuf image;

	if (ps > 1)
		image = new FrameBuf(w / ps, h / ps, ps, ps);
	else if (ps == 1)
		image = new FrameBuf(w, h);
	
	auto fw = FrameWatch();
	fw.start();
	fw.throttleBack(500.msecs);

	@trusted void drawWithFiber(Fiber drawFiber, Duration wantedFrameTime)
	{
		while(!gui.isQuitRequested && drawFiber.state != Fiber.State.TERM)
		{
			drawFiber.call();
			gui.draw(image);
			gui.processEvents();

			if (wantedFrameTime > 1.msecs)
				fw.throttleBack(wantedFrameTime);
		}
	}

	@trusted void drawWithFunc(void delegate() drawFunc, Duration wantedFrameTime)
	{
		while(!gui.isQuitRequested)
		{
			drawFunc();
			gui.draw(image);
			gui.processEvents();

			if (wantedFrameTime > 1.msecs)
				fw.throttleBack(wantedFrameTime);
		}
	}

	@trusted Fiber fiber(void function(FrameBuf, SdlGui) func, size_t fiberStackSize = 64 * 1024 * 1024)
	{
		return new Fiber({ func(image, gui); }, fiberStackSize);
	}

	//drawWithFiber(fiber(&drawFastStuff), 60.fps);
	//
	//drawWithFiber(fiber(&drawSlowStuff), 0.msecs);

	drawWithFiber(fiber(&task_rect), 60.fps);

	gui.waitForExit();
}

void task1_var2(FrameBuf img, SdlGui gui)
{
	Line line;

	while(true)
	{
		line = Line(gui.getLine(), img.metrics);
		img.drawBresenhamLine(line.start, line.end, Color.Orange);

		//line = Line(gui.getLine(), img.metrics);
		img.drawBresenhamLine_FromEndToEnd(line.start, line.end, Color.Blue, Color.Pink);
	}
}

void task2_var2(FrameBuf img, SdlGui gui)
{
	while(true)
	{
		Point center = Point(gui.getPoint(), img.metrics);
		Point end = Point(gui.getPoint(), img.metrics);
		int r = center.distanceTo(end);

		img.DrawBresenhamCircle(center, r, Color.CornflowerBlue);
		img.DrawMichenerCircle(center, r, Color.Brown);
	}
}

void task2_var2_no_overlay(FrameBuf img, SdlGui gui)
{
	while(true)
	{
		Point center = Point(gui.getPoint(), img.metrics);
		Point end = Point(gui.getPoint(), img.metrics);
		int r = center.distanceTo(end);
		img.DrawBresenhamCircle(center, r, Color.CornflowerBlue);

		center = Point(gui.getPoint(), img.metrics);
		end = Point(gui.getPoint(), img.metrics);
		r = center.distanceTo(end);
		img.DrawMichenerCircle(center, r, Color.Brown);
	}
}

@trusted Line findCloseLine(FrameBuf img, Line l)
{
	return l;
}

void task3_var3(FrameBuf img, SdlGui gui)
{
	// Get center and radius for 4 circles
	foreach (_; 0 .. 4)
	{
		Line radius = Line(gui.getLine(), img.metrics);

		img.DrawBresenhamCircle(radius.start, radius.start.distanceTo(radius.end), Color.CornflowerBlue);
	}

	while (true)
	{
		Point p = Point(gui.getPoint(), img.metrics);

		img.SimpleBoundryFill_4(p, Color.Yellow, Color.CornflowerBlue);
	}
}

void task_rect(FrameBuf img, SdlGui gui)
{
	Point p1 = Point(gui.getPoint(), img.metrics);
	Point p2 = Point(gui.getPoint(), img.metrics);
	img.drawBresenhamLine(p1, p2, Color.Blue);

	Point p3 = Point(gui.getPoint(), img.metrics);
	img.drawBresenhamLine(p2, p3, Color.Blue);

	Point p4 = Point(gui.getPoint(), img.metrics);
	img.drawBresenhamLine(p3, p4, Color.Blue);
	
	img.drawBresenhamLine(p4, p1, Color.Blue);

	Point centerFill = Point(gui.getPoint(), img.metrics);
	img.SimpleBoundryFill_4(centerFill, Color.Red, Color.Blue);
}


void drawFastStuff(FrameBuf img, SdlGui gui) @safe
{
	//img.drawGradient();
	
	//img.drawBresenhamLine(Point(50, 30, img.metrics), Point(320, 100, img.metrics), Color.Orange);
	//img.drawBresenhamLine(Point(50, 40, img.metrics), Point(620, 200, img.metrics), Color.Purple);
	//img.drawBresenhamLine(Point(50, 50, img.metrics), Point(500, 300, img.metrics), Color.Orange);
	//img.drawBresenhamLine(Point(50, 50, img.metrics), Point(400, 400, img.metrics), Color.White);
	//img.drawBresenhamLine(Point(50, 60, img.metrics), Point(320, 450, img.metrics), Color.Pink);
	
	assert(img.metrics.pixelSize.x == img.metrics.pixelSize.y, "Pixels should be square");
	//img.DrawBresenhamCircle(Point(150, 150, img.metrics), 100 / img.metrics.pixelSize.x, Color.CornflowerBlue);
}

void drawSlowStuff(FrameBuf img, SdlGui gui) @safe
{
	//img.SimpleFloodFill_4(Point(200, 300, img.metrics), Color.Yellow, Color.Black);
}

