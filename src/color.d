
Color gradient(Color from, Color to, float x)
{
	return Color(
		cast(ubyte)(x * to.r + (1 - x) * from.r),
		cast(ubyte)(x * to.g + (1 - x) * from.g),
		cast(ubyte)(x * to.b + (1 - x) * from.b),
		cast(ubyte)(x * to.a + (1 - x) * from.a));
}

struct Color
{
	union
	{
		uint value = 0xFF000000;
		struct { ubyte b, g, r, a; }
	}
	
	alias alpha = a;
	alias red = r;
	alias green = g;
	alias blue = b;

	this (uint hexColor)
	{
		this.value = hexColor;
	}
	
	this (ubyte r_, ubyte g_, ubyte b_, ubyte a_ = 255)
	{
		r = r_;
		g = g_;
		b = b_;
		a = a_;
	}
	
	T opCast(T)() if (is(T == uint))
	{
		return value;
	}
	
	//enum Color Red = Color(255, 0, 0);
	//enum Color Green = Color(0, 255, 0);
	//enum Color Blue = Color(0, 0, 255);
	//enum Color White = Color(255, 255, 255);
	//enum Color Black = Color(0, 0, 0);
	
	// Red colors
	enum Color IndianRed = Color(205, 92, 92);
	enum Color WildWatermelon = Color(249, 82, 107);
	enum Color LightCoral = Color(240, 128, 128);
	enum Color Salmon = Color(250, 128, 114);
	enum Color DarkSalmon = Color(233, 150, 122);
	enum Color LightSalmon = Color(255, 160, 122);
	enum Color Crimson = Color(220, 20, 60);
	enum Color Red = Color(255, 0, 0);
	enum Color FireBrick = Color(178, 34, 34);
	enum Color DarkRed = Color(139, 0, 0);

	// Pink colors
	enum Color FlamingoPink = Color(255, 102, 255);
	enum Color ShockingPink = Color(252, 15, 192);
	enum Color BubbleGum = Color(255, 193, 204);
	enum Color Pink = Color(255, 192, 203);
	enum Color LightPink = Color(255, 182, 193);
	enum Color HotPink = Color(255, 105, 180);
	enum Color DeepPink = Color(255, 20, 147);
	enum Color MediumVioletRed = Color(199, 21, 133);
	enum Color PaleVioletRed = Color(219, 112, 147);

	// Orange colors
	enum Color Coral = Color(255, 127, 80);
	enum Color Tomato = Color(255, 99, 71);
	enum Color OrangeRed = Color(255, 69, 0);
	enum Color DarkOrange = Color(255, 140, 0);
	enum Color Pumpkin = Color(255, 104, 17);
	enum Color Orange = Color(255, 165, 0);
	enum Color OrangeCircuit = Color(255, 191, 0);
	enum Color NeonCarrot = Color(255, 153, 51);
	enum Color AtomicTangerine = Color(255, 153, 104);
	enum Color Sunglow = Color(255, 204, 51);

	// Yellow colors
	enum Color Gold = Color(255, 215, 0);
	enum Color FluoresentYellow = Color(204, 255, 00);
	enum Color ChartreuseYellow = Color(223, 255, 0);
	enum Color Lemon = Color(253, 255, 16);
	enum Color LemonLime = Color(227, 255, 0);
	enum Color LemonGlacier = Color(253, 255, 0);
	enum Color Yellow = Color(255, 255, 0);
	enum Color Daffodil = Color(255, 255, 49);
	enum Color ElectricYellow = Color(255, 255, 51);
	enum Color LemonYellow = Color(255, 244, 79);
	enum Color LaserLemonYellow = Color(255, 255, 102);
	enum Color Canary = Color(255, 255, 178);
	enum Color LightYellow = Color(255, 255, 224);
	enum Color LemonChiffon = Color(255, 250, 205);
	enum Color LightGoldenrodYellow = Color(250, 250, 210);
	enum Color SnowFlurry = Color(228, 255, 209);
	enum Color PapayaWhip = Color(255, 239, 213);
	enum Color Moccasin = Color(255, 228, 181);
	enum Color PeachPuff = Color(255, 218, 185);
	enum Color PaleGoldenrod = Color(238, 232, 170);
	enum Color Khaki = Color(240, 230, 140);
	enum Color DarkKhaki = Color(189, 183, 107);

