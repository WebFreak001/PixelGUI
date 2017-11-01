module pixelgui.widgets.bitmap;

import pixelgui.render;
import pixelgui.widget;

import std.algorithm;
import std.math;

/// Supported bitmap formats
enum BitmapFormat
{
	/// Alpha-premultiplied RGBA data, can be rendered the fastest
	RGBA_PREMULTIPLIED,
	/// RGBA data
	RGBA,
	/// Alpha-premultiplied ARGB data
	ARGB_PREMULTIPLIED,
	/// ARGB data
	ARGB,
	/// Alpha-premultiplied BGRA data
	BGRA_PREMULTIPLIED,
	/// BGRA data
	BGRA,
	/// Alpha-premultiplied ABGR data
	ABGR_PREMULTIPLIED,
	/// ABGR data
	ABGR,
	/// opaque RGB data
	RGB,
	/// opaque BGR data
	BGR,
}

/// Used byte size per pixel for a BitmapFormat.
int pixelSize(BitmapFormat format)
{
	final switch (format)
	{
	case BitmapFormat.RGBA_PREMULTIPLIED:
	case BitmapFormat.RGBA:
	case BitmapFormat.ARGB_PREMULTIPLIED:
	case BitmapFormat.ARGB:
	case BitmapFormat.BGRA_PREMULTIPLIED:
	case BitmapFormat.BGRA:
	case BitmapFormat.ABGR_PREMULTIPLIED:
	case BitmapFormat.ABGR:
		return 4;
	case BitmapFormat.RGB:
	case BitmapFormat.BGR:
		return 3;
	}
}

///
enum SizingMode
{
	/// Put image to the left
	leftAlign,
	/// Put image to the center
	centerAlign,
	/// Put image to the right
	rightAlign,
	/// Always stretch to fit dimension
	stretch,
}

/// Returns true for modes not requiring resizing (leftAlign, centerAlign, rightAlign)
bool isAlignMode(SizingMode s)
{
	return s == SizingMode.leftAlign || s == SizingMode.centerAlign || s == SizingMode.rightAlign;
}

///
enum ClampMode
{
	clamp,
	repeat
}

private int computePosition(SizingMode mode, int image, int max)
{
	final switch (mode)
	{
	case SizingMode.leftAlign:
	case SizingMode.stretch:
		return 0;
	case SizingMode.centerAlign:
		return (max - image) / 2;
	case SizingMode.rightAlign:
		return max - image;
	}
}

private float computeIndex(SizingMode mode, int i, float scale, int outerW, int innerW)
{
	final switch (mode)
	{
	case SizingMode.leftAlign:
		return i;
	case SizingMode.centerAlign:
		return i - (outerW - innerW) * 0.5f;
	case SizingMode.rightAlign:
		return i - outerW + innerW;
	case SizingMode.stretch:
		return i * scale;
	}
}

alias LinearInterpolation = lerpColor;

///
struct BitmapData
{
	ubyte[] data;
	int w, h;
	BitmapFormat format;

	static BitmapData fromRenderTarget(RenderTarget t)
	{
		return BitmapData(t.pixels, t.w, t.h, BitmapFormat.RGBA_PREMULTIPLIED);
	}

	void premultiply()
	{
		switch (format)
		{
		case BitmapFormat.RGBA:
		case BitmapFormat.BGRA:
			for (int i = 0; i < data.length; i += 4)
				data[i .. i + 4] = data[i .. i + 4][0 .. 4].premultiply;
			format--;
			break;
		case BitmapFormat.ARGB:
		case BitmapFormat.ABGR:
			for (int i = 0; i < data.length; i += 4)
				data[i .. i + 4] = data[i .. i + 4][0 .. 4].premultiplyARGB;
			format--;
			break;
		default:
			break;
		}
	}

	/// Returns: a premultiplied color at the exact position in the image.
	/// Throws: `Exception` if out of bounds.
	Color pixelAt(int x, int y) const
	{
		if (x < 0 || y < 0 || x >= w || y >= h)
			throw new Exception("Coordinate out of bounds");
		int s = format.pixelSize;
		int i = (x + y * w) * s;
		auto part = data[i .. i + s];
		final switch (format)
		{
		case BitmapFormat.RGBA_PREMULTIPLIED:
			return part[0 .. 4];
		case BitmapFormat.RGBA:
			return part[0 .. 4].premultiply;
		case BitmapFormat.ARGB_PREMULTIPLIED:
			return [part[1], part[2], part[3], part[0]];
		case BitmapFormat.ARGB:
			return [part[1], part[2], part[3], part[0]].premultiply;
		case BitmapFormat.BGRA_PREMULTIPLIED:
			return [part[2], part[1], part[0], part[3]];
		case BitmapFormat.BGRA:
			return [part[2], part[1], part[0], part[3]].premultiply;
		case BitmapFormat.ABGR_PREMULTIPLIED:
			return [part[3], part[2], part[1], part[0]];
		case BitmapFormat.ABGR:
			return [part[3], part[2], part[1], part[0]].premultiply;
		case BitmapFormat.RGB:
			return [part[0], part[1], part[2], 0xFF];
		case BitmapFormat.BGR:
			return [part[2], part[1], part[0], 0xFF];
		}
	}

