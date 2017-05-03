module pixelgui.widgets.button;

import pixelgui.render;
import pixelgui.widget;

import std.stdio;

class Button : ManagedWidget
{
	override void draw(ref RenderTarget dest)
	{
		writeln("Drawing");
		dest.clearFast(HTMLColors.aqua);
	}
}
