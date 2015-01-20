import core.thread;
import std.datetime;
import std.stdio;

import frame_buf, sdl2gui, raster;

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
	
	auto fiberStackSize = 64 * 1024 * 1024;
	auto animationFiber = new Fiber({ image.drawStuff(ps); }, fiberStackSize);
	
	auto fw = FrameWatch();
	fw.start();
	fw.throttleBack(500.msecs);
	
	// Animation loop
	while(!gui.isQuitRequested)
	{	
		animationFiber.call();
		
		if (animationFiber.state == Fiber.State.TERM)
		    break;

		//image.drawStuff();
		
		gui.draw(image);
		gui.sdl2.processEvents();		
		//fw.throttleBack(64.msecs);
	}
	
	gui.waitForExit();
}

void drawStuff(FrameBuf img, uint pixelSize)
{
	//drawGradient(img);
	
	drawBresenhamLine(img, Point(50, 30, pixelSize), Point(320, 100, pixelSize), Color.Orange);
	drawBresenhamLine(img, Point(50, 40, pixelSize), Point(620, 200, pixelSize), Color.Purple);
	drawBresenhamLine(img, Point(50, 50, pixelSize), Point(500, 300, pixelSize), Color.Orange);
	drawBresenhamLine(img, Point(50, 50, pixelSize), Point(400, 400, pixelSize), Color.White);
	drawBresenhamLine(img, Point(50, 60, pixelSize), Point(320, 450, pixelSize), Color.Pink);
	
	img.DrawBresenhamCircle(Point(150, 150, pixelSize), 100 / pixelSize, Color.CornflowerBlue);
	
	img.SimpleFloodFill_4(Point(200, 300, pixelSize), Color.Yellow, Color.Black);
}

