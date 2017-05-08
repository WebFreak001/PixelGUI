module pixelgui.behaviors.button;

import pixelgui.constants;
import pixelgui.render;
import pixelgui.widget;

import std.stdio;

abstract class ButtonBehavior(BaseWidget : RawWidget) : BaseWidget
{
	bool isHovered;
	bool isMouseActive;
	bool isKeyboardActive;

	bool canReceiveFocus = true;

	bool isActive() const @property
	{
		return isMouseActive || isKeyboardActive;
	}

	void onClick()
	{
	}

	override void onMouseMove(int, int)
	{
		if (!isHovered)
		{
			redraw();
			isHovered = true;
		}
	}

	override void onUnhover()
	{
		if (isHovered)
		{
			isHovered = false;
			redraw();
		}
	}

	override void onMouseDown(int, int, MouseButton button, int)
	{
		if (button == MouseButton.left)
		{
			isMouseActive = true;
			redraw();
		}
	}

	override void onMouseUp(int, int, MouseButton button)
	{
		if (button == MouseButton.left)
		{
			if (isHovered && isMouseActive)
				onClick();
			isMouseActive = false;
			redraw();
		}
	}

	override void onKeyDown(int, int, Key key, int)
	{
		if (isFocused && (key == Key.enter || key == Key.space))
		{
			isKeyboardActive = true;
			redraw();
		}
	}

	override void onKeyUp(int, int, Key key)
	{
		if (key == Key.enter || key == Key.space)
		{
			if (isFocused && isKeyboardActive)
				onClick();
			isKeyboardActive = false;
			redraw();
		}
	}
}
