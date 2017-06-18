module pixelgui.widget;

import pixelgui.constants;
import pixelgui.render;

import tinyevent;

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

struct PropertyStore
{
	Length[string] lengthProperties;
	Color[string] colorProperties;
	string[string] stringProperties;
}

mixin template RedrawProperty(T, string name, T defaultValue = T.init)
{
	mixin("auto " ~ name ~ "() const @property { return _" ~ name ~ "; }");
	mixin("T " ~ name ~ "(T val) @property { _" ~ name ~ " = val; redraw(); return _" ~ name ~ "; }");
	mixin("T _" ~ name ~ " = defaultValue;");
}

mixin template RectangleProperties(string p)
{
	mixin("auto " ~ p ~ "Top() const @property { return _" ~ p ~ ".top; }");
	mixin("auto " ~ p ~ "Right() const @property { return _" ~ p ~ ".right; }");
	mixin("auto " ~ p ~ "Bottom() const @property { return _" ~ p ~ ".bottom; }");
	mixin("auto " ~ p ~ "Left() const @property { return _" ~ p ~ ".left; }");

	mixin("auto " ~ p ~ "Top(Length v) @property { _" ~ p ~ ".top = v; redraw(); return v; }");
	mixin("auto " ~ p ~ "Right(Length v) @property { _" ~ p ~ ".right = v; redraw(); return v; }");
	mixin("auto " ~ p ~ "Bottom(Length v) @property { _" ~ p ~ ".bottom = v; redraw(); return v; }");
	mixin("auto " ~ p ~ "Left(Length v) @property { _" ~ p ~ ".left = v; redraw(); return v; }");

	mixin("auto " ~ p ~ "Top(int v) @property { _" ~ p ~ ".top = v.px; redraw(); return v.px; }");
	mixin("auto " ~ p ~ "Right(int v) @property { _" ~ p ~ ".right = v.px; redraw(); return v.px; }");
	mixin("auto " ~ p ~ "Bottom(int v) @property { _" ~ p ~ ".bottom = v.px; redraw(); return v.px; }");
	mixin("auto " ~ p ~ "Left(int v) @property { _" ~ p ~ ".left = v.px; redraw(); return v.px; }");
}

import std.string : capitalize;

mixin template RedrawInheritableProperty(T, string name, string typeName = T.stringof.capitalize)
{
	mixin("auto " ~ name ~ "() const @property { return get" ~ typeName ~ "Property(name); }");
	mixin(
			"T " ~ name ~ "(T val) @property { set" ~ typeName
			~ "Property(name, val); redraw(); return val; }");
}

private string generatePropertyShortcuts(T...)()
{
	string ret;
	foreach (arg; T)
	{
		char[] lowercase = arg.capitalize.dup;
		lowercase[0] -= 'A' - 'a';
		ret ~= `auto get` ~ arg.capitalize ~ `Property(string name) const
		{
			auto ptr = name in extraProperties.` ~ lowercase
			~ `Properties;
			if (ptr)
				return *ptr;
			else if (parent)
				return parent.get` ~ arg.capitalize ~ `Property(name);
			else
				return typeof(return).init;
		}

		void set` ~ arg.capitalize
			~ `Property(string name, ` ~ arg ~ ` value)
		{
			extraProperties.` ~ lowercase
			~ `Properties[name] = value;
		}`;
	}
	return ret;
}

abstract class RawWidget
{
	PropertyStore extraProperties;
	mixin(generatePropertyShortcuts!("Length", "Color", "string"));

	mixin RedrawProperty!(Rectangle, "rectangle", Rectangle.full);
	mixin RedrawProperty!(Rectangle, "margin");
	mixin RectangleProperties!("margin");
	mixin RedrawProperty!(Rectangle, "padding");
	mixin RectangleProperties!("padding");
	RawWidget parent;
	mixin RedrawProperty!(RawWidget[], "children");
	mixin RedrawProperty!(Overflow, "overflow");
	bool requiresRedraw = true;
	mixin RedrawProperty!(bool, "hasLocalFocus");
	mixin RedrawProperty!(bool, "hasGlobalFocus");
	mixin RedrawProperty!(bool, "canReceiveFocus");
	bool hadHover = false;
	mixin RedrawProperty!(bool, "opaqueHover");

	Container computedRectangle;
	Container[] hierarchy;

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

	void clearChildren()
	{
		_children.length = 0;
		redraw();
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
				if (child.handleMouseMove(x, y) && child.opaqueHover)
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
				if (child.handleMouseDown(x, y, button, clicks) && child.opaqueHover)
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
				if (child.handleMouseUp(x, y, button) && child.opaqueHover)
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
		this.hierarchy = hierarchy;
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
		this.hierarchy = hierarchy;
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
		this.hierarchy = hierarchy;
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
