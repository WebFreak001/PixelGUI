module pixelgui.fontconfig;

import fontconfig.fontconfig;
import std.string;

/// Finds all font file paths for a font family on systems using fontconfig
string[string] fontFamilyByName(string name)
{
	string[string] ret;
	FcPattern* pat = FcPatternCreate();
	FcObjectSet* os = FcObjectSetBuild(FC_FAMILY.ptr, FC_STYLE.ptr, FC_FILE.ptr, null);
	FcFontSet* fs = FcFontList(null, pat, os);
	const compareFamily = name.strip.toLower;
	for (int i = 0; fs && i < fs.nfont; ++i)
	{
		FcPattern* font = fs.fonts[i];
		char* file, style, family;
		if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResult.FcResultMatch
				&& FcPatternGetString(font, FC_FAMILY, 0, &family) == FcResult.FcResultMatch
				&& FcPatternGetString(font, FC_STYLE, 0, &style) == FcResult.FcResultMatch)
		{
			const dFamily = family.fromStringz;
			if (dFamily.strip.toLower == compareFamily)
			{
				const dFile = file.fromStringz.idup;
				const dStyle = style.fromStringz.idup;
				ret[dStyle] = dFile;
			}
		}
	}
	if (fs)
		FcFontSetDestroy(fs);
	return ret;
}

shared static this()
{
	if (!FcInit())
		throw new Exception("Could not init fontconfig");
}

shared static ~this()
{
	FcFini();
}
