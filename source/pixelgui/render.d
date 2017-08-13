module pixelgui.render;

/// Premultiplied [R, G, B, A] color
alias Color = ubyte[4];

///
string toColorHexString(in Color color)
{
	pragma(inline, true) immutable(char)[2] digit(ubyte b)
	{
		ubyte l = b / 16;
		ubyte r = b % 16;
		immutable(char) lc = cast(immutable(char))((l >= 10 ? 'A' - 10 : '0') + l);
		immutable(char) rc = cast(immutable(char))((r >= 10 ? 'A' - 10 : '0') + r);
		return [lc, rc];
	}

	if (color[3] == 0xFF)
		return '#' ~ digit(color[0]) ~ digit(color[1]) ~ digit(color[2]);
	else
		return '#' ~ digit(color[0]) ~ digit(color[1]) ~ digit(color[2]) ~ digit(color[3]);
}

/// Non-premultiplied color
template colUnmul(string hex)
{
	static if (hex.length == 6)
		enum colUnmul = cast(Color)[mixin("0x" ~ hex[0 .. 2]), mixin("0x" ~ hex[2 .. 4]),
				mixin("0x" ~ hex[4 .. 6]), 0xFF];
	else static if (hex.length == 8)
		enum colUnmul = cast(Color)[mixin("0x" ~ hex[0 .. 2]), mixin("0x" ~ hex[2 .. 4]),
				mixin("0x" ~ hex[4 .. 6]), mixin("0x" ~ hex[6 .. 8])];
	else
		static assert(false, "Hex color string '" ~ hex ~ "' not supported");
}

/// Premultiplied color
template col(string hex)
{
	static if (hex.length == 6)
		enum col = cast(Color)[mixin("0x" ~ hex[0 .. 2]), mixin("0x" ~ hex[2 .. 4]),
				mixin("0x" ~ hex[4 .. 6]), 0xFF];
	else static if (hex.length == 8)
		enum col = cast(Color)[mixin("0x" ~ hex[0 .. 2]), mixin("0x" ~ hex[2 .. 4]),
				mixin("0x" ~ hex[4 .. 6]), mixin("0x" ~ hex[6 .. 8])].premultiply;
	else
		static assert(false, "Hex color string '" ~ hex ~ "' not supported");
}

