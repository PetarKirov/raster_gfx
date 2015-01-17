import core.thread;
import std.datetime;
import std.stdio;

import ae.utils.graphics.image;
import sdl2gui, color;
import raster;

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
	auto gui = SDL2Gui(w, h, "Task 1");
	auto image = Image!Color();
	image.size(w, h);
	
	auto animationFiber = new Fiber({ image.drawStuff(); },
									64 * 1024 * 1024);
	
	auto fw = FrameWatch();
	fw.start();
	fw.throttleBack(500.msecs);
	
	// Animation loop
	while(!gui.isQuitRequested)
	{	
		animationFiber.call();
		
		if (animationFiber.state == Fiber.State.TERM)
			break;		
		
		gui.draw(image);
		gui.sdl2.processEvents();		
		//fw.throttleBack(64.msecs);
	}
	
	gui.waitForExit();
}

void drawStuff(Image!Color img)
{
	//drawGradient(img);
	
	drawBresenhamLine(img, 50, 30, 320, 100, Color.Orange);
	//drawBresenhamLine(img, 50, 40, 320, 200, Color.Purple);
	//drawBresenhamLine(img, 50, 50, 320, 300, Color.Orange);
	//drawBresenhamLine(img, 50, 50, 320, 400, Color.White);
	//drawBresenhamLine(img, 50, 60, 320, 500, Color.Pink);
	
	img.DrawBresenhamCircle(150, 150, 100, Color.CornflowerBlue);
	
	img.SimpleFloodFill_4(200, 300, Color.Orange, Color.Black);
}

