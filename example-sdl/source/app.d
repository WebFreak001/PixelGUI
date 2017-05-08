import derelict.sdl2.sdl;

import pixelgui;
import pixelgui.material;

import std.stdio;
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
	auto window = gui.newRootWidget!LinearLayout(14 * 20 + 10, 19 * 20 + 10);

	window.padding = Rectangle(4.px);

	void addButton(string color)()
	{
		auto button = new MaterialButton();
		button.rectangle = Rectangle(0.px, 18.px, 18.px, 0.px);
		button.padding = Rectangle(0.px);
		button.margin = Rectangle(2.px);
		button.color = makeButtonColor!color;
		button.onClick ~= () {
			writeln(color, ": ", button.color.normalColor.toColorHexString);
		};
		window.addChild(button);
	}

	foreach (color; __traits(allMembers, MaterialColors))
	{
		static if (color != "transparent") // move transparent to end for nicer alignment
			addButton!color;
	}
	addButton!"transparent";

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
						cast(Key) event.key.keysym.sym, event.key.repeat);
				break;
			case SDL_KEYUP:
				window.handleKeyUp(event.key.keysym.scancode, event.key.keysym.mod,
						cast(Key) event.key.keysym.sym);
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
