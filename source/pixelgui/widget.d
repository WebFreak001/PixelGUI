module pixelgui.widget;

import pixelgui.constants;
import pixelgui.render;

import tinyevent;

import std.algorithm;
import std.math;
import std.exception;

enum Overflow
{
	shown,
	hidden,
	scroll,
	scrollX,
	scrollY
}

struct Container
{
	int x, y, w, h;

	alias right = w;
	alias bottom = h;

	Container push(int y, int right, int bottom, int x, Overflow overflow) const
	{
		int w = right - x;
		int h = bottom - y;
		if (overflow == Overflow.shown)
			return Container(this.x + x, this.y + y, w, h);
		else
		{
			if (overflow == Overflow.hidden || overflow == Overflow.scrollY)
			{
				if (x < 0)
				{
					w += x;
					x = 0;
				}
				if (x + w > this.x + this.w)
					w = this.x + this.w - x;
			}
			if (overflow == Overflow.hidden || overflow == Overflow.scrollX)
			{
				if (y < 0)
				{
					h += y;
					y = 0;
				}
				if (y + h > this.y + this.h)
					h = this.y + this.h - y;
			}
			return Container(this.x + x, this.y + y, w, h);
		}
	}
}

struct Length
{
	enum Mode : ubyte
	{
		pixel,
		percent,
		point,
		vw,
		vh,
		em,
		fitContent
	}

	float value = 0;
	Mode mode;

	float compute(Container[] hierarchy, bool horizontal) const
	{
		final switch (mode)
		{
		case Mode.pixel:
			return value;
		case Mode.percent:
			return (horizontal ? hierarchy[$ - 1].w : hierarchy[$ - 1].h) * 0.01f * value;
		case Mode.point:
			return value / 90.0 * 72.0; // TODO
		case Mode.vw:
			return hierarchy[0].w * 0.01 * value;
		case Mode.vh:
			return hierarchy[0].h * 0.01 * value;
		case Mode.em:
			return value * 16; // TODO
		case Mode.fitContent:
			return 0;
		}
	}

	Length opBinary(string op)(Length rhs) const
	{
		if (rhs.mode != mode && value != 0)
			return Length(value, mode);
		return Length(mixin("value" ~ op ~ "rhs.value"), mode);
	}
}

struct Rectangle
{
	union
	{
		Length[4] rect;
		struct
		{
			/// Length units relative to top left
			Length top, right, bottom, left;
		}
	}

	this(Length top, Length right, Length bottom, Length left)
	{
		this.top = top;
		this.right = right;
		this.bottom = bottom;
		this.left = left;
	}

	this(Length top, Length leftRight, Length bottom)
	{
		this.top = top;
		left = right = leftRight;
		this.left = left;
	}

	this(Length topBottom, Length leftRight)
	{
		top = bottom = topBottom;
		left = right = leftRight;
	}

	this(Length all)
	{
		top = right = bottom = left = all;
	}

	Length width() const
	{
		return right - left;
	}

	Length width(Length val)
	{
		right = left + val;
		return val;
	}

	Length height() const
	{
		return bottom - top;
	}

	Length height(Length val)
	{
		bottom = top + val;
		return val;
	}

	enum full = Rectangle(0.px, 100.percent, 100.percent, 0.px);

	static Rectangle size(int widthPx, int heightPx)
	{
		return Rectangle(0.px, widthPx.px, heightPx.px, 0.px);
	}

	static Rectangle size(Length width, Length height)
	{
		return Rectangle(0.px, width, height, 0.px);
	}
}

struct Position
{
	union
	{
		Length[2] pos;
		struct
		{
			Length x, y;
		}
	}
}

Length px(int i)
{
	return Length(i, Length.Mode.pixel);
}

Length px(float i)
{
	return Length(i, Length.Mode.pixel);
}

Length percent(int i)
{
	return Length(i, Length.Mode.percent);
}

Length percent(float i)
{
	return Length(i, Length.Mode.percent);
}

Length pt(int i)
{
	return Length(i, Length.Mode.point);
}

Length pt(float i)
{
	return Length(i, Length.Mode.point);
}

Length vw(int i)
{
	return Length(i, Length.Mode.vw);
}

Length vw(float i)
{
	return Length(i, Length.Mode.vw);
}

Length vh(int i)
{
	return Length(i, Length.Mode.vh);
}

Length vh(float i)
{
	return Length(i, Length.Mode.vh);
}

Length em(int i)
{
	return Length(i, Length.Mode.em);
}

Length em(float i)
{
	return Length(i, Length.Mode.em);
}

