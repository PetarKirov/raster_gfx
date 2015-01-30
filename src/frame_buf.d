module frame_buf;

import ae.utils.graphics.image : Image;
import primitives : Metrics, Size2;

public import color;

class FrameBuf
{
	private Image!Color img_;
	private immutable Metrics metrics_;

	@trusted:

	@property uint w() { return metrics_.screenSize.x; }
	@property uint h() { return metrics_.screenSize.y; }
	@property ref immutable(Metrics) metrics() { return metrics_; }

	ref Color opIndex(uint x, uint y) { return img_[x, y]; }

	Color[] pixels() { return img_.pixels; }
	Color[] scanline(int y) { return img_.scanline(y); }

	void clear(Color val)
	{
		pixels[] = val;
	}

	this(uint screenWidth, uint screenHeight, uint pixelWidth = 1, uint pixelHeight = 1)
	{
		this.img_.size(screenWidth / pixelWidth, screenHeight / pixelHeight);
		this.metrics_ = Metrics(Size2(img_.w, img_.h),
							   Size2(pixelWidth, pixelHeight));
	}
}
