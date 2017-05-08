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
	MaterialButtonColor color = makeButtonColor!materialDefaultPrimaryName;
	/// If true, background will be filled with color
	bool raised = true;

	override bool isTransparent() const @property
	{
		return color.normalColor[3] != 0xFF || color.pressedColor[3] != 0xFF
			|| color.focusShade[3] != 0xFF;
	}

	override void draw(ref RenderTarget dest, Container mask)
	{
		Color background;
		if (isHovered || isFocused)
			background = blend(color.focusShade, color.normalColor);
		else if (isActive)
			background = color.pressedColor;
		else
			background = color.normalColor;
		if (raised)
		{
			if (mask.w < 4 || mask.h < 4)
				dest.fillRect(mask.x, mask.y, mask.w, mask.h, background);
			else
			{
				dest.fillRect(mask.x + 1, mask.y, mask.w - 2, 1, background);
				dest.fillRect(mask.x, mask.y + 1, mask.w, mask.h - 2, background);
				dest.fillRect(mask.x + 1, mask.y + mask.h - 1, mask.w - 2, 1, background);
			}
		}
	}
}
