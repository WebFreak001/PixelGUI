module pixelgui.layouts.linear;

import std.algorithm;

import pixelgui.widget;

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
			if (x + xMod + lastMargin > rect.w && !first && wrap)
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
			if (x - lastMargin < 0 && !first && wrap)
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
			if (y + yMod + lastMargin > rect.h && !first && wrap)
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
			if (y - lastMargin < 0 && !first && wrap)
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
	bool wrap = true;

private:
	int x, y;
	int offX, offY;
	int curOrtho, maxOrtho;
	int lastMargin, maxOrthoMargin;
	bool first;
}