enum HTMLColors : Color
{
	aliceBlue = col!"F0F8FF",
	antiqueWhite = col!"FAEBD7",
	aqua = col!"00FFFF",
	aquamarine = col!"7FFFD4",
	azure = col!"F0FFFF",
	beige = col!"F5F5DC",
	bisque = col!"FFE4C4",
	black = col!"000000",
	blanchedAlmond = col!"FFEBCD",
	blue = col!"0000FF",
	blueViolet = col!"8A2BE2",
	brown = col!"A52A2A",
	burlyWood = col!"DEB887",
	cadetBlue = col!"5F9EA0",
	chartreuse = col!"7FFF00",
	chocolate = col!"D2691E",
	coral = col!"FF7F50",
	cornflowerBlue = col!"6495ED",
	cornsilk = col!"FFF8DC",
	crimson = col!"DC143C",
	cyan = col!"00FFFF",
	darkBlue = col!"00008B",
	darkCyan = col!"008B8B",
	darkGoldenRod = col!"B8860B",
	darkGray = col!"A9A9A9",
	darkGrey = col!"A9A9A9",
	darkGreen = col!"006400",
	darkKhaki = col!"BDB76B",
	darkMagenta = col!"8B008B",
	darkOliveGreen = col!"556B2F",
	darkOrange = col!"FF8C00",
	darkOrchid = col!"9932CC",
	darkRed = col!"8B0000",
	darkSalmon = col!"E9967A",
	darkSeaGreen = col!"8FBC8F",
	darkSlateBlue = col!"483D8B",
	darkSlateGray = col!"2F4F4F",
	darkSlateGrey = col!"2F4F4F",
	darkTurquoise = col!"00CED1",
	darkViolet = col!"9400D3",
	deepPink = col!"FF1493",
	deepSkyBlue = col!"00BFFF",
	dimGray = col!"696969",
	dimGrey = col!"696969",
	dodgerBlue = col!"1E90FF",
	fireBrick = col!"B22222",
	floralWhite = col!"FFFAF0",
	forestGreen = col!"228B22",
	fuchsia = col!"FF00FF",
	gainsboro = col!"DCDCDC",
	ghostWhite = col!"F8F8FF",
	gold = col!"FFD700",
	goldenRod = col!"DAA520",
	gray = col!"808080",
	grey = col!"808080",
	green = col!"008000",
	greenYellow = col!"ADFF2F",
	honeyDew = col!"F0FFF0",
	hotPink = col!"FF69B4",
	indianRed = col!"CD5C5C",
	indigo = col!"4B0082",
	ivory = col!"FFFFF0",
	khaki = col!"F0E68C",
	lavender = col!"E6E6FA",
	lavenderBlush = col!"FFF0F5",
	lawnGreen = col!"7CFC00",
	lemonChiffon = col!"FFFACD",
	lightBlue = col!"ADD8E6",
	lightCoral = col!"F08080",
	lightCyan = col!"E0FFFF",
	lightGoldenRodYellow = col!"FAFAD2",
	lightGray = col!"D3D3D3",
	lightGrey = col!"D3D3D3",
	lightGreen = col!"90EE90",
	lightPink = col!"FFB6C1",
	lightSalmon = col!"FFA07A",
	lightSeaGreen = col!"20B2AA",
	lightSkyBlue = col!"87CEFA",
	lightSlateGray = col!"778899",
	lightSlateGrey = col!"778899",
	lightSteelBlue = col!"B0C4DE",
	lightYellow = col!"FFFFE0",
	lime = col!"00FF00",
	limeGreen = col!"32CD32",
	linen = col!"FAF0E6",
	magenta = col!"FF00FF",
	maroon = col!"800000",
	mediumAquaMarine = col!"66CDAA",
	mediumBlue = col!"0000CD",
	mediumOrchid = col!"BA55D3",
	mediumPurple = col!"9370DB",
	mediumSeaGreen = col!"3CB371",
	mediumSlateBlue = col!"7B68EE",
	mediumSpringGreen = col!"00FA9A",
	mediumTurquoise = col!"48D1CC",
	mediumVioletRed = col!"C71585",
	midnightBlue = col!"191970",
	mintCream = col!"F5FFFA",
	mistyRose = col!"FFE4E1",
	moccasin = col!"FFE4B5",
	navajoWhite = col!"FFDEAD",
	navy = col!"000080",
	oldLace = col!"FDF5E6",
	olive = col!"808000",
	oliveDrab = col!"6B8E23",
	orange = col!"FFA500",
	orangeRed = col!"FF4500",
	orchid = col!"DA70D6",
	paleGoldenRod = col!"EEE8AA",
	paleGreen = col!"98FB98",
	paleTurquoise = col!"AFEEEE",
	paleVioletRed = col!"DB7093",
	papayaWhip = col!"FFEFD5",
	peachPuff = col!"FFDAB9",
	peru = col!"CD853F",
	pink = col!"FFC0CB",
	plum = col!"DDA0DD",
	powderBlue = col!"B0E0E6",
	purple = col!"800080",
	rebeccaPurple = col!"663399",
	red = col!"FF0000",
	rosyBrown = col!"BC8F8F",
	royalBlue = col!"4169E1",
	saddleBrown = col!"8B4513",
	salmon = col!"FA8072",
	sandyBrown = col!"F4A460",
	seaGreen = col!"2E8B57",
	seaShell = col!"FFF5EE",
	sienna = col!"A0522D",
	silver = col!"C0C0C0",
	skyBlue = col!"87CEEB",
	slateBlue = col!"6A5ACD",
	slateGray = col!"708090",
	slateGrey = col!"708090",
	snow = col!"FFFAFA",
	springGreen = col!"00FF7F",
	steelBlue = col!"4682B4",
	tan = col!"D2B48C",
	teal = col!"008080",
	thistle = col!"D8BFD8",
	tomato = col!"FF6347",
	turquoise = col!"40E0D0",
	violet = col!"EE82EE",
	wheat = col!"F5DEB3",
	white = col!"FFFFFF",
	whiteSmoke = col!"F5F5F5",
	yellow = col!"FFFF00",
	yellowGreen = col!"9ACD32",
}

/// Represents a drawable area
struct RenderTarget
{
	/// Pixels in RGBA format
	ubyte[] pixels;
	/// in pixels
	int w, h;
}

