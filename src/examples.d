module examples;

import frame_buf, sdl_gui, primitives, raster_methods;

mixin template Input()
{
	ScreenLine getLine()
	{
		return ScreenLine(gui.getLine("Click somewhere to set the starting point", "Click elsewhere to set the end point"),
		                  img.metrics);
	}
	
	ScreenPoint getPoint(string msg)
	{
		return ScreenPoint(gui.getPoint(msg), img.metrics);
	}
}

void task1_var3(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto line = getLine();
		img.drawBresenhamLine(line, Color.Orange);
		img.drawBresenhamLine!((ref img, color, Point2 point) =>
		                       PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
			point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
			(line, Color.CornflowerBlue);
		
		gui.draw(img);
	}
}

void task2_var3(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto center = getPoint("1: Click somewhere to set the center of the circle");
		auto end = getPoint("2: Click elsewhere to set the radius of the circle");
		int r = center.distanceTo(end);
		img.drawBresenhamCircle(center, r, Color.CornflowerBlue);
		img.drawBresenhamCircle!((ref img, color, point) =>
		                         PutPixels(img, color, [point.up(), point.down(), point.left(), point.right(),
			point.upLeft(), point.upRight(), point.downLeft(), point.downRight()]))
			(center, r, Color.CornflowerBlue);
		
		gui.draw(img);
	}
}

void task1_var2(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto line = getLine();
		img.drawBresenhamLine(line, Color.Orange);
		img.drawBresenhamLine_FromEndToEnd(line, Color.Blue, Color.Pink);
		
		gui.draw(img);
	}
}

void task1_var2_no_overlay(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto line = getLine();
		img.drawBresenhamLine(line, Color.Orange);
		
		line = getLine();
		img.drawBresenhamLine_FromEndToEnd(line, Color.Blue, Color.Pink);
		
		gui.draw(img);
	}
}

void task2_var2(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto center = getPoint("1: Click somewhere to set the center of the circle");
		auto end = getPoint("2: Click elsewhere to set the radius of the circle");
		int r = center.distanceTo(end);
		
		img.drawBresenhamCircle(center, r, Color.CornflowerBlue);
		img.drawMichenerCircle(center, r, Color.Brown);
		
		gui.draw(img);
	}
}

void task2_var2_no_overlay(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	while(!gui.isQuitRequested)
	{
		auto center = getPoint("1: Click somewhere to set the center of the Bresenham circle");
		auto end = getPoint("2: Click elsewhere to set the radius of the Bresenham circle");
		int r = center.distanceTo(end);
		img.drawBresenhamCircle(center, r, Color.CornflowerBlue);
		
		center = getPoint("1: Click somewhere to set the center of the Michener circle");
		end = getPoint("2: Click elsewhere to set the radius of the Michener circle");
		r = center.distanceTo(end);
		img.drawMichenerCircle(center, r, Color.Brown);
		
		gui.draw(img);
	}
}

void task3_var3(FrameBuf img, SdlGui gui)
{
	import std.string : format;
	
	mixin Input;
	
	// Get center and radius for 4 circles
	foreach (i; 0 .. 4)
	{
		auto center = getPoint(format("(%s/5)|(1/2) Click somewhere to set the center of the Bresenham circle", i + 1));
		auto end = getPoint(format("(%s/5)|(2/2) Click elsewhere to set the radius of the Bresenham circle", i + 1));
		img.drawBresenhamCircle(center, center.distanceTo(end), Color.CornflowerBlue);
		
		gui.draw(img);
	}
	
	// Fill stuff till program quit
	while(!gui.isQuitRequested)
	{
		auto p = getPoint("(5/5)|(1/1) Click somewhere in the area between the circles to fill it");
		img.SimpleBoundryFill_4(p, Color.Yellow, Color.CornflowerBlue);
		
		gui.draw(img);
	}
}

void task4_var3(FrameBuf img, SdlGui gui)
{
	auto bounds = ScreenRectangle(50, 50, 250, 250, img.metrics);
	img.drawRectangle(bounds, Color.White);
	
	auto line = ScreenLine(50, 25, 250, 290, img.metrics);
	img.drawBresenhamLine(line, Color.White);
	
	img.CohenSuttherland(line, bounds, Color.Purple);
	
	gui.draw(img);
}

void task_fill_quadrangle(FrameBuf img, SdlGui gui)
{
	mixin Input;
	
	auto p1 = getPoint("Click somewhere to set the 1st vertex of the rectangle");
	auto p2 = getPoint("Click somewhere to set the 2nd vertex of the rectangle");
	auto l = ScreenLine(p1, p2);
	img.drawBresenhamLine(l, Color.Blue);
	gui.draw(img);
	
	auto p3 = getPoint("Click somewhere to set the 3rd vertex of the rectangle");
	l = ScreenLine(p2, p3);
	img.drawBresenhamLine(l, Color.Blue);
	gui.draw(img);
	
	auto p4 = getPoint("Click somewhere to set the 4th vertex of the rectangle");
	l = ScreenLine(p3, p4);
	img.drawBresenhamLine(l, Color.Blue);
	gui.draw(img);
	
	l = ScreenLine(p4, p1);
	img.drawBresenhamLine(l, Color.Blue);
	gui.draw(img);
	
	while(!gui.isQuitRequested)
	{
		auto centerFill = getPoint("Click somewhere inside the quadrangle to fill it");
		img.SimpleFloodFill_4(centerFill, Color.Red, Color.Black);
		gui.draw(img);
	}
	
	gui.setTitle("Done");
}

void drawFastStuff(FrameBuf img, SdlGui gui)
{
	//img.drawGradient();
	
	img.drawBresenhamLine(ScreenLine(50, 30, 620, 100, img.metrics), Color.Orange);
	img.drawBresenhamLine(ScreenLine(50, 40, 500, 200, img.metrics), Color.Orange);
	img.drawBresenhamLine(ScreenLine(50, 50, 400, 300, img.metrics), Color.Orange);
	img.drawBresenhamLine(ScreenLine(50, 60, 320, 450, img.metrics), Color.Orange);
	
	assert(img.metrics.pixelSize.x == img.metrics.pixelSize.y, "Pixels should be square");
	auto r = 100 / img.metrics.pixelSize.x;
	auto c = ScreenPoint(150, 150, img.metrics);
	img.drawBresenhamCircle(c, r, Color.CornflowerBlue);
}

void drawSlowStuff(FrameBuf img, SdlGui gui)
{
	img.SimpleFloodFill_4(ScreenPoint(200, 300, img.metrics), Color.Yellow, Color.Black);
}
