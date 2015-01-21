module sdl2gui;

import std.experimental.logger;
import gfm.sdl2, ae.utils.graphics.view;

//Default SDL2 GUI
struct SDL2Gui
{
	immutable uint width, height;

	private SDL2 sdl2;
	private SDL2Window window;
	private SDL2Renderer renderer;
	private SDL2Surface surface;
	private SDL2Texture texture;
	private Logger log;

	this(uint width, uint height, string title, Logger log = stdlog)
	{
		this.width = width;
		this.height = height;
		init(title, log);
	}

	void init(string title, Logger log_)
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

	@property bool isQuitRequested()
	{
		return sdl2.keyboard().isPressed(SDLK_ESCAPE) ||
			sdl2.wasQuitRequested();
	}

	void waitForExit()
	{
		SDL_Event temp;
		while(!isQuitRequested)
			sdl2.waitEvent(&temp);
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

	void draw(Image)(auto ref Image buf) if (isView!Image)
	{		
		uint[] pixels = (cast(uint*)surface.pixels)[0 .. width * height];
		auto img = buf.img;
		auto pixelWidth = buf.pixelSize.x;
		auto pixelHeight = buf.pixelSize.y;

		if (buf.pixelSize.x == 1 && buf.pixelSize.y == 1)
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
		
		texture.updateTexture(surface.pixels, surface.pitch);
		renderer.clear();
		renderer.copy(texture, 0, 0);
		renderer.present();
	}

	~this()
	{
		log.log("At ~SDL2Gui()");
		this.close();
	}
}