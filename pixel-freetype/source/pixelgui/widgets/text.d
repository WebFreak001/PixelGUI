module pixelgui.widgets.text;

import derelict.freetype.ft;

import pixelgui;
import pixelgui.behaviors.text;

import std.conv;
import std.math;
import std.string;
import std.utf;

__gshared FT_Library ftLibrary;

shared static this()
{
	DerelictFT.load();

	FT_Init_FreeType(&ftLibrary).enforceFT;
}

struct FreeTypeFontFamily
{
	FT_Face[string] fonts;

	FT_Face opIndex(string name)
	{
		if (fonts.byKeyValue.empty)
			return null;
		auto ptr = name in fonts;
		if (ptr)
			return *ptr;
		name = name.strip.toLower;
		foreach (key, value; fonts)
		{
			if (key.strip.toLower == name)
				return value;
		}
		ptr = "Regular" in fonts;
		if (ptr)
			return *ptr;
		else
			return fonts.byKeyValue.front.value;
	}

	static FreeTypeFontFamily fromFiles(string[string] files)
	{
		FreeTypeFontFamily ret;
		foreach (key, value; files)
		{
			FT_Face face;
			FT_New_Face(ftLibrary, value.toStringz, 0, &face).enforceFT;
			FT_Set_Char_Size(face, 0, 11 * 64, 0, 0).enforceFT;
			FT_Select_Charmap(face, FT_ENCODING_UNICODE).enforceFT;
			ret.fonts[key] = face;
		}
		return ret;
	}
}

enum MinFontSize = 4;

void draw(ref RenderTarget image, FT_Bitmap bitmap, int x, int y, Color color)
{
	if (bitmap.pitch <= 0)
		return;
	int w = bitmap.width;
	if (bitmap.pixel_mode == FT_PIXEL_MODE_LCD || bitmap.pixel_mode == FT_PIXEL_MODE_LCD_V)
		w /= 3;
	int h = bitmap.rows;
	if (x + w < 0 || y + h < 0 || x >= image.w || y >= image.h)
		return;
	if (x < 0)
	{
		w -= x;
		x = 0;
	}
	if (w <= 0 || h <= 0)
		return;
	if (x + w >= image.w)
		w = image.w - x - 1;
	if (bitmap.pixel_mode == FT_PIXEL_MODE_GRAY)
		for (int ly; ly < h; ly++)
		{
			if (ly + y < 0 || ly + y >= image.h)
				continue;
			for (int lx; lx < w; lx++)
			{
				Color col = color;
				ubyte a = bitmap.buffer[lx + ly * bitmap.pitch];
				col[0] = cast(ubyte)(col[0] * a / 255);
				col[1] = cast(ubyte)(col[1] * a / 255);
				col[2] = cast(ubyte)(col[2] * a / 255);
				col[3] = cast(ubyte)(col[3] * a / 255);
				image.pixels[(lx + x + (ly + y) * image.w) * 4 .. (lx + x + (ly + y) * image.w) * 4 + 4] = blend(col,
						image.pixels[(lx + x + (ly + y) * image.w) * 4 .. (lx + x + (ly + y) * image.w) * 4 + 4][0
						.. 4]);
			}
		}
	else if (bitmap.pixel_mode == FT_PIXEL_MODE_LCD)
		for (int ly; ly < h; ly++)
		{
			if (ly + y < 0 || ly + y >= image.h)
				continue;
			for (int lx; lx < w; lx++)
			{
				Color col = color;
				ubyte[] b = bitmap.buffer[lx * 3 + ly * bitmap.pitch .. lx * 3 + ly * bitmap.pitch + 3];
				auto existing = image.pixels[(lx + x + (ly + y) * image.w) * 4 .. (
						lx + x + (ly + y) * image.w) * 4 + 4];
				uint a = ((cast(int) b[0] + cast(int) b[1] + cast(int) b[2]) / 3) * col[3] / 255;
				ubyte b0 = cast(ubyte)(b[0] * a / 255);
				ubyte b1 = cast(ubyte)(b[1] * a / 255);
				ubyte b2 = cast(ubyte)(b[2] * a / 255);
				col[0] = cast(ubyte)(col[0] * b0 / 255 + existing[0] * (255 - b0) / 255);
				col[1] = cast(ubyte)(col[1] * b1 / 255 + existing[1] * (255 - b1) / 255);
				col[2] = cast(ubyte)(col[2] * b2 / 255 + existing[2] * (255 - b2) / 255);
				col[3] = cast(ubyte)(col[3] * a / 255 + existing[3] * (255 - a) / 255);
				image.pixels[(lx + x + (ly + y) * image.w) * 4 .. (lx + x + (ly + y) * image.w) * 4 + 4] = col;
			}
		}
	else
		throw new Exception("Unsupported bitmap format " ~ bitmap.pixel_mode.to!string);
}

