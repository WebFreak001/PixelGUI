import derelict.sdl2.sdl;

import pixelgui;

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

class DummyWidget : FastWidget
{
	override void draw(ref RenderTarget, Container)
	{
	}
}

void main()
{
	DerelictSDL2.load(SharedLibVersion(2, 0, 2));

	auto gui = makePixelGUI;
	auto window = gui.newRootWidget!FloatingLayout(853, 480);

	auto button = new Button();
	button.rectangle = Rectangle(8.px, 99.percent, 99.percent, 8.px);
	window.addChild(button);

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		throw new SDLException();
	scope (exit)
		SDL_Quit();

	auto sdlWindow = SDL_CreateWindow("Wedit", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
			window.width, window.height, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
	if (!sdlWindow)
		throw new SDLException();

	auto renderer = SDL_CreateRenderer(sdlWindow, -1, 0);
	scope (exit)
		SDL_DestroyRenderer(renderer);

	auto texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ABGR8888,
			SDL_TEXTUREACCESS_STATIC, window.width, window.height);

	bool quit = false;
	SDL_Event event;

	SDL_EventState(SDL_DROPFILE, SDL_ENABLE);

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
					SDL_DestroyTexture(texture);
					texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ABGR8888,
							SDL_TEXTUREACCESS_STATIC, window.width, window.height);
					gui.resize(window, event.window.data1, event.window.data2);
					break;
				case SDL_WINDOWEVENT_EXPOSED:
					window.redrawRect(0, 0, window.width, window.height);
					break;
				case SDL_WINDOWEVENT_FOCUS_GAINED:
					window.onFocus();
					break;
				case SDL_WINDOWEVENT_FOCUS_LOST:
					window.onUnfocus();
					break;
				case SDL_WINDOWEVENT_CLOSE:
					window.onClose();
					break;
				case SDL_WINDOWEVENT_LEAVE:
					window.onUnhover();
					break;
				default:
					break;
				}
				break;
			case SDL_KEYDOWN:
				window.onKeyDown(event.key.keysym.scancode, event.key.keysym.mod,
						event.key.keysym.sym, event.key.repeat);
				break;
			case SDL_KEYUP:
				window.onKeyUp(event.key.keysym.scancode, event.key.keysym.mod, event.key.keysym.sym);
				break;
			case SDL_TEXTINPUT:
				window.onTextInput(event.text.text.ptr.fromStringz.idup);
				break;
			case SDL_MOUSEMOTION:
				window.onMouseMove(event.motion.x, event.motion.y);
				break;
			case SDL_MOUSEBUTTONDOWN:
				window.onMouseDown(event.button.x, event.button.y,
						event.button.button.sdlButtonToGuiButton, event.button.clicks);
				break;
			case SDL_MOUSEBUTTONUP:
				window.onMouseUp(event.button.x, event.button.y, event.button.button.sdlButtonToGuiButton);
				break;
			case SDL_MOUSEWHEEL:
				int r = event.wheel.direction == SDL_MOUSEWHEEL_FLIPPED ? -1 : 1;
				window.onScroll(event.wheel.x * r, event.wheel.y * r);
				break;
			case SDL_DROPFILE:
				window.onDropFile(event.drop.file.fromStringz.idup);
				SDL_free(event.drop.file);
				break;
			case SDL_DROPTEXT:
				window.onDropText(event.drop.file.fromStringz.idup);
				SDL_free(event.drop.file);
				break;
			case SDL_RENDER_DEVICE_RESET:
				texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ABGR8888,
						SDL_TEXTUREACCESS_STATIC, window.width, window.height);
				goto case;
			case SDL_RENDER_TARGETS_RESET:
				window.redrawRect(0, 0, window.width, window.height);
				break;
			default:
				break;
			}
		}

		if (window.draw)
		{
			SDL_UpdateTexture(texture, null, window.target.pixels.ptr, window.width * 4);
			SDL_RenderCopy(renderer, texture, null, null);
			SDL_RenderPresent(renderer);
		}
		SDL_Delay(0);
	}
}
