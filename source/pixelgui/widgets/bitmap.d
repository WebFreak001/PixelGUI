module pixelgui.widgets.bitmap;

import pixelgui.render;
import pixelgui.widget;

/// Supported bitmap formats
enum BitmapFormat
{
	/// RGBA data, can be rendered the fastest
	RGBA,
	/// ARGB data
	ARGB,
	/// BGRA data
	BGRA,
	/// ABGR data
	ABGR,
	/// opaque RGB data
	RGB,
	/// opaque BGR data
	BGR,
}

///
enum SizingMode
{
	/// Put image to the left
	leftAlign,
	/// Put image to the center
	centerAlign,
	/// Put image to the right
	rightAlign
}

private int compute(SizingMode mode, int image, int max)
{
	final switch (mode)
	{
	case SizingMode.leftAlign:
		return 0;
	case SizingMode.centerAlign:
		return (max - image) / 2;
	case SizingMode.rightAlign:
		return max - image;
	}
}

///
struct BitmapData
{
	ubyte[] data;
	int w, h;
	BitmapFormat format;
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
		int imageStartX = compute(stretchWidth, _bitmap.w, mask.w);
		int imageStartY = compute(stretchHeight, _bitmap.h, mask.h);
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
				final switch (_bitmap.format)
				{
				case BitmapFormat.RGBA:
					dst[] = blend(_bitmap.data[(sX + sY * _bitmap.w) * 4 .. (sX + sY * _bitmap.w) * 4 + 4][0
							.. 4], dst[0 .. 4]);
					break;
				case BitmapFormat.ARGB:
					Color src = [_bitmap.data[(sX + sY * _bitmap.w) * 4 + 3],
						_bitmap.data[(sX + sY * _bitmap.w) * 4],
						_bitmap.data[(sX + sY * _bitmap.w) * 4 + 1], _bitmap.data[(sX + sY * _bitmap.w) * 4 + 2]];
					dst[] = blend(src, dst[0 .. 4]);
					break;
				case BitmapFormat.BGRA:
					Color src = [_bitmap.data[(sX + sY * _bitmap.w) * 4 + 2],
						_bitmap.data[(sX + sY * _bitmap.w) * 4 + 1],
						_bitmap.data[(sX + sY * _bitmap.w) * 4 + 0], _bitmap.data[(sX + sY * _bitmap.w) * 4 + 3]];
					dst[] = blend(src, dst[0 .. 4]);
					break;
				case BitmapFormat.ABGR:
					Color src = [_bitmap.data[(sX + sY * _bitmap.w) * 4 + 3],
						_bitmap.data[(sX + sY * _bitmap.w) * 4 + 2],
						_bitmap.data[(sX + sY * _bitmap.w) * 4 + 1], _bitmap.data[(sX + sY * _bitmap.w) * 4]];
					dst[] = blend(src, dst[0 .. 4]);
					break;
				case BitmapFormat.RGB:
					Color src = [_bitmap.data[(sX + sY * _bitmap.w) * 3 + 0],
						_bitmap.data[(sX + sY * _bitmap.w) * 3 + 1],
						_bitmap.data[(sX + sY * _bitmap.w) * 3 + 2], 0xFF];
					dst[] = blend(src, dst[0 .. 4]);
					break;
				case BitmapFormat.BGR:
					Color src = [_bitmap.data[(sX + sY * _bitmap.w) * 3 + 2],
						_bitmap.data[(sX + sY * _bitmap.w) * 3 + 1],
						_bitmap.data[(sX + sY * _bitmap.w) * 3 + 0], 0xFF];
					dst[] = blend(src, dst[0 .. 4]);
					break;
				}
			}
		}
	}
}
