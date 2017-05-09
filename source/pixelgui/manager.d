module pixelgui.manager;

import std.experimental.allocator;

import pixelgui.render;
import pixelgui.widget;

import std.exception;

class RootWidget(T : RawWidget) : T
{
	RenderTarget target;

	string name;
	bool resizable = true;
	Color backgroundColor = HTMLColors.white;

	void redrawRect(int x, int y, int w, int h)
	{
		// TODO: only update in rect
		redraw();
	}

	bool draw()
	{
		if (requiresRedraw)
			target.clearFast(backgroundColor);
		if (shouldRedraw)
		{
			computedRectangle = Container(0, 0, width, height);
			finalDraw(target, [computedRectangle]);
			clearDrawQueue();
			return true;
		}
		requiresRedraw = false;
		return false;
	}

	int width() const @property
	{
		return target.w;
	}

	int height() const @property
	{
		return target.h;
	}
}

/// PixelGUI root object handling allocations and such
struct PixelGUI
{
	@disable this();

	IAllocator allocator;

	this(IAllocator allocator)
	{
		this.allocator = allocator;
	}

	RootWidget!WidgetImpl newRootWidget(WidgetImpl : RawWidget)(int width, int height)
	{
		auto ret = allocator.make!(RootWidget!WidgetImpl);
		ret.target.w = width;
		ret.target.h = height;
		ret.target.pixels = allocator.makeArray!ubyte(width * height * 4);
		return ret;
	}

	void resize(WidgetImpl : RawWidget)(ref RootWidget!WidgetImpl widget, int width, int height)
	{
		size_t oldSize = widget.target.pixels.length;
		size_t newSize = width * height * 4;
		if (newSize == oldSize)
			return;
		widget.target.w = width;
		widget.target.h = height;
		if (newSize > oldSize)
			allocator.expandArray(widget.target.pixels, newSize - oldSize).enforce;
		else
			allocator.shrinkArray(widget.target.pixels, oldSize - newSize).enforce;
		widget.handleResize(width, height);
		widget.redraw();
	}
}

PixelGUI makePixelGUI(IAllocator alloc = theAllocator)
{
	return PixelGUI(alloc);
}