/// Alpha premultiply a color.
Color premultiply(ubyte[4] rgba)
{
	const ushort r = rgba[0] * rgba[3];
	const ushort g = rgba[1] * rgba[3];
	const ushort b = rgba[2] * rgba[3];
	return [(r / 255) & 0xFF, (g / 255) & 0xFF, (b / 255) & 0xFF, rgba[3]];
}

/// Undo alpha premultiplication
ubyte[4] demultiply(Color c)
{
	if (c[3] == 0)
		return c;
	auto r = c[0] * 255 / c[3];
	auto g = c[1] * 255 / c[3];
	auto b = c[2] * 255 / c[3];
	return [r & 0xFF, g & 0xFF, b & 0xFF, c[3]];
}

/// Blending operators (See https://www.cairographics.org/operators/)
enum BlendOp
{
	/// Always fully replace the color with the foreground
	source,
	/// Physically accurate color mixing
	over,
}

/// Alpha premultiply a color.
pragma(inline, true) Color blend(BlendOp mixOp = BlendOp.over)(Color fg, Color bg)
{
	static if (mixOp == BlendOp.source)
	{
		pragma(msg,
				"Warning: blend called with BlendOp.source, consider just using the fg instead as this is a no-op");
		return fg;
	}
	else
	{
		ubyte[4] r;
		static if (mixOp == BlendOp.over)
		{
			r[3] = (fg[3] + bg[3] * (255 - fg[3]) / 255) & 0xFF;
			if (r[3] == 0)
				return r;
			foreach (c; 0 .. 3)
			{
				r[c] = ((fg[c] * 255 + bg[c] * (255 - fg[3])) / r[3]) & 0xFF;
			}
		}
		else
			static assert(false);
		return r;
	}
}

///
@safe unittest
{
	assert(blend!(BlendOp.over)(col!"FF000080", col!"000000") == col!"800000");
	assert(blend!(BlendOp.over)(col!"FF0000", col!"000000") == col!"FF0000");
}

/// Copies a bitmap to another one
void copyTo(BlendOp mixOp = BlendOp.over)(in RenderTarget src, ref RenderTarget target,
		int x, int y, int offX = 0, int offY = 0, int clipWidth = 0, int clipHeight = 0)
{
	if (clipWidth == 0)
		clipWidth = src.w;
	else if (clipWidth < 0)
		clipWidth = src.w + clipWidth;
	if (clipHeight == 0)
		clipHeight = src.h;
	else if (clipHeight == 0)
		clipHeight = src.h + clipHeight;
	if (x < 0)
	{
		offX -= x;
		clipWidth += x;
		x = 0;
	}
	if (y < 0)
	{
		offY -= y;
		clipHeight += y;
		y = 0;
	}
	if (x >= target.w || y >= target.h)
		return;
	if (clipWidth <= 0 || clipHeight <= 0)
		return;
	if (offX < 0)
		offX = 0;
	if (offY < 0)
		offY = 0;
	if (clipWidth + offX >= src.w)
		clipWidth = src.w - offX;
	if (clipHeight + offY >= src.h)
		clipHeight = src.h - offY;
	if (clipWidth + x >= target.w)
		clipWidth = target.w - x;
	if (clipHeight + y >= target.h)
		clipHeight = target.h - y;
	if (x + clipWidth < 0 || y + clipHeight < 0)
		return;
	for (int row = 0; row < clipHeight; row++)
	{
		static if (mixOp == BlendOp.source)
		{
			target.pixels[(x + (y + row) * target.w) * 4 .. (x + (y + row) * target.w + clipWidth) * 4] = src.pixels[(
					offX + (offY + row) * src.w) * 4 .. (offX + (offY + row) * src.w + clipWidth) * 4];
		}
		else
		{
			for (int col = 0; col < clipWidth; col++)
			{
				target.pixels[(x + col + (y + row) * target.w) * 4 .. (x + col + (y + row) * target.w)
					* 4 + 4][0 .. 4] = blend!mixOp(
						src.pixels[(offX + col + (offY + row) * src.w) * 4 .. (
						offX + col + (offY + row) * src.w) * 4 + 4][0 .. 4],
						target.pixels[(x + col + (y + row) * target.w) * 4 .. (x + col + (y + row) * target.w)
						* 4 + 4][0 .. 4]);
			}
		}
	}
}

