import pixelgui;
import pixelgui.fontconfig;
import pixelgui.freetype;
import pixelgui.material;
import pixelgui.sdl;

import std.random;
import std.stdio;

import imageformats;

FreeTypeFontFamily font;

void text(MaterialButton button, string text)
{
	foreach (child; button.children)
	{
		if (cast(TextWidget) child)
		{
			(cast(TextWidget) child).text = text;
			return;
		}
	}
	auto content = new TextWidget();
	content.font = font;
	content.text = text;
	content.rectangle = Rectangle.full;
	button.addChild(content);
}

Solid wrapBackground(RawWidget widget, Color background)
{
	auto solid = new Solid;
	solid.rectangle = widget.rectangle;
	widget.rectangle = Rectangle.full;
	solid.backgroundColor = background;
	solid.addChild(widget);
	return solid;
}

Bitmap bitmap;
BitmapData[] images;
size_t imageIndex;
int slideshowInterval;

void offsetImage(byte offset)
{
	imageIndex = (imageIndex + images.length + offset) % images.length;
	bitmap.bitmap = images[imageIndex];
}

void main(string[] args)
{
	if (args.length)
		args = args[1 .. $];

	auto gui = makePixelGUI;
	auto window = gui.newRootWidget!CenterLayout(853, 480);
	window.backgroundColor = col!"202020";

	font = FreeTypeFontFamily.fromFiles(fontFamilyByName("Roboto"));

	auto sidebar = new LinearLayout;
	sidebar.direction = LinearLayout.Direction.vertical;
	sidebar.rectangle = Rectangle.size(200.px, 100.percent);
	sidebar.padding = Rectangle(4.px);
	sidebar.wrap = false;

	auto btnSlideshow = new MaterialButton;
	btnSlideshow.color = MaterialButtonColor(col!"FFFFFF");
	btnSlideshow.raised = false;
	btnSlideshow.padding = Rectangle(12.px);
	btnSlideshow.text = "Start Slideshow";
	btnSlideshow.marginBottom = 4.px;
	btnSlideshow.onClick ~= () {
		if (slideshowInterval)
		{
			btnSlideshow.text = "Start Slideshow";
			clearInterval(slideshowInterval);
			slideshowInterval = 0;
		}
		else
		{
			btnSlideshow.text = "Stop Slideshow";
			offsetImage(1);
			slideshowInterval = setInterval(() { offsetImage(1); }, 8000);
		}
	};
	sidebar.addChild(btnSlideshow);

	auto btnNext = new MaterialButton;
	btnNext.color = MaterialButtonColor(col!"FFFFFF");
	btnNext.raised = false;
	btnNext.padding = Rectangle(12.px);
	btnNext.text = "Next";
	btnNext.marginBottom = 4.px;
	btnNext.onClick ~= () {
		if (slideshowInterval)
			resetInterval(slideshowInterval);
		offsetImage(1);
	};
	sidebar.addChild(btnNext);

	auto btnPrev = new MaterialButton;
	btnPrev.color = MaterialButtonColor(col!"FFFFFF");
	btnPrev.raised = false;
	btnPrev.padding = Rectangle(12.px);
	btnPrev.text = "Previous";
	btnPrev.marginBottom = 4.px;
	btnPrev.onClick ~= () {
		if (slideshowInterval)
			resetInterval(slideshowInterval);
		offsetImage(-1);
	};
	sidebar.addChild(btnPrev);

	bitmap = new Bitmap;
	bitmap.stretchWidth = SizingMode.centerAlign;
	bitmap.stretchHeight = SizingMode.centerAlign;
	foreach (file; args)
	{
		try
		{
			auto image = read_image(file);
			images ~= BitmapData(image.pixels, image.w, image.h,
					image.c == ColFmt.RGBA ? BitmapFormat.RGBA : BitmapFormat.RGB);
		}
		catch (Exception)
		{
			stderr.writeln("Could not read image file ", file);
		}
	}
	if (images.length == 0)
	{
		ubyte[] noise = new ubyte[1024 * 1024 * 4];
		foreach (ref b; noise)
			b = uniform(ubyte.min, ubyte.max);
		images ~= BitmapData(noise, 1024, 1024, BitmapFormat.RGBA);
	}
	bitmap.bitmap = images[imageIndex];
	window.addChild(bitmap);

	auto overlay = new LinearLayout;
	overlay.wrap = false;
	// because transparency basically needs to rerender everything, a transparent widget
	// all the way up to the root widget will update very slowly, performance will drastically
	// improve for changes if transparent objects have an opaque object as parent
	overlay.addChild(wrapBackground(sidebar, [0, 0, 0, 0x20]));
	window.addChild(overlay);

	gui.runWithSDL(window);
}
