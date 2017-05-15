import pixelgui;
import pixelgui.fontconfig;
import pixelgui.freetype;
import pixelgui.material;
import pixelgui.sdl;

import std.stdio;

void main()
{
	auto gui = makePixelGUI;
	auto window = gui.newRootWidget!CenterLayout(853, 480);

	auto font = FreeTypeFontFamily.fromFiles(fontFamilyByName("Roboto"));

	auto colorPalette = new LinearLayout();
	colorPalette.rectangle = Rectangle.size(19 * 20 + 10, 14 * 20 + 10);
	colorPalette.padding = Rectangle(4.px);
	colorPalette.direction = LinearLayout.Direction.vertical;

	auto text = new TextWidget();
	text.font = font;
	text.fontSize = 0.7.em;
	text.text = import("app.d");
	text.rectangle = Rectangle.full;
	window.addChild(text);

	window.addChild(colorPalette);

	auto overlay = new MaterialButton();
	overlay.rectangle = Rectangle.size(100, 56);
	overlay.padding = Rectangle(16.px);
	auto content = new TextWidget();
	content.font = font;
	content.text = "Click Me";
	content.rectangle = Rectangle.full;
	overlay.addChild(content);
	window.addChild(overlay);

	bool isFG;
	void addButton(string color)()
	{
		auto button = new MaterialButton();
		button.rectangle = Rectangle.size(18, 18);
		button.padding = Rectangle(0.px);
		button.margin = Rectangle(2.px);
		button.color = makeButtonColor!color;
		button.onClick ~= () {
			isFG = !isFG;
			if (isFG)
				text.textColor = button.color.normalColor;
			else
				window.backgroundColor = button.color.normalColor;
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