///
@safe unittest
{
	RenderTarget image;
	image.w = 4;
	image.h = 4;
	image.pixels = new ubyte[4 * 4 * 4];

	RenderTarget over;
	over.w = 2;
	over.h = 2;
	over.pixels = new ubyte[2 * 2 * 4];
	over.fillRect!(BlendOp.source)(0, 0, 2, 2, col!"00FF00");

	over.copyTo!(BlendOp.source)(image, 1, 1);

	//dfmt off
	enum w = 0xFF;
	assert(image.pixels == [
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	]);
	//dfmt on

	image.pixels[] = 0;
	over.copyTo!(BlendOp.over)(image, 1, 1);
	//dfmt off
	assert(image.pixels == [
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	]);
	//dfmt on
}

/// Fills a rectangle inside the image with a pattern.
void fillPattern(alias patternFun, BlendOp mixOp = BlendOp.over)(
		ref RenderTarget target, int x, int y, int w, int h)
{
	if (w <= 0 || h <= 0)
		return;
	if (x + w < 0 || y + h < 0 || x >= target.w || y >= target.h)
		return;
	if (x < 0)
	{
		w += x;
		x = 0;
	}
	if (y < 0)
	{
		h += y;
		y = 0;
	}
	if (w <= 0 || h <= 0)
		return;
	if (x + w > target.w)
		w = target.w - x;
	if (y + h > target.h)
		h = target.h - y;
	for (int v; v < h; v++)
	{
		for (int c; c < w; c++)
		{
			static if (__traits(compiles, { patternFun(c, v, x + c, y + v, w, h); }))
				const rgba = patternFun(c, v, x + c, y + v, w, h);
			else static if (__traits(compiles, { patternFun(c, v, w, h); }))
				const rgba = patternFun(c, v, w, h);
			else static if (__traits(compiles, { patternFun(c, v); }))
				const rgba = patternFun(c, v);
			else
				static assert(false, "Can't use pattern function which doesn't take 2/4/6 arguments.");
			static if (mixOp == BlendOp.source)
			{
				(cast(uint[]) target.pixels)[x + c + (y + v) * target.w] = rgba.rgbaToMemory;
			}
			else
			{
				auto blended = blend!mixOp(rgba, target.pixels[(
						x + c + (y + v) * target.w) * 4 .. (x + c + (y + v) * target.w) * 4 + 4][0 .. 4]);
				target.pixels[(x + c + (y + v) * target.w) * 4 + 0] = blended[0];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 1] = blended[1];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 2] = blended[2];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 3] = blended[3];
			}
		}
	}
}

/// Draws a rectangle border with a solid color.
void drawBorder(BlendOp mixOp = BlendOp.over)(ref RenderTarget target, int x,
		int y, int w, int h, in Color rgba) pure nothrow @safe
{
	if (w <= 0 || h <= 0)
		return;
	if (x + w < 0 || y + h < 0 || x >= target.w || y >= target.h)
		return;
	if (x < 0)
	{
		w += x;
		x = 0;
	}
	if (y < 0)
	{
		h += y;
		y = 0;
	}
	if (w <= 0 || h <= 0)
		return;
	if (x + w > target.w)
		w = target.w - x;
	if (y + h > target.h)
		h = target.h - y;
	static if (mixOp == BlendOp.source)
	{
		uint color = rgba.rgbaToMemory;
		(cast(uint[]) target.pixels[(x + y * target.w) * 4 .. (x + w + y * target.w) * 4])[] = color;
		(cast(uint[]) target.pixels[(x + (y + h - 1) * target.w) * 4 .. (x + w + (y + h - 1) * target.w)
				* 4])[] = color;
		for (int v = 1; v < h - 1; v++)
		{
			(cast(uint[]) target.pixels)[x + (y + v) * target.w] = color;
			(cast(uint[]) target.pixels)[x + w - 1 + (y + v) * target.w] = color;
		}
	}
	else
	{
		foreach (v; [0, h - 1])
		{
			for (int c; c < w; c++)
			{
				auto i = (x + c + (y + v) * target.w) * 4;
				auto blended = blend!mixOp(rgba, target.pixels[i .. i + 4][0 .. 4]);
				target.pixels[i + 0] = blended[0];
				target.pixels[i + 1] = blended[1];
				target.pixels[i + 2] = blended[2];
				target.pixels[i + 3] = blended[3];
			}
		}
		for (int v = 1; v < h - 1; v++)
		{
			{
				auto i = (x + (y + v) * target.w) * 4;
				auto blended = blend!mixOp(rgba, target.pixels[i .. i + 4][0 .. 4]);
				target.pixels[i + 0] = blended[0];
				target.pixels[i + 1] = blended[1];
				target.pixels[i + 2] = blended[2];
				target.pixels[i + 3] = blended[3];
			}
			{
				auto i = (x + w - 1 + (y + v) * target.w) * 4;
				auto blended = blend!mixOp(rgba, target.pixels[i .. i + 4][0 .. 4]);
				target.pixels[i + 0] = blended[0];
				target.pixels[i + 1] = blended[1];
				target.pixels[i + 2] = blended[2];
				target.pixels[i + 3] = blended[3];
			}
		}
	}
}

