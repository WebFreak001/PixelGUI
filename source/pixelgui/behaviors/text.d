module pixelgui.behaviors.text;

import pixelgui.render;
import pixelgui.widget;

import std.algorithm;
import std.string;

import tinyevent;

struct TextPart(FontData)
{
	string text;
	Color color = col!"FFFFFF00"; // reset color
	Length size = fitContent;
	FontData font;
	string fontStyle;
	float lineHeight = 1;
}

enum TextAlignment : ubyte
{
	topLeft,
	topCenter,
	topRight,
	middleLeft,
	middleCenter,
	middleRight,
	bottomLeft,
	bottomCenter,
	bottomRight
}

bool isLeftAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.topLeft
		|| alignment == TextAlignment.middleLeft || alignment == TextAlignment.bottomLeft;
}

bool isCenterAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.topCenter
		|| alignment == TextAlignment.middleCenter || alignment == TextAlignment.bottomCenter;
}

bool isRightAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.topRight
		|| alignment == TextAlignment.middleRight || alignment == TextAlignment.bottomRight;
}

bool isTopAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.topLeft
		|| alignment == TextAlignment.topCenter || alignment == TextAlignment.topRight;
}

bool isMiddleAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.middleLeft
		|| alignment == TextAlignment.middleCenter || alignment == TextAlignment.middleRight;
}

bool isBottomAlign(TextAlignment alignment)
{
	return alignment == TextAlignment.bottomLeft
		|| alignment == TextAlignment.bottomCenter || alignment == TextAlignment.bottomRight;
}

abstract class TextBehavior(BaseWidget : RawWidget, FontData) : BaseWidget
{
	mixin RedrawProperty!(TextPart!FontData[], "parts");
	mixin RedrawProperty!(TextAlignment, "textAlignment");
	mixin RedrawInheritableProperty!(Color, "textColor", "Color");
	mixin RedrawInheritableProperty!(Length, "fontSize");
	mixin RedrawInheritableProperty!(string, "fontStyle");
	mixin RedrawProperty!(FontData, "font");

	string text() const @property
	{
		return parts.map!"a.text".join();
	}

	string text(string val) @property
	{
		parts = [TextPart!FontData(val)];
		return val;
	}

	TextPart!FontData[][] partsByLines()
	{
		TextPart!FontData[][] ret;
		ret.length = 1;
		foreach (part; _parts)
		{
			ptrdiff_t index;
			while ((index = part.text.indexOf('\n')) != -1)
			{
				TextPart!FontData modPart = part;
				modPart.text = part.text[0 .. index];
				part.text = part.text[index + 1 .. $];
				ret[$ - 1] ~= modPart; // even include empty strings for proper line height
				ret.length++;
			}
			ret[$ - 1] ~= part;
		}
		return ret;
	}
}