	// Purple colors
	enum Color Lavender = Color(230, 230, 250);
	enum Color Thistle = Color(216, 191, 216);
	enum Color Plum = Color(221, 160, 221);
	enum Color Violet = Color(238, 130, 238);
	enum Color Orchid = Color(218, 112, 214);
	enum Color Fuchsia = Color(255, 0, 255);
	enum Color Magenta = Color(255, 0, 255);
	enum Color MediumOrchid = Color(186, 85, 211);
	enum Color MediumPurple = Color(147, 112, 219);
	enum Color BlueViolet = Color(138, 43, 226);
	enum Color DarkViolet = Color(148, 0, 211);
	enum Color DarkOrchid = Color(153, 50, 204);
	enum Color DarkMagenta = Color(139, 0, 139);
	enum Color Purple = Color(128, 0, 128);
	enum Color Indigo = Color(75, 0, 130);
	enum Color SlateBlue = Color(106, 90, 205);
	enum Color DarkSlateBlue = Color(72, 61, 139);
	enum Color MediumSlateBlue = Color(123, 104, 238);

	// Brown colors
	enum Color Cornsilk = Color(255, 248, 220);
	enum Color BlanchedAlmond = Color(255, 235, 205);
	enum Color Bisque = Color(255, 228, 196);
	enum Color NavajoWhite = Color(255, 222, 173);
	enum Color Wheat = Color(245, 222, 179);
	enum Color DesertSand = Color(237, 201, 175);
	enum Color BurlyWood = Color(222, 184, 135);
	enum Color Tan = Color(210, 180, 140);
	enum Color RosyBrown = Color(188, 143, 143);
	enum Color SandyBrown = Color(244, 164, 96);
	enum Color Goldenrod = Color(218, 165, 32);
	enum Color DarkGoldenrod = Color(184, 134, 11);
	enum Color Peru = Color(205, 133, 63);
	enum Color Chocolate = Color(210, 105, 30);
	enum Color FuzzyWuzzyBrown = Color(196, 86, 85);
	enum Color SaddleBrown = Color(139, 69, 19);
	enum Color Sienna = Color(160, 82, 45);
	enum Color Brown = Color(165, 42, 42);
	enum Color Maroon = Color(128, 0, 0);

	// Green colors
	enum Color FrostedMint = Color(219, 255, 248);
	enum Color SnowyMint = Color(214, 255, 219);
	enum Color ParisDaisy = Color(255, 244, 110);
	enum Color ElectricLime = Color(204, 255, 00);
	enum Color GreenYellow = Color(173, 255, 47);
	enum Color Chartreuse = Color(127, 255, 0);
	enum Color LawnGreen = Color(124, 252, 0);
	enum Color Lime = Color(0, 255, 0);
	enum Color LimeGreen = Color(50, 205, 50);
	enum Color PaleGreen = Color(152, 251, 152);
	enum Color LightGreen = Color(144, 238, 144);
	enum Color MediumSpringGreen = Color(0, 250, 154);
	enum Color SpringGreen = Color(0, 255, 127);
	enum Color MediumSeaGreen = Color(60, 179, 113);
	enum Color SeaGreen = Color(46, 139, 87);
	enum Color ForestGreen = Color(34, 139, 34);
	enum Color Green = Color(0, 128, 0);
	enum Color DarkGreen = Color(0, 100, 0);
	enum Color YellowGreen = Color(154, 205, 50);
	enum Color OliveDrab = Color(107, 142, 35);
	enum Color Olive = Color(128, 128, 0);
	enum Color DarkOliveGreen = Color(85, 107, 47);
	enum Color MediumAquamarine = Color(102, 205, 170);
	enum Color DarkSeaGreen = Color(143, 188, 143);
	enum Color LightSeaGreen = Color(32, 178, 170);
	enum Color DarkCyan = Color(0, 139, 139);
	enum Color Teal = Color(0, 128, 128);
	
