module frame_watch;

import std.datetime : Duration, StopWatch, msecs;
import core.thread : Thread;

class FrameWatch
{
@trusted:

	StopWatch sw;

	alias sw this;

	void throttleBack(Duration frameTime)
	{
		auto timeLeft = frameTime - sw.peek();
		sw.reset();

		if (timeLeft > 1.msecs)
			Thread.sleep(timeLeft);
	}

	Duration measureTime(scope void delegate() func)
	{
		import std.conv : to;

		auto t1 = this.peek();
		func();
		auto t2 = this.peek();

		return to!Duration(t2 - t1);
	}
}
