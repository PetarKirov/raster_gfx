module sdl2gui;

import std.experimental.logger;
import gfm.sdl2, ae.utils.graphics.image;

//Default SDL2 GUI
struct SDL2Gui
{
	uint width, height;

	SDL2 sdl2;
	SDL2Window window;
	SDL2Renderer renderer;
	SDL2Surface surface;
	SDL2Texture texture;
	Logger log;	

	this(uint width, uint height, string title, Logger log = stdlog)
	{
		init(width, height, title, log);
	}

	void init(uint width, uint height, string title, Logger log_)
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
		this.width = width;
		this.height = height;

		renderer.setColor(255, 255, 255, 255);
		renderer.clear();
		renderer.copy(texture, 0, 0);
		renderer.present();
	}

	void draw(SRC)(auto ref SRC image) if (isView!SRC)
	{		
		void* pixels = surface.pixels;

		foreach (y; 0 .. surface.height)
			(cast(uint*)pixels)[y * surface.width .. (y + 1 )* surface.width] = cast(uint[])image.scanline(y);
		
		texture.updateTexture(surface.pixels, surface.pitch);
		renderer.clear();
		renderer.copy(texture, 0, 0);
		renderer.present();
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

	~this()
	{
		log.log("At ~SDL2Gui()");
		this.close();
	}
}