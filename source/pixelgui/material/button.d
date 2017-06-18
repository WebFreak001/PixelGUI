module pixelgui.material.button;

import pixelgui.render;
import pixelgui.widget;

import pixelgui.behaviors.button;

import pixelgui.material.color;

struct MaterialButtonColor
{
	Color normalColor = MaterialColors.gray300;
	Color pressedColor = col!"D5D5D5";
	Color focusShade = col!"0000001F";
}

MaterialButtonColor makeButtonColor(string colorName)()
{
	MaterialButtonColor ret;
	static if (__traits(compiles, mixin("MaterialColors." ~ colorName ~ "500")))
	{
		ret.normalColor = mixin("MaterialColors." ~ colorName ~ "500");
		ret.pressedColor = mixin("MaterialColors." ~ colorName ~ "700");
	}
	else
	{
		ret.normalColor = mixin("MaterialColors." ~ colorName);
		ret.pressedColor = blend(col!"20202020", mixin("MaterialColors." ~ colorName));
	}
	return ret;
}

/// Material design style button
class MaterialButton : ButtonBehavior!FastWidget
{
	/// Color scheme for the button
	mixin RedrawProperty!(MaterialButtonColor, "color", makeButtonColor!materialDefaultPrimaryName);
	/// Text color
	mixin RedrawInheritableProperty!(Color, "foreground", "Color");
	/// If true, background will be filled with color
	mixin RedrawProperty!(bool, "raised", true);

	this()
	{
		super();
		foreground = HTMLColors.white;
		setStringProperty("fontStyle", "Bold");
	}

	override bool isTransparent() const @property
	{
		return !raised || color.normalColor[3] != 0xFF
			|| color.pressedColor[3] != 0xFF || color.focusShade[3] != 0xFF;
	}

	override void draw(ref RenderTarget dest, Container mask)
	{
		Color background;
		if (isHovered || isFocused)
		{
			if (isActive)
				background = blend(color.focusShade, raised ? color.pressedColor : ActiveBackgroundBase);
			else
				background = blend(color.focusShade, raised ? color.normalColor : HoveredBackgroundBase);
		}
		else
			background = raised ? color.normalColor : RegularBackgroundBase;
		if (mask.w < 4 || mask.h < 4)
			dest.fillRect(mask.x, mask.y, mask.w, mask.h, background);
		else
		{
			dest.fillRect(mask.x + 1, mask.y, mask.w - 2, 1, background);
			dest.fillRect(mask.x, mask.y + 1, mask.w, mask.h - 2, background);
			dest.fillRect(mask.x + 1, mask.y + mask.h - 1, mask.w - 2, 1, background);
		}
		if (raised)
			setColorProperty("textColor", foreground);
		else
			setColorProperty("textColor", color.normalColor);
	}
}

private enum Color RegularBackgroundBase = [0, 0, 0, 0];
private enum Color ActiveBackgroundBase = [0, 0, 0, 0x20];
private enum Color HoveredBackgroundBase = [0, 0, 0, 0x10];