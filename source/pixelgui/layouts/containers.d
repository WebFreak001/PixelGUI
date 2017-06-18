module pixelgui.layouts.containers;

import pixelgui.widget;

class FloatingLayout : Layout
{
	override void prepareLayout(Container[] hierarchy, void*[] preparation)
	{
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		widget.computedRectangle = .layout(widget.rectangle, hierarchy);
	}
}

class CenterLayout : Layout
{
	override void prepareLayout(Container[] hierarchy, void*[] preparation)
	{
	}

	override void layout(size_t i, ref RawWidget widget, Container[] hierarchy, void* prepass)
	{
		auto rect = .layout(widget.rectangle, hierarchy);
		widget.computedRectangle = Container((computedRectangle.w - rect.w) / 2 + rect.x,
				(computedRectangle.h - rect.h) / 2 + rect.y, rect.w, rect.h);
	}
}