Length fitContent()
{
	return Length(0, Length.Mode.fitContent);
}

Container layout(bool rectangle = false)(Rectangle r, Container[] hierarchy,
		Overflow overflow = Overflow.shown)
{
	int top = cast(int) round(r.top.compute(hierarchy, false));
	int right = cast(int) round(r.right.compute(hierarchy, true));
	int bottom = cast(int) round(r.bottom.compute(hierarchy, false));
	int left = cast(int) round(r.left.compute(hierarchy, true));
	static if (rectangle)
		return Container(left, top, right, bottom);
	else
		return hierarchy[$ - 1].push(top, right, bottom, left, overflow);
}

mixin template RedrawProperty(T, string name, T defaultValue = T.init)
{
	mixin("auto " ~ name ~ "() const @property { return _" ~ name ~ "; }");
	mixin("T " ~ name ~ "(T val) @property { _" ~ name ~ " = val; redraw(); return _" ~ name ~ "; }");
	mixin("T _" ~ name ~ " = defaultValue;");
}

abstract class RawWidget
{
	mixin RedrawProperty!(Rectangle, "rectangle", Rectangle.full);
	mixin RedrawProperty!(Rectangle, "margin");
	mixin RedrawProperty!(Rectangle, "padding");
	RawWidget parent;
	mixin RedrawProperty!(RawWidget[], "children");
	mixin RedrawProperty!(Overflow, "overflow");
	bool requiresRedraw = true;
	mixin RedrawProperty!(bool, "hasLocalFocus");
	mixin RedrawProperty!(bool, "hasGlobalFocus");
	mixin RedrawProperty!(bool, "canReceiveFocus");
	bool hadHover = false;

	Container computedRectangle;

	abstract void finalDraw(ref RenderTarget dest, Container[] hierarchy);

	/// Override and return true if there are any transparent pixels drawn
	bool isTransparent() const @property
	{
		return false;
	}

	/// Returns true if this widget or any children require a redraw
	bool shouldRedraw() const @property
	{
		if (requiresRedraw)
			return true;
		foreach (child; children)
			if (child.shouldRedraw)
				return true;
		return false;
	}

	void redraw()
	{
		if (requiresRedraw)
			return;
		requiresRedraw = true;
		if (isTransparent && parent)
			parent.redraw();
		foreach (ref child; _children)
			child.redraw();
	}

	void clearDrawQueue()
	{
		requiresRedraw = false;
		foreach (ref child; _children)
			child.clearDrawQueue();
	}

	void addChild(RawWidget widget)
	{
		enforce(widget.parent is null, "Can't add widget to two different containers");
		widget.parent = this;
		widget.redraw();
		_children ~= widget;
	}

	bool isFocused() const @property
	{
		return hasGlobalFocus && hasLocalFocus && canReceiveFocus;
	}

	/// (width, height) event when widget got resized
	Event!(int, int) onResize;
	/// Event when widget got focused
	Event!() onFocus;
	/// Event when widget got unfocused
	Event!() onUnfocus;
	/// Event when widget got unhovered
	Event!() onUnhover;
	/// Event on root window when it got closed
	Event!() onClose;
	/// (scancode, mods, key, repeats) when key is pressed
	Event!(int, int, Key, int) onKeyDown;
	/// (scancode, mods, key) when key is unpressed
	Event!(int, int, Key) onKeyUp;
	/// (text) when text has been entered (for example unicode or compose key)
	Event!(string) onTextInput;
	/// (x, y) when mouse has been moved
	Event!(int, int) onMouseMove;
	/// (x, y, button, clicks) when mouse has been pressed down
	Event!(int, int, MouseButton, int) onMouseDown;
	/// (x, y, button) when mouse has been released
	Event!(int, int, MouseButton) onMouseUp;
	/// (scrollX, scrollY) when mouse wheel has been used
	Event!(int, int) onScroll;
	/// (filename) when file has been dragged into the window
	Event!(string) onDropFile;
	/// (text) when text has been dragged into the window
	Event!(string) onDropText;

	void handleResize(int width, int height)
	{
		onResize.emit(width, height);
	}

	void handleFocus()
	{
		onFocus.emit();
		hasGlobalFocus = true;
		foreach (child; _children)
			child.handleFocus();
	}

	void handleUnfocus()
	{
		onUnfocus.emit();
		hasGlobalFocus = false;
		foreach (child; _children)
			child.handleUnfocus();
	}

	void handleUnhover()
	{
		onUnhover.emit();
		hadHover = false;
	}

	void handleClose()
	{
		onClose.emit();
	}

