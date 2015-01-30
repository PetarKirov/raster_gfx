import core.thread : Fiber;
import std.datetime : msecs;
import std.stdio;
import std.typecons : scoped;

import primitives, raster_methods;
import frame_buf, frame_watch, sdl_gui;

@safe @property
Duration fps(long x) { return (1000 / x).msecs; }

alias DrawFunc = void function(FrameBuf img, SdlGui gui);

void main()
{
	uint w = 640, h = 480;
	uint ps = 3; // pixel size
	auto fw = new FrameWatch();
	auto gui = scoped!SdlGui(w, h, "Task 1");
	auto image = scoped!FrameBuf(w, h, ps, ps);

	fw.start();
	fw.throttleBack(500.msecs);

	doDraw(image, gui, fw);

	gui.setTitle("Press Esc to exit.");
	gui.waitForExit();
}

void doDraw(FrameBuf image, SdlGui gui, FrameWatch fw)
{
	mixin drawFuncAdaptors;

	drawWithFunc(&task4_var3, 0.msecs);
}

mixin template drawFuncAdaptors()
{
	@trusted Fiber fiber(DrawFunc func, size_t fiberStackSize = 64 * 1024 * 1024)
	{
		return new Fiber({ func(image, gui); }, fiberStackSize);
	}
	
	@trusted void drawWithFiber(DrawFunc func, Duration frameTime, size_t fiberStackSize = 64 * 1024 * 1024)
	{
		gui.drawWithFiber(image, fiber(func, fiberStackSize), fw, frameTime);
	}
	
	@trusted void drawWithFunc(DrawFunc func, Duration frameTime)
	{
		gui.drawWithFunc(image, { func(image, gui); }, fw, frameTime);
	}
}

