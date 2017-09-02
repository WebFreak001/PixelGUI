module pixelgui.sdl;

import pixelgui;

import derelict.sdl2.sdl;

import std.string;

/// Exception for SDL related issues
class SDLException : Exception
{
	/// Creates an exception from SDL_GetError()
	this(string file = __FILE__, size_t line = __LINE__) nothrow @nogc
	{
		super(cast(string) SDL_GetError().fromStringz, file, line);
	}
}

MouseButton sdlButtonToGuiButton(ubyte button)
{
	switch (button)
	{
	case SDL_BUTTON_LEFT:
		return MouseButton.left;
	case SDL_BUTTON_MIDDLE:
		return MouseButton.middle;
	case SDL_BUTTON_RIGHT:
		return MouseButton.right;
	default:
		return cast(MouseButton)(button + 1);
	}
}

pragma(inline, true) Key sdlKeysymToGuiKey(uint sym)
{
	return cast(Key) sym;
}

struct SDLPixelWindow(T)
{
	SDL_Window* sdlWindow;
	SDL_Renderer* renderer;
	SDL_Texture* texture;

	~this()
	{
		SDL_DestroyWindow(sdlWindow);
		SDL_DestroyRenderer(renderer);
		SDL_DestroyTexture(texture);
	}
}

void initSDL()
{
	DerelictSDL2.load(SharedLibVersion(2, 0, 2));

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		throw new SDLException();

	SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
}

SDLPixelWindow!T createSDLWindow(T)(ref RootWidget!T window)
{
	auto flags = SDL_WINDOW_SHOWN;
	if (window.resizable)
		flags |= SDL_WINDOW_RESIZABLE;
	auto sdlWindow = SDL_CreateWindow(window.name.toStringz, SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED, window.width, window.height, flags);
	if (!sdlWindow)
		throw new SDLException();

	auto renderer = SDL_CreateRenderer(sdlWindow, -1, 0);

	auto texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ABGR8888,
			SDL_TEXTUREACCESS_STATIC, window.width, window.height);

	return SDLPixelWindow!T(sdlWindow, renderer, texture);
}

void runWithSDL(T)(ref PixelGUI gui, ref RootWidget!T window)
{
	initSDL();
	scope (exit)
		SDL_Quit();

	auto sdl = createSDLWindow(window);
	SDL_Event event;
	bool quit = false;
	while (!quit)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_QUIT:
				quit = true;
				break;
			case SDL_WINDOWEVENT:
				switch (event.window.event)
				{
				case SDL_WINDOWEVENT_RESIZED:
				case SDL_WINDOWEVENT_SIZE_CHANGED:
					SDL_DestroyTexture(sdl.texture);
					sdl.texture = SDL_CreateTexture(sdl.renderer, SDL_PIXELFORMAT_ABGR8888,
							SDL_TEXTUREACCESS_STATIC, window.width, window.height);
					gui.resize(window, event.window.data1, event.window.data2);
					break;
				case SDL_WINDOWEVENT_EXPOSED:
					window.redrawRect(0, 0, window.width, window.height);
					break;
				case SDL_WINDOWEVENT_FOCUS_GAINED:
					window.handleFocus();
					break;
				case SDL_WINDOWEVENT_FOCUS_LOST:
					window.handleUnfocus();
					break;
				case SDL_WINDOWEVENT_CLOSE:
					window.handleClose();
					break;
				case SDL_WINDOWEVENT_LEAVE:
					window.handleUnhover();
					break;
				default:
					break;
				}
				break;
			case SDL_KEYDOWN:
				window.handleKeyDown(event.key.keysym.scancode, event.key.keysym.mod,
						event.key.keysym.sym.sdlKeysymToGuiKey, event.key.repeat);
				break;
			case SDL_KEYUP:
				window.handleKeyUp(event.key.keysym.scancode, event.key.keysym.mod,
						event.key.keysym.sym.sdlKeysymToGuiKey);
				break;
			case SDL_TEXTINPUT:
				window.handleTextInput(event.text.text.ptr.fromStringz.idup);
				break;
			case SDL_MOUSEMOTION:
				window.handleMouseMove(event.motion.x, event.motion.y);
				break;
			case SDL_MOUSEBUTTONDOWN:
				window.handleMouseDown(event.button.x, event.button.y,
						event.button.button.sdlButtonToGuiButton, event.button.clicks);
				break;
			case SDL_MOUSEBUTTONUP:
				window.handleMouseUp(event.button.x, event.button.y,
						event.button.button.sdlButtonToGuiButton);
				break;
			case SDL_MOUSEWHEEL:
				int r = event.wheel.direction == SDL_MOUSEWHEEL_FLIPPED ? -1 : 1;
				window.handleScroll(event.wheel.x * r, event.wheel.y * r);
				break;
			case SDL_DROPFILE:
				window.handleDropFile(event.drop.file.fromStringz.idup);
				SDL_free(event.drop.file);
				break;
			case SDL_DROPTEXT:
				window.handleDropText(event.drop.file.fromStringz.idup);
				SDL_free(event.drop.file);
				break;
			case SDL_RENDER_DEVICE_RESET:
				sdl.texture = SDL_CreateTexture(sdl.renderer, SDL_PIXELFORMAT_ABGR8888,
						SDL_TEXTUREACCESS_STATIC, window.width, window.height);
				goto case;
			case SDL_RENDER_TARGETS_RESET:
				window.redrawRect(0, 0, window.width, window.height);
				break;
			default:
				break;
			}
		}

		dispatcher.tick;

		if (window.draw)
		{
			SDL_UpdateTexture(sdl.texture, null, window.target.pixels.ptr, window.width * 4);
			SDL_RenderCopy(sdl.renderer, sdl.texture, null, null);
			SDL_RenderPresent(sdl.renderer);
		}
		SDL_Delay(0);
	}
}

void captureMouse(bool enable)
{
	SDL_CaptureMouse(enable);
}
