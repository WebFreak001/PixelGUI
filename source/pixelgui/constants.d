module pixelgui.constants;

enum MouseButton : ubyte
{
	left = 1,
	middle = 2,
	right = 3
}

enum scancodeToKeycode(int t) = (1 << 30) | t;

enum Key : uint
{
	unknown = 0,

	enter = '\r',
	escape = '\033',
	backspace = '\b',
	tab = '\t',
	space = ' ',
	exclaim = '!',
	quotedbl = '"',
	hash = '#',
	percent = '%',
	dollar = '$',
	ampersand = '&',
	quote = '\'',
	leftparen = '(',
	rightparen = ')',
	asterisk = '*',
	plus = '+',
	comma = ',',
	minus = '-',
	period = '.',
	slash = '/',
	_0 = '0',
	_1 = '1',
	_2 = '2',
	_3 = '3',
	_4 = '4',
	_5 = '5',
	_6 = '6',
	_7 = '7',
	_8 = '8',
	_9 = '9',
	colon = ':',
	semicolon = ';',
	less = '<',
	equals = '=',
	greater = '>',
	question = '?',
	at = '@',
	leftbracket = '[',
	backslash = '\\',
	rightbracket = ']',
	caret = '^',
	underscore = '_',
	backquote = '`',
	a = 'a',
	b = 'b',
	c = 'c',
	d = 'd',
	e = 'e',
	f = 'f',
	g = 'g',
	h = 'h',
	i = 'i',
	j = 'j',
	k = 'k',
	l = 'l',
	m = 'm',
	n = 'n',
	o = 'o',
	p = 'p',
	q = 'q',
	r = 'r',
	s = 's',
	t = 't',
	u = 'u',
	v = 'v',
	w = 'w',
	x = 'x',
	y = 'y',
	z = 'z',

	capslock = 1073741881,

	f1,
	f2,
	f3,
	f4,
	f5,
	f6,
	f7,
	f8,
	f9,
	f10,
	f11,
	f12,

	printscreen,
	scrolllock,
	pause,
	insert,
	home,
	pageup,
	delete_ = '\177',
	end = 1073741901,
	pagedown,
	right,
	left,
	down,
	up,

	numlockclear,
	kp_divide,
	kp_multiply,
	kp_minus,
	kp_plus,
	kp_enter,
	kp_1,
	kp_2,
	kp_3,
	kp_4,
	kp_5,
	kp_6,
	kp_7,
	kp_8,
	kp_9,
	kp_0,
	kp_period,
	application = 1073741925,
	power,
	kp_equals,
	f13,
	f14,
	f15,
	f16,
	f17,
	f18,
	f19,
	f20,
	f21,
	f22,
	f23,
	f24,
	execute,
	help,
	menu,
	select,
	stop,
	again,
	undo,
	cut,
	copy,
	paste,
	find,
	mute,
	volumeup,
	volumedown,
	kp_comma = 1073741957,
	kp_equalsas400,
	alterase = 1073741977,
	sysreq,
	cancel,
	clear,
	prior = 1073741981,
	return2,
	separator,
	out_,
	oper,
	clearagain,
	crsel,
	exsel,
	kp_00 = 1073742000,
	kp_000,
	thousandsseparator,
	decimalseparator,
	currencyunit,
	currencysubunit,
	kp_leftparen,
	kp_rightparen,
	kp_leftbrace,
	kp_rightbrace,
	kp_tab,
	kp_backspace,
	kp_a,
	kp_b,
	kp_c,
	kp_d,
	kp_e,
	kp_f,
	kp_xor,
	kp_power,
	kp_percent,
	kp_less,
	kp_greater,
	kp_ampersand,
	kp_dblampersand,
	kp_verticalbar,
	kp_dblverticalbar,
	kp_colon,
	kp_hash,
	kp_space,
	kp_at,
	kp_exclam,
	kp_memstore,
	kp_memrecall,
	kp_memclear,
	kp_memadd,
	kp_memsubtract,
	kp_memmultiply,
	kp_memdivide,
	kp_plusminus,
	kp_clear,
	kp_clearentry,
	kp_binary,
	kp_octal,
	kp_decimal,
	kp_hexadecimal,

	lctrl = 1073742048,
	lshift,
	lalt,
	lgui,
	rctrl,
	rshift,
	ralt,
	rgui,
	mode = 1073742081,
	audionext,
	audioprev,
	audiostop,
	audioplay,
	audiomute,
	mediaselect,
	www,
	mail,
	calculator,
	computer,
	ac_search,
	ac_home,
	ac_back,
	ac_forward,
	ac_stop,
	ac_refresh,
	ac_bookmarks,

	brightnessdown,
	brightnessup,
	displayswitch,
	kbdillumtoggle,
	kbdillumdown,
	kbdillumup,
	eject,
	sleep
}