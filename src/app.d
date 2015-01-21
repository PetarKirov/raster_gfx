import core.thread;
import std.datetime;
import std.stdio;

import primitives, frame_buf, sdl2gui, raster;

struct FrameWatch
{
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

void main()
{
	uint w = 640, h = 480;
	uint ps = 3; // pixel size
	auto gui = SDL2Gui(w, h, "Task 1");

	FrameBuf image = void;

	if (ps > 1)
		image = FrameBuf(w / ps, h / ps, ps, ps);
	else if (ps == 1)
		image = FrameBuf(w, h);
	
	auto fw = FrameWatch();
	fw.start();
	fw.throttleBack(500.msecs);

	void draw(Fiber drawFiber, Duration wantedFrameTime)
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

	auto fiberStackSize = 64 * 1024 * 1024;

	draw(new Fiber({ image.drawFastStuff(); }, fiberStackSize),
		 16.msecs);

	draw(new Fiber({ image.drawSlowStuff(); }, fiberStackSize),
		 0.msecs);
	
	gui.waitForExit();
}

void drawFastStuff(FrameBuf img)
{
	auto ps = img.pixelSize;

	img.drawGradient();
	
	img.drawBresenhamLine(Point(50, 30, ps), Point(320, 100, ps), Color.Orange);
	img.drawBresenhamLine(Point(50, 40, ps), Point(620, 200, ps), Color.Purple);
	img.drawBresenhamLine(Point(50, 50, ps), Point(500, 300, ps), Color.Orange);
	img.drawBresenhamLine(Point(50, 50, ps), Point(400, 400, ps), Color.White);
	img.drawBresenhamLine(Point(50, 60, ps), Point(320, 450, ps), Color.Pink);
	
	assert(ps.x == ps.y, "Pixels should be square");
	img.DrawBresenhamCircle(Point(150, 150, ps), 100 / ps.x, Color.CornflowerBlue);
	
}

void drawSlowStuff(FrameBuf img)
{
	auto ps = img.pixelSize;
	img.SimpleFloodFill_4(Point(200, 300, ps), Color.Yellow, Color.Black);
}

