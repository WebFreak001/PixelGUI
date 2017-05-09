import pixelgui;
import pixelgui.material;
import pixelgui.sdl;

import std.stdio;

void main()
{
	auto gui = makePixelGUI;
	auto window = gui.newRootWidget!CenterLayout(853, 480);

	auto colorPalette = new LinearLayout();
	colorPalette.rectangle = Rectangle.size(19 * 20 + 10, 14 * 20 + 10);
	colorPalette.padding = Rectangle(4.px);
	colorPalette.direction = LinearLayout.Direction.vertical;

	window.addChild(colorPalette);

	void addButton(string color)()
	{
		auto button = new MaterialButton();
		button.rectangle = Rectangle.size(18, 18);
		button.padding = Rectangle(0.px);
		button.margin = Rectangle(2.px);
		button.color = makeButtonColor!color;
		button.onClick ~= () {
			writeln(color, ": ", button.color.normalColor.toColorHexString);
		};
		colorPalette.addChild(button);
	}

	foreach (color; __traits(allMembers, MaterialColors))
	{
		static if (color != "transparent") // move transparent to end for nicer alignment
			addButton!color;
	}
	addButton!"transparent";

	gui.runWithSDL(window);
}
