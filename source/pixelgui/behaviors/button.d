module pixelgui.behaviors.button;

import pixelgui.constants;
import pixelgui.render;
import pixelgui.widget;

import tinyevent;

abstract class ButtonBehavior(BaseWidget : RawWidget) : BaseWidget
{
	bool isHovered;
	bool isMouseActive;
	bool isKeyboardActive;

	bool canReceiveFocus = true;

	Event!() onClick;

	this()
	{
		onMouseMove ~= &mouseMove;
		onUnhover ~= &unhover;
		onMouseDown ~= &mouseDown;
		onMouseUp ~= &mouseUp;
		onKeyDown ~= &keyDown;
		onKeyUp ~= &keyUp;
	}

	bool isActive() const @property
	{
		return isMouseActive || isKeyboardActive;
	}

	void mouseMove(int, int)
	{
		if (!isHovered)
		{
			redraw();
			isHovered = true;
		}
	}

	void unhover()
	{
		if (isHovered)
		{
			isHovered = false;
			redraw();
		}
	}

	void mouseDown(int, int, MouseButton button, int)
	{
		if (button == MouseButton.left)
		{
			isMouseActive = true;
			redraw();
		}
	}

	void mouseUp(int, int, MouseButton button)
	{
		if (button == MouseButton.left)
		{
			if (isHovered && isMouseActive)
				onClick.emit();
			isMouseActive = false;
			redraw();
		}
	}

	void keyDown(int, int, Key key, int)
	{
		if (isFocused && (key == Key.enter || key == Key.space))
		{
			isKeyboardActive = true;
			redraw();
		}
	}

	void keyUp(int, int, Key key)
	{
		if (key == Key.enter || key == Key.space)
		{
			if (isFocused && isKeyboardActive)
				onClick.emit();
			isKeyboardActive = false;
			redraw();
		}
	}
}