/// Fills a rectangle inside the image with a solid color.
void fillRect(BlendOp mixOp = BlendOp.over)(ref RenderTarget target, int x, int y,
		int w, int h, in Color rgba) pure nothrow @safe
{
	if (w <= 0 || h <= 0)
		return;
	if (x + w < 0 || y + h < 0 || x >= target.w || y >= target.h)
		return;
	if (x < 0)
	{
		w += x;
		x = 0;
	}
	if (y < 0)
	{
		h += y;
		y = 0;
	}
	if (w <= 0 || h <= 0)
		return;
	if (x + w > target.w)
		w = target.w - x;
	if (y + h > target.h)
		h = target.h - y;
	static if (mixOp == BlendOp.source)
		uint color = rgba.rgbaToMemory;
	for (int v; v < h; v++)
	{
		static if (mixOp == BlendOp.source)
			(cast(uint[]) target.pixels[(x + (y + v) * target.w) * 4 .. (x + w + (y + v) * target.w) * 4])[] = color;
		else
		{
			for (int c; c < w; c++)
			{
				auto blended = blend!mixOp(rgba, target.pixels[(
						x + c + (y + v) * target.w) * 4 .. (x + c + (y + v) * target.w) * 4 + 4][0 .. 4]);
				target.pixels[(x + c + (y + v) * target.w) * 4 + 0] = blended[0];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 1] = blended[1];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 2] = blended[2];
				target.pixels[(x + c + (y + v) * target.w) * 4 + 3] = blended[3];
			}
		}
	}
}

/// Clears the buffer with one solid color using SSE.
void clearFast(ref RenderTarget target, in Color rgba) pure nothrow @nogc @safe
{
	(cast(uint[]) target.pixels)[] = rgba.rgbaToMemory;
}

/// Converts a Color value to the system dependent uint for SSE optimization.
auto rgbaToMemory(inout Color rgba) pure nothrow @nogc @trusted
{
	return *(cast(uint*) rgba.ptr);
}

///
@safe unittest
{
	RenderTarget image;
	image.w = 2;
	image.h = 1;
	image.pixels = new ubyte[4 * 2];
	immutable Color bg = [0x10, 0x20, 0x30, 0x40];
	image.clearFast(bg);
	assert(image.pixels[0] == 0x10);
	assert(image.pixels[1] == 0x20);
	assert(image.pixels[2] == 0x30);
	assert(image.pixels[3] == 0x40);
	assert(image.pixels[4] == 0x10);
	assert(image.pixels[5] == 0x20);
	assert(image.pixels[6] == 0x30);
	assert(image.pixels[7] == 0x40);
}

///
@safe unittest
{
	RenderTarget image;
	image.w = 4;
	image.h = 4;
	image.pixels = new ubyte[4 * 4 * 4];
	image.fillRect!(BlendOp.source)(1, 1, 2, 2, col!"00FF00");
	//dfmt off
	enum w = 0xFF;
	assert(image.pixels == [
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,w,0,w, 0,w,0,w, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	]);
	//dfmt on
}

///
@safe unittest
{
	RenderTarget image;
	image.w = 4;
	image.h = 4;
	image.pixels = new ubyte[4 * 4 * 4];
	image.fillRect!(BlendOp.source)(-1, -1, 2, 2, col!"00FF00");
	//dfmt off
	enum w = 0xFF;
	assert(image.pixels == [
		0,w,0,w, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	]);
	//dfmt on
}
