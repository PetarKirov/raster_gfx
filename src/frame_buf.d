module frame_buf;

import ae.utils.graphics.image : Image;
import primitives : Size;

public import color;

struct FrameBuf
{
	Image!Color img;
	Size pixelSize;

	alias img this;

	this(uint imageWidth, uint imageHeight, uint pixelWidth = 1, uint pixelHeight = 1)
	{
		this.img.size(imageWidth, imageHeight);
		this.pixelSize = Size(pixelWidth, pixelHeight);
	}
}