module pixelgui.behaviors.button;

import pixelgui.constants;
import pixelgui.render;
import pixelgui.widget;

import tinyevent;

abstract class ButtonBehavior(BaseWidget : RawWidget) : BaseWidget
{
	mixin RedrawProperty!(bool, "isHovered");
	mixin RedrawProperty!(bool, "isMouseActive");
	mixin RedrawProperty!(bool, "isKeyboardActive");

	bool _canReceiveFocus = true;

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
			isHovered = true;
	}

	void unhover()
	{
		if (isHovered)
			isHovered = false;
	}

	void mouseDown(int, int, MouseButton button, int)
	{
		if (button == MouseButton.left)
			isMouseActive = true;
	}

	void mouseUp(int, int, MouseButton button)
	{
		if (button == MouseButton.left)
		{
			if (isHovered && isMouseActive)
				onClick.emit();
			isMouseActive = false;
		}
	}

	void keyDown(int, int, Key key, int)
	{
		if (isFocused && (key == Key.enter || key == Key.space))
			isKeyboardActive = true;
	}

	void keyUp(int, int, Key key)
	{
		if (key == Key.enter || key == Key.space)
		{
			if (isFocused && isKeyboardActive)
				onClick.emit();
			isKeyboardActive = false;
		}
	}
}