	void handleKeyDown(int scancode, int mods, Key key, int repeats)
	{
		onKeyDown.emit(scancode, mods, key, repeats);
	}

	void handleKeyUp(int scancode, int mods, Key key)
	{
		onKeyUp.emit(scancode, mods, key);
	}

	void handleTextInput(string text)
	{
		onTextInput.emit(text);
	}

	bool handleMouseMove(int x, int y)
	{
		if (!parent || x > computedRectangle.x && x <= computedRectangle.x + computedRectangle.w
				&& y > computedRectangle.y && y <= computedRectangle.y + computedRectangle.h)
		{
			foreach_reverse (child; _children)
				if (child.handleMouseMove(x, y))
				{
					if (hadHover)
						handleUnhover();
					return true;
				}
			hadHover = true;
			onMouseMove.emit(x - computedRectangle.x, y - computedRectangle.y);
			return true;
		}
		else
		{
			if (hadHover)
				handleUnhover();
			return false;
		}
	}

	bool handleMouseDown(int x, int y, MouseButton button, int clicks)
	{
		if (!parent || x > computedRectangle.x && x <= computedRectangle.x + computedRectangle.w
				&& y > computedRectangle.y && y <= computedRectangle.y + computedRectangle.h)
		{
			foreach_reverse (child; _children)
				if (child.handleMouseDown(x, y, button, clicks))
				{
					if (hadHover)
						handleUnhover();
					return true;
				}
			onMouseDown.emit(x - computedRectangle.x, y - computedRectangle.y, button, clicks);
			return true;
		}
		else
		{
			if (hadHover)
				handleUnhover();
			return false;
		}
	}

	bool handleMouseUp(int x, int y, MouseButton button)
	{
		if (!parent || x > computedRectangle.x && x <= computedRectangle.x + computedRectangle.w
				&& y > computedRectangle.y && y <= computedRectangle.y + computedRectangle.h)
		{
			foreach_reverse (child; _children)
				if (child.handleMouseUp(x, y, button))
				{
					if (hadHover)
						handleUnhover();
					return true;
				}
			onMouseUp.emit(x - computedRectangle.x, y - computedRectangle.y, button);
			return true;
		}
		else
		{
			if (hadHover)
				handleUnhover();
			return false;
		}
	}

	void handleScroll(int scrollX, int scrollY)
	{
		onScroll.emit(scrollX, scrollY);
	}

	void handleDropFile(string filename)
	{
		onDropFile.emit(filename);
	}

	void handleDropText(string text)
	{
		onDropText.emit(text);
	}
}

abstract class FastWidget : RawWidget
{
	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		if (requiresRedraw)
			draw(dest, computedRectangle);
		auto computedPadding = layout!true(padding, hierarchy);
		auto rect = computedRectangle;
		rect.x += computedPadding.x;
		rect.y += computedPadding.y;
		rect.w -= computedPadding.x + computedPadding.right;
		rect.h -= computedPadding.y + computedPadding.bottom;
		if (overflow != Overflow.hidden || (rect.w > 0 && rect.h > 0))
		{
			hierarchy ~= rect;
			foreach (child; _children)
			{
				child.computedRectangle = layout(child.rectangle, hierarchy, Overflow.hidden);
				child.finalDraw(dest, hierarchy);
			}
		}
	}

	abstract void draw(ref RenderTarget dest, Container mask);
}

abstract class ManagedWidget : RawWidget
{
	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		if (computedRectangle.w > 0 && computedRectangle.h > 0 && shouldRedraw)
		{
			RenderTarget img;
			img.w = computedRectangle.w;
			img.h = computedRectangle.h;
			img.pixels = new ubyte[img.w * img.h * 4];
			draw(img);
			img.copyTo(dest, computedRectangle.x, computedRectangle.y);
			auto computedPadding = .layout!true(padding, hierarchy);
			auto rect = computedRectangle;
			rect.x += computedPadding.x;
			rect.y += computedPadding.y;
			rect.w -= computedPadding.x + computedPadding.right;
			rect.h -= computedPadding.y + computedPadding.bottom;
			hierarchy ~= rect;
			foreach (child; _children)
			{
				child.computedRectangle = layout(child.rectangle, hierarchy, Overflow.hidden);
				child.computedRectangle.x -= rect.x;
				child.computedRectangle.y -= rect.y;
				child.finalDraw(dest, hierarchy);
				child.computedRectangle.x += rect.x;
				child.computedRectangle.y += rect.y;
			}
		}
	}

	abstract void draw(ref RenderTarget dest);
}

// Layout