	// Blue colors
	enum Color Aqua = Color(0, 255, 255);
	enum Color Cyan = Color(0, 255, 255);
	enum Color AeroBlue = Color(201, 255, 229);
	enum Color LightCyan = Color(224, 255, 255);
	enum Color LightRainshower = Color(178, 255, 226);
	enum Color Rainshower = Color(168, 255, 224);
	enum Color PaleTurquoise = Color(175, 238, 238);
	enum Color Aquamarine = Color(127, 255, 212);
	enum Color Turquoise = Color(64, 224, 208);
	enum Color MediumTurquoise = Color(72, 209, 204);
	enum Color DarkTurquoise = Color(0, 206, 209);
	enum Color CadetBlue = Color(95, 158, 160);
	enum Color SteelBlue = Color(70, 130, 180);
	enum Color LightSteelBlue = Color(176, 196, 222);
	enum Color PowderBlue = Color(176, 224, 230);
	enum Color LightBlue = Color(173, 216, 230);
	enum Color SkyBlue = Color(135, 206, 235);
	enum Color LightSkyBlue = Color(135, 206, 250);
	enum Color DeepSkyBlue = Color(0, 191, 255);
	enum Color DodgerBlue = Color(30, 144, 255);
	enum Color FuchsiaBlue = Color(122, 88, 193);
	enum Color CornflowerBlue = Color(100, 149, 237);
	enum Color RoyalBlue = Color(65, 105, 225);
	enum Color Blue = Color(0, 0, 255);
	enum Color MediumBlue = Color(0, 0, 205);
	enum Color DarkBlue = Color(0, 0, 139);
	enum Color Navy = Color(0, 0, 128);
	enum Color MidnightBlue = Color(25, 25, 112);
	
	// White colors
	enum Color White = Color(255, 255, 255);
	enum Color Snow = Color(255, 250, 250);
	enum Color Honeydew = Color(240, 255, 240);
	enum Color MintCream = Color(245, 255, 250);
	enum Color Azure = Color(240, 255, 255);
	enum Color AliceBlue = Color(240, 248, 255);
	enum Color GhostWhite = Color(248, 248, 255);
	enum Color WhiteSmoke = Color(245, 245, 245);
	enum Color Seashell = Color(255, 245, 238);
	enum Color Beige = Color(245, 245, 220);
	enum Color OldLace = Color(253, 245, 230);
	enum Color FloralWhite = Color(255, 250, 240);
	enum Color Ivory = Color(255, 255, 240);
	enum Color AntiqueWhite = Color(250, 235, 215);
	enum Color Linen = Color(250, 240, 230);
	enum Color LavenderBlush = Color(255, 240, 245);
	enum Color MistyRose = Color(255, 228, 225);
	// Gray colors
	enum Color Platinum = Color(229, 228, 226);
	enum Color Gainsboro = Color(220, 220, 220);
	enum Color LightGrey = Color(211, 211, 211);
	enum Color Silver = Color(192, 192, 192);
	enum Color DarkGray = Color(169, 169, 169);
	enum Color Gray = Color(128, 128, 128);
	enum Color DimGray = Color(105, 105, 105);
	enum Color LightSlateGray = Color(119, 136, 153);
	enum Color SlateGray = Color(112, 128, 144);
	enum Color DarkSlateGrey = Color(47, 79, 79);
	enum Color Black = Color(0, 0, 0);
}
