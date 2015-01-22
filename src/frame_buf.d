module frame_buf;

import ae.utils.graphics.image : Image;
import primitives : Metrics, Size;

public import color;

class FrameBuf
{
	Image!Color img;

	private immutable Metrics metrics_;

	@trusted:

	@property uint w() { return metrics_.screenSize.x; }
	@property uint h() { return metrics_.screenSize.y; }
	@property ref immutable(Metrics) metrics() { return metrics_; }

	ref Color opIndex(uint x, uint y) { return img[x, y]; }

	this(uint screenWidth, uint screenHeight, uint pixelWidth = 1, uint pixelHeight = 1)
	{
		this.img.size(screenWidth / pixelWidth, screenHeight / pixelHeight);
		this.metrics_ = Metrics(Size(img.w, img.h),
							   Size(pixelWidth, pixelHeight));
	}
}