abstract class Layout : RawWidget
{
	override bool isTransparent() const @property
	{
		return true;
	}

	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		if (!shouldRedraw)
			return;
		auto computedPadding = .layout!true(padding, hierarchy);
		auto rect = computedRectangle;
		rect.x += computedPadding.x;
		rect.y += computedPadding.y;
		rect.w -= computedPadding.x + computedPadding.right;
		rect.h -= computedPadding.y + computedPadding.bottom;
		hierarchy ~= rect;
		void*[] pre;
		foreach (i, child; _children)
			pre ~= preLayout(i, child, hierarchy);
		prepareLayout(hierarchy, pre);
		foreach (i, child; _children)
		{
			layout(i, child, hierarchy, pre[i]);
			child.finalDraw(dest, hierarchy);
		}
	}

	abstract void prepareLayout(Container[] hierarchy, void*[] preparation);

	void* preLayout(size_t i, ref RawWidget widget, Container[] hierarchy)
	{
		return null;
	}

	abstract void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass);
}

class FloatingLayout : Layout
{
	override void prepareLayout(Container[] hierarchy, void*[] preparation)
	{
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		widget.computedRectangle = .layout(widget.rectangle, hierarchy);
	}
}

class CenterLayout : Layout
{
	override void prepareLayout(Container[] hierarchy, void*[] preparation)
	{
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		auto rect = .layout(widget.rectangle, hierarchy);
		widget.computedRectangle = Container((computedRectangle.w - rect.w) / 2 + rect.x,
				(computedRectangle.h - rect.h) / 2 + rect.y, rect.w, rect.h);
	}
}

class LinearLayout : Layout
{
	enum Direction
	{
		horizontal,
		vertical,
		horizontalReverse,
		verticalReverse
	}

	override void prepareLayout(Container[] hierarchy, void*[] preparation)
	{
		x = y = curOrtho = maxOrtho = maxOrthoMargin = lastMargin = 0;
		final switch (direction)
		{
		case Direction.horizontal:
		case Direction.vertical:
		case Direction.verticalReverse:
			break;
		case Direction.horizontalReverse:
			x = computedRectangle.w;
			break;
		}
		first = true;
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		auto rect = hierarchy[$ - 1];
		auto size = .layout(widget.rectangle, hierarchy);
		auto margin = .layout!true(widget.margin, hierarchy);
		int xMod, yMod;
		final switch (direction)
		{
		case Direction.horizontal:
			auto effMargin = max(lastMargin, margin.x);
			lastMargin = margin.right;
			x += effMargin;
			y = curOrtho + margin.y;
			maxOrtho = max(maxOrtho, margin.bottom + size.h);
			xMod = size.w;
			if (x + xMod + lastMargin > rect.w && !first)
			{
				x = margin.x;
				y += maxOrtho;
				curOrtho += maxOrtho;
				maxOrtho = 0;
			}
			break;
		case Direction.horizontalReverse:
			auto effMargin = max(lastMargin, margin.right);
			lastMargin = margin.x;
			x -= effMargin + size.w;
			y = curOrtho + margin.y;
			maxOrtho = max(maxOrtho, margin.bottom + size.h);
			if (x - lastMargin < 0 && !first)
			{
				x = rect.w - effMargin - size.w;
				y += maxOrtho;
				curOrtho += maxOrtho;
				maxOrtho = 0;
			}
			break;
		case Direction.vertical:
			auto effMargin = max(lastMargin, margin.y);
			lastMargin = margin.bottom;
			y += effMargin;
			x = curOrtho + margin.x;
			maxOrtho = max(maxOrtho, margin.right + size.w);
			yMod = size.h;
			if (y + yMod + lastMargin > rect.h && !first)
			{
				y = margin.y;
				x += maxOrtho;
				curOrtho += maxOrtho;
				maxOrtho = 0;
			}
			break;
		case Direction.verticalReverse:
			auto effMargin = max(lastMargin, margin.bottom);
			lastMargin = margin.y;
			y -= effMargin + size.h;
			x = curOrtho + margin.x;
			maxOrtho = max(maxOrtho, margin.right + size.w);
			if (y - lastMargin < 0 && !first)
			{
				y = rect.h - effMargin - size.h;
				x += maxOrtho;
				curOrtho += maxOrtho;
				maxOrtho = 0;
			}
			break;
		}
		widget.computedRectangle = Container(rect.x + x, rect.y + y, size.w, size.h);
		x += xMod;
		y += yMod;
		first = false;
	}

	Direction direction;

private:
	int x, y;
	int offX, offY;
	int curOrtho, maxOrtho;
	int lastMargin, maxOrthoMargin;
	bool first;
}
