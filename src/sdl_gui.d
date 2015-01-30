module sdl_gui;

import core.thread : Fiber;
import std.datetime : Duration, msecs;
import std.experimental.logger;
import gfm.sdl2;
import primitives, frame_buf, frame_watch;

/// Use only with scoped!
class SdlGui
{
@trusted:

	immutable uint width, height;

	private SDL2 sdl2;
	private SDL2Window window;
	private SDL2Renderer renderer;
	private SDL2Surface surface;
	private SDL2Texture texture;
	private Logger log;

	// Used to prevent over-drawing if a fiber tries call the draw method,
	// instead of waiting for us to call it after the fiber yields.
	private bool fiberCalled = false;

	this(uint x, uint y, string title, Logger log = stdlog)
	{
		this.width = x;
		this.height = y;
		initSDL(title, log);
	}

	private void initSDL(string title, Logger log_)
	{
		log = log_;
		sdl2 = new SDL2(log);
		window = new SDL2Window(sdl2, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
								width, height,
								SDL_WINDOW_SHOWN | SDL_WINDOW_INPUT_FOCUS | SDL_WINDOW_MOUSE_FOCUS);
		window.setTitle(title);
		renderer = new SDL2Renderer(window, SDL_RENDERER_SOFTWARE);
		surface = new SDL2Surface(sdl2, width, height, 32,
								  0x00FF0000,
								  0x0000FF00,
								  0x000000FF,
								  0xFF000000);

		texture = new SDL2Texture(renderer,
								  SDL_PIXELFORMAT_ARGB8888,
								  SDL_TEXTUREACCESS_STREAMING,
								  surface.width, surface.height);

		renderer.setColor(255, 255, 255, 255);
		renderer.clear();
		renderer.copy(texture, 0, 0);
		renderer.present();
	}

	void processEvents()
	{
		sdl2.processEvents();
	}

	@trusted void drawWithFiber(ref FrameBuf buf, Fiber drawFiber, FrameWatch fw, Duration wantedFrameTime)
	{
		while(!isQuitRequested && drawFiber.state != Fiber.State.TERM)
		{
			fiberCalled = true;
			drawFiber.call();
			fiberCalled = false;

			draw(buf);
			processEvents();

			if (wantedFrameTime > 1.msecs)
				fw.throttleBack(wantedFrameTime);
		}
	}

	@trusted void drawWithFunc(ref FrameBuf buf, void delegate() drawFunc, FrameWatch fw, Duration wantedFrameTime)
	{
		drawFunc();
		draw(buf);
		processEvents();

		if (wantedFrameTime > 1.msecs)
			fw.throttleBack(wantedFrameTime);
	}

	@property bool isQuitRequested()
	{
		processEvents();
		return sdl2.keyboard().isPressed(SDLK_ESCAPE) ||
			sdl2.wasQuitRequested();
	}

	void waitForExit()
	{
		SDL_Event temp;
		while(!isQuitRequested)
			sdl2.waitEvent(&temp);
	}

	void setTitle(string title)
	{
		window.setTitle(title);
	}

	Point2 getMousePosition(bool buttonPressed)
	{
		Point2 result;

		while(!isQuitRequested)
		{
			processEvents();

			if (sdl2.mouse.isButtonPressed(SDL_BUTTON_LMASK) == buttonPressed)
			{
				auto pos = sdl2.mouse().position();
				result = Point2(pos.x, pos.y);
				break;				
			}
		}

		return result;
	}

	Point2 getPoint(string msg = null)
	{
		if (msg)
			setTitle(msg);

		cast(void)getMousePosition(false);

		return getMousePosition(true);
	}

	Line2 getLine(string msg1, string msg2)
	{
		auto start = getPoint(msg1);
		auto end = getPoint(msg2);

		return Line2(start, end);
	}

	void draw(ref FrameBuf img)
	{
		if (fiberCalled)
			return;

		uint[] pixels = (cast(uint*)surface.pixels)[0 .. width * height];
		auto pixelWidth = img.metrics.pixelSize.x;
		auto pixelHeight = img.metrics.pixelSize.y;

		if (pixelWidth == 1 && pixelHeight == 1)
		{
			pixels[] = cast(uint[])img.pixels[];
		}
		else
		{

			foreach (y; 0 .. img.h)
			{
				auto row = y * pixelHeight;
				auto rowStart = row * width;
				auto rowEnd = (row + 1) * width;

				foreach (x; 0 .. img.w)
				{
					auto colStart = x * pixelWidth;
					auto pos = rowStart + colStart;
					pixels[pos .. pos + pixelWidth] = cast(uint)img[x, y];
				}

				// Repeat each row (yRatio - 1) times
				foreach (pY; 1 .. pixelHeight)
				{
					auto nextRowStart = rowStart + width * pY;
					auto nextRowEnd = rowEnd + width * pY;
					pixels[nextRowStart .. nextRowEnd] =
						pixels[rowStart .. rowEnd];
				}
			}
		}
		
		texture.updateTexture(surface.pixels, cast(int)surface.pitch);
		renderer.clear();
		renderer.copy(texture, 0, 0);
		renderer.present();
	}

	void close()
	{
		log.log("Attempting to close SDL2 resources.");
		texture.close();
		surface.close();
		renderer.close();
		window.close();
		sdl2.close();
	}

	~this()
	{
		log.log("At ~SDL2Gui()");
		this.close();
	}
}