	int clampX(int x, ClampMode c) const
	{
		final switch (c)
		{
		case ClampMode.clamp:
			return clamp(x, 0, w - 1);
		case ClampMode.repeat:
			while (x < 0)
				x += w;
			return x % w;
		}
	}

	int clampY(int y, ClampMode c) const
	{
		final switch (c)
		{
		case ClampMode.clamp:
			return clamp(y, 0, h - 1);
		case ClampMode.repeat:
			while (y < 0)
				y += h;
			return y % h;
		}
	}

	/// Params:
	///   interpXFun = the interpolation function to use on the x axis `Color function(Color a, Color b, float t)` 0 <= t <= 1
	///   interpYFun = the interpolation function to use on the y axis `Color function(Color a, Color b, float t)` 0 <= t <= 1
	/// Returns: the interpolated Color at x, y
	Color interpolateAt(alias interpXFun, alias interpYFun)(double x, double y,
			ClampMode xwrap = ClampMode.clamp, ClampMode ywrap = ClampMode.clamp) const
	{
		if (x < 0 || y < 0 || !x.isFinite || !y.isFinite)
			throw new Exception("Invalid float args passed to interpolateAt");
		int xPart = cast(int) trunc(x);
		int yPart = cast(int) trunc(y);
		Color tl, tr, bl, br;
		tl = pixelAt(clampX(xPart, xwrap), clampY(yPart, ywrap));
		tr = pixelAt(clampX(xPart + 1, xwrap), clampY(yPart, ywrap));
		bl = pixelAt(clampX(xPart, xwrap), clampY(yPart + 1, ywrap));
		br = pixelAt(clampX(xPart + 1, xwrap), clampY(yPart + 1, ywrap));
		return interpYFun(interpXFun(tl, tr, x - xPart), interpXFun(bl, br, x - xPart), y - yPart);
	}
}

/// Bitmap drawing
class Bitmap : FastWidget
{
	/// Bitmap to draw
	mixin RedrawProperty!(BitmapData, "bitmap");
	///
	mixin RedrawProperty!(SizingMode, "stretchWidth");
	///
	mixin RedrawProperty!(SizingMode, "stretchHeight");

	override bool isTransparent() const @property
	{
		return true;
	}

	override void draw(ref RenderTarget dest, Container mask)
	{
		if (_bitmap.w <= 0 || _bitmap.h <= 0)
			return;
		if (stretchWidth.isAlignMode && stretchHeight.isAlignMode)
		{
			int imageStartX = computePosition(stretchWidth, _bitmap.w, mask.w);
			int imageStartY = computePosition(stretchHeight, _bitmap.h, mask.h);
			for (int y = 0; y < mask.h; y++)
			{
				int sY = y - imageStartY;
				if (sY < 0)
					continue;
				if (sY >= _bitmap.h)
					break;
				int dY = mask.y + y;
				for (int x = 0; x < mask.w; x++)
				{
					int sX = x - imageStartX;
					if (sX < 0)
						continue;
					if (sX >= _bitmap.w)
						break;
					int dX = mask.x + x;
					ubyte[] dst = dest.pixels[(dX + dY * dest.w) * 4 .. (dX + dY * dest.w) * 4 + 4];
					dst[] = blend(_bitmap.pixelAt(sX, sY), dst[0 .. 4]);
				}
			}
		}
		else
		{
			float xScale = 1.0f / cast(float) mask.w * _bitmap.w;
			float yScale = 1.0f / cast(float) mask.h * _bitmap.h;
			for (int y = 0; y < mask.h; y++)
			{
				int dY = mask.y + y;
				for (int x = 0; x < mask.w; x++)
				{
					int dX = mask.x + x;
					ubyte[] dst = dest.pixels[(dX + dY * dest.w) * 4 .. (dX + dY * dest.w) * 4 + 4];
					float sX = computeIndex(stretchWidth, x, xScale, mask.w, _bitmap.w);
					float sY = computeIndex(stretchHeight, y, yScale, mask.h, _bitmap.h);
					if (sX >= 0 && sY >= 0 && sX <= _bitmap.w && sY <= _bitmap.h)
						dst[] = blend(_bitmap.interpolateAt!(LinearInterpolation,
								LinearInterpolation)(sX, sY), dst[0 .. 4]);
				}
			}
		}
	}
}
