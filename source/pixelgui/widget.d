module pixelgui.widget;

import pixelgui.constants;
import pixelgui.render;

import std.math;

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
		em
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

Container layout(Rectangle r, Container[] hierarchy, Overflow overflow = Overflow.shown)
{
	int top = cast(int) round(r.top.compute(hierarchy, true));
	int right = cast(int) round(r.right.compute(hierarchy, false));
	int bottom = cast(int) round(r.bottom.compute(hierarchy, true));
	int left = cast(int) round(r.left.compute(hierarchy, false));
	return hierarchy[$ - 1].push(top, right, bottom, left, overflow);
}

abstract class RawWidget
{
	Rectangle rectangle = Rectangle.full;
	Rectangle margin;
	Rectangle padding;
	RawWidget[] children;
	Overflow overflow;
	bool requiresRedraw = true;

	Rectangle computedRectangle = Rectangle.full;

	abstract void finalDraw(ref RenderTarget dest, Container[] hierarchy);

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
		requiresRedraw = true;
		foreach (ref child; children)
			child.redraw();
	}

	void clearDrawQueue()
	{
		requiresRedraw = false;
		foreach (ref child; children)
			child.clearDrawQueue();
	}

	void addChild(RawWidget widget)
	{
		widget.redraw();
		children ~= widget;
	}

	void onResize(int width, int height)
	{
	}

	void onFocus()
	{
	}

	void onUnfocus()
	{
	}

	void onUnhover()
	{
	}

	void onClose()
	{
	}

	void onKeyDown(int scancode, int mods, int key, int repeats)
	{
	}

	void onKeyUp(int scancode, int mods, int key)
	{
	}

	void onTextInput(string text)
	{
	}

	void onMouseMove(int x, int y)
	{
	}

	void onMouseDown(int x, int y, MouseButton button, int clicks)
	{
	}

	void onMouseUp(int x, int y, MouseButton button)
	{
	}

	void onScroll(int scrollX, int scrollY)
	{
	}

	void onDropFile(string filename)
	{
	}

	void onDropText(string text)
	{
	}
}

abstract class FastWidget : RawWidget
{
	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		auto size = layout(computedRectangle, hierarchy, overflow);
		if (requiresRedraw)
			draw(dest, size);
		auto computedPadding = layout(padding, hierarchy);
		size.x += computedPadding.x;
		size.y += computedPadding.y;
		size.w -= computedPadding.w;
		size.h -= computedPadding.h;
		if (overflow != Overflow.hidden || (size.w > 0 && size.h > 0))
		{
			hierarchy ~= size;
			foreach (child; children)
				child.finalDraw(dest, hierarchy);
		}
	}

	abstract void draw(ref RenderTarget dest, Container mask);
}

abstract class ManagedWidget : RawWidget
{
	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		auto size = layout(computedRectangle, hierarchy, overflow);
		if (size.w > 0 && size.h > 0 && shouldRedraw)
		{
			RenderTarget img;
			img.w = size.w;
			img.h = size.h;
			img.pixels = new ubyte[img.w * img.h * 4];
			draw(img);
			img.copyTo(dest, size.x, size.y);
			hierarchy ~= size;
			foreach (child; children)
				child.finalDraw(dest, hierarchy);
		}
	}

	abstract void draw(ref RenderTarget dest);
}

// Layout

abstract class Layout : RawWidget
{
	override void finalDraw(ref RenderTarget dest, Container[] hierarchy)
	{
		if (!shouldRedraw)
			return;
		auto size = .layout(computedRectangle, hierarchy, overflow);
		hierarchy ~= size;
		void*[] pre;
		foreach (i, child; children)
			pre ~= preLayout(i, child, hierarchy);
		prepareLayout(hierarchy, pre);
		foreach (i, child; children)
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
		widget.computedRectangle = widget.rectangle;
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
		x = y = maxH = lastMargin = 0;
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		auto size = .layout(widget.rectangle, hierarchy);
		auto margin = .layout(widget.margin, hierarchy);
		final switch (direction)
		{
		case Direction.horizontal:
			break;
		case Direction.vertical:
			break;
		case Direction.horizontalReverse:
			break;
		case Direction.verticalReverse:
			break;
		}
	}

	Direction direction;

private:
	int x, y;
	int offX, offY;
	int maxH;
	int lastMargin;
}