class TextWidget : TextBehavior!(FastWidget, FreeTypeFontFamily)
{
	override void draw(ref RenderTarget dest, Container mask)
	{
		int x = mask.x << 6;
		int y = mask.y << 6;
		int[] lineHeights;
		int targetSize = cast(int) round(fontSize.compute(hierarchy, false) * 64);
		if (targetSize < MinFontSize * 64)
			targetSize = MinFontSize * 64;
		string font;
		FT_Face face;
		auto lines = partsByLines;
		foreach (line; lines)
		{
			int maxHeight = 0;
			foreach (part; line)
			{
				if (!part.fontStyle.length)
					part.fontStyle = fontStyle;
				if (font !is part.fontStyle)
				{
					face = (part.font == FreeTypeFontFamily.init ? _font : part.font)[part.fontStyle];
					auto size = targetSize;
					if (part.size.mode != Length.Mode.fitContent)
						size = cast(int) round(part.size.compute(hierarchy, false) * 64);
					FT_Set_Char_Size(face, 0, size, 0, 0).enforceFT;
					font = part.fontStyle;
					auto height = cast(int)(face.height * size / face.units_per_EM * part.lineHeight);
					if (height > maxHeight)
						maxHeight = height;
				}
			}
			lineHeights ~= maxHeight;
			font = null;
		}
		foreach (i, line; lines)
		{
			x = mask.x << 6;
			y += lineHeights[i];
			foreach (part; line)
			{
				if (!part.fontStyle.length)
					part.fontStyle = fontStyle;
				if (font !is part.fontStyle)
				{
					face = (part.font == FreeTypeFontFamily.init ? _font : part.font)[part.fontStyle];
					auto size = targetSize;
					if (part.size.mode != Length.Mode.fitContent)
						size = cast(int) round(part.size.compute(hierarchy, false) * 64);
					FT_Set_Char_Size(face, 0, size, 0, 0).enforceFT;
					font = part.fontStyle;
				}
				if (!face)
					face = (part.font == FreeTypeFontFamily.init ? _font : part.font)["Regular"];
				bool kerning = FT_HAS_KERNING(face);
				FT_UInt prev;
				foreach (c; part.text.byDchar)
					drawChar(dest, face, c, prev, x, y, kerning, part.color);
			}
		}
	}

	private void drawChar(ref RenderTarget dest, FT_Face face, dchar c,
			ref FT_UInt prev, ref int x, ref int y, bool kerning, Color color)
	{
		auto glyphIndex = FT_Get_Char_Index(face, cast(FT_ULong) c);
		if (kerning && c && glyphIndex)
		{
			FT_Vector delta;
			FT_Get_Kerning(face, prev, glyphIndex, FT_Kerning_Mode.FT_KERNING_DEFAULT, &delta);
			x += delta.x;
			y += delta.y;
		}
		prev = glyphIndex;
		if (FT_Load_Glyph(face, glyphIndex, FT_LOAD_COLOR | FT_LOAD_TARGET_LIGHT))
			return;
		FT_Render_Glyph(face.glyph, FT_RENDER_MODE_LCD);

		dest.draw(face.glyph.bitmap, (x >> 6) + face.glyph.bitmap_left,
				(y >> 6) - face.glyph.bitmap_top, color);

		x += face.glyph.advance.x;
		y += face.glyph.advance.y;
	}
}

enum FTErrors
{
	FT_Err_Ok = 0x00,
	FT_Err_Cannot_Open_Resource = 0x01,
	FT_Err_Unknown_File_Format = 0x02,
	FT_Err_Invalid_File_Format = 0x03,
	FT_Err_Invalid_Version = 0x04,
	FT_Err_Lower_Module_Version = 0x05,
	FT_Err_Invalid_Argument = 0x06,
	FT_Err_Unimplemented_Feature = 0x07,
	FT_Err_Invalid_Table = 0x08,
	FT_Err_Invalid_Offset = 0x09,
	FT_Err_Array_Too_Large = 0x0A,
	FT_Err_Missing_Module = 0x0B,
	FT_Err_Missing_Property = 0x0C,

	FT_Err_Invalid_Glyph_Index = 0x10,
	FT_Err_Invalid_Character_Code = 0x11,
	FT_Err_Invalid_Glyph_Format = 0x12,
	FT_Err_Cannot_Render_Glyph = 0x13,
	FT_Err_Invalid_Outline = 0x14,
	FT_Err_Invalid_Composite = 0x15,
	FT_Err_Too_Many_Hints = 0x16,
	FT_Err_Invalid_Pixel_Size = 0x17,

