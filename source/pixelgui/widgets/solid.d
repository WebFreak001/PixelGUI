module pixelgui.widgets.solid;

import pixelgui.render;
import pixelgui.widget;

/// Solid colored widget for putting backgrounds and borders
class Solid : FastWidget
{
	/// Text color
	mixin RedrawProperty!(Color, "backgroundColor");

	override bool isTransparent() const @property
	{
		return backgroundColor[3] != 0xFF;
	}

	override void draw(ref RenderTarget dest, Container mask)
	{
		dest.fillRect(mask.x, mask.y, mask.w, mask.h, backgroundColor);
	}
}
