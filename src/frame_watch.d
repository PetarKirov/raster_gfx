module frame_watch;

import std.datetime : Duration, StopWatch, msecs;
import core.thread : Thread;

struct FrameWatch
{
@trusted:

	private StopWatch sw;

	void start() { sw.start(); }

	void throttleBack(Duration frameTime)
	{
		auto timeLeft = frameTime - sw.peek();
		sw.reset();

		if (timeLeft > 1.msecs)
			Thread.sleep(timeLeft);
	}
}