	FT_Err_Invalid_Handle = 0x20,
	FT_Err_Invalid_Library_Handle = 0x21,
	FT_Err_Invalid_Driver_Handle = 0x22,
	FT_Err_Invalid_Face_Handle = 0x23,
	FT_Err_Invalid_Size_Handle = 0x24,
	FT_Err_Invalid_Slot_Handle = 0x25,
	FT_Err_Invalid_CharMap_Handle = 0x26,
	FT_Err_Invalid_Cache_Handle = 0x27,
	FT_Err_Invalid_Stream_Handle = 0x28,

	FT_Err_Too_Many_Drivers = 0x30,
	FT_Err_Too_Many_Extensions = 0x31,

	FT_Err_Out_Of_Memory = 0x40,
	FT_Err_Unlisted_Object = 0x41,

	FT_Err_Cannot_Open_Stream = 0x51,
	FT_Err_Invalid_Stream_Seek = 0x52,
	FT_Err_Invalid_Stream_Skip = 0x53,
	FT_Err_Invalid_Stream_Read = 0x54,
	FT_Err_Invalid_Stream_Operation = 0x55,
	FT_Err_Invalid_Frame_Operation = 0x56,
	FT_Err_Nested_Frame_Access = 0x57,
	FT_Err_Invalid_Frame_Read = 0x58,

	FT_Err_Raster_Uninitialized = 0x60,
	FT_Err_Raster_Corrupted = 0x61,
	FT_Err_Raster_Overflow = 0x62,
	FT_Err_Raster_Negative_Height = 0x63,

	FT_Err_Too_Many_Caches = 0x70,

	FT_Err_Invalid_Opcode = 0x80,
	FT_Err_Too_Few_Arguments = 0x81,
	FT_Err_Stack_Overflow = 0x82,
	FT_Err_Code_Overflow = 0x83,
	FT_Err_Bad_Argument = 0x84,
	FT_Err_Divide_By_Zero = 0x85,
	FT_Err_Invalid_Reference = 0x86,
	FT_Err_Debug_OpCode = 0x87,
	FT_Err_ENDF_In_Exec_Stream = 0x88,
	FT_Err_Nested_DEFS = 0x89,
	FT_Err_Invalid_CodeRange = 0x8A,
	FT_Err_Execution_Too_Long = 0x8B,
	FT_Err_Too_Many_Function_Defs = 0x8C,
	FT_Err_Too_Many_Instruction_Defs = 0x8D,
	FT_Err_Table_Missing = 0x8E,
	FT_Err_Horiz_Header_Missing = 0x8F,
	FT_Err_Locations_Missing = 0x90,
	FT_Err_Name_Table_Missing = 0x91,
	FT_Err_CMap_Table_Missing = 0x92,
	FT_Err_Hmtx_Table_Missing = 0x93,
	FT_Err_Post_Table_Missing = 0x94,
	FT_Err_Invalid_Horiz_Metrics = 0x95,
	FT_Err_Invalid_CharMap_Format = 0x96,
	FT_Err_Invalid_PPem = 0x97,
	FT_Err_Invalid_Vert_Metrics = 0x98,
	FT_Err_Could_Not_Find_Context = 0x99,
	FT_Err_Invalid_Post_Table_Format = 0x9A,
	FT_Err_Invalid_Post_Table = 0x9B,

	FT_Err_Syntax_Error = 0xA0,
	FT_Err_Stack_Underflow = 0xA1,
	FT_Err_Ignore = 0xA2,
	FT_Err_No_Unicode_Glyph_Name = 0xA3,
	FT_Err_Glyph_Too_Big = 0xA4,

	FT_Err_Missing_Startfont_Field = 0xB0,
	FT_Err_Missing_Font_Field = 0xB1,
	FT_Err_Missing_Size_Field = 0xB2,
	FT_Err_Missing_Fontboundingbox_Field = 0xB3,
	FT_Err_Missing_Chars_Field = 0xB4,
	FT_Err_Missing_Startchar_Field = 0xB5,
	FT_Err_Missing_Encoding_Field = 0xB6,
	FT_Err_Missing_Bbx_Field = 0xB7,
	FT_Err_Bbx_Too_Big = 0xB8,
	FT_Err_Corrupted_Font_Header = 0xB9,
	FT_Err_Corrupted_Font_Glyphs = 0xBA,

	FT_Err_Max,
}

void enforceFT(FT_Error err)
{
	if (err == 0)
		return;
	throw new Exception((cast(FTErrors) err).to!string);
}
