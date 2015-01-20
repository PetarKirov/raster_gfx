module frame_buf;

import ae.utils.graphics.image;
public import color;

struct FrameBuf
{
	Image!Color img;

	alias img this;

	uint xRatio;
	uint yRatio;

	this(uint width, uint height, uint xRatio = 1, uint yRatio = 1)
	{
		this.img.size(width, height);
		this.w = width;
		this.h = height;
		this.xRatio = xRatio;
		this.yRatio = yRatio;
	}
}