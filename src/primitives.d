module primitives;

private mixin template Access()
{
	ref auto get(string accessPattern)() inout
	{
		return mixin(accessPattern);
	}
}

struct Point2
{
	uint x;
	uint y;

pure nothrow @safe @nogc:

	uint distanceTo(const ref Point2 other)
	{
		import std.math : hypot;
		int dx = x - other.x;
		int dy = y - other.y;
		return cast(uint)hypot(dx, dy);
	}
}

Point2 up(Point2 p) { return Point2(p.x, p.y - 1); }
Point2 down(Point2 p) { return Point2(p.x, p.y + 1); }
Point2 left(Point2 p) { return Point2(p.x - 1, p.y); }
Point2 right(Point2 p) { return Point2(p.x + 1, p.y); }

Point2 upLeft(Point2 p) { return Point2(p.x - 1, p.y - 1); }
Point2 upRight(Point2 p) { return Point2(p.x + 1, p.y - 1); }
Point2 downLeft(Point2 p) { return Point2(p.x - 1, p.y + 1); }
Point2 downRight(Point2 p) { return Point2(p.x + 1, p.y + 1); }

Point2 swap(Point2 p) { return Point2(p.y, p.x); }


alias Size2 = Point2;

struct Line2
{
	Point2 start;
	Point2 end;

	mixin Access;

	alias x1 = get!"start.x";
	alias y1 = get!"start.y";
	alias x2 = get!"end.x";
	alias y2 = get!"end.y";
}

struct Rectangle2
{
	Point2 min;
	Point2 max;
}

struct Metrics
{
	Size2 screenSize;
	Size2 pixelSize;
	
	@disable this(this);
	
	this(Size2 screenSize, Size2 pixelSize)
	{
		this.screenSize = screenSize;
		this.pixelSize = pixelSize;
	}
	
	bool inRange(Point2 p) inout
	{
		return (p.x >= 0 && p.x < screenSize.x) &&
			(p.y >= 0 && p.y < screenSize.y);
	}

	bool inRange(uint x, uint y) inout
	{
		return (x >= 0 && x < screenSize.x) &&
			(y >= 0 && y < screenSize.y);
	}
}

struct ScreenPoint
{
	Point2 point;

	alias point this;

	uint distanceTo(const ref ScreenPoint other)
	{
		return this.point.distanceTo(other.point);
	}

	this(Point2 p, const ref Metrics metrics)
	{
		this(p.x, p.y, metrics);
	}

	this(uint x, uint y, const ref Metrics metrics)
	{
		this.x = x / metrics.pixelSize.x;
		this.y = y / metrics.pixelSize.y;
		assert(metrics.inRange(this), "The point is outside of the screen!");
	}

	static ScreenPoint make(uint x, uint y)
	{
		ScreenPoint res;
		res.x = x;
		res.y = y;
		return res;
	}
}

alias ScreenSize = ScreenPoint;

struct ScreenLine
{
	ScreenPoint start;
	ScreenPoint end;

	mixin Access;
	
	alias x1 = get!"start.x";
	alias y1 = get!"start.y";
	alias x2 = get!"end.x";
	alias y2 = get!"end.y";

	this(Line2 l, const ref Metrics metrics)
	{
		this(l.start.x, l.start.y, l.end.x, l.end.y, metrics);
	}

	this(const ref ScreenPoint start, const ref ScreenPoint end)
	{
		this.start = start;
		this.end = end;
	}

	this(uint x1, uint y1, uint x2, uint y2, const ref Metrics metrics)
	{
		this.start = ScreenPoint(x1, y1, metrics);
		this.end = ScreenPoint(x2, y2, metrics);
	}
}

struct ScreenRectangle
{
	ScreenPoint min;
	ScreenPoint max;

	this(const ref ScreenPoint min, const ref ScreenPoint max)
	{
		this.min = min;
		this.max = max;
	}

	this(uint xMin, uint yMin, uint xMax, uint yMax, const ref Metrics metrics)
	{
		this.min = ScreenPoint(xMin, yMin, metrics);
		this.max = ScreenPoint(xMax, yMax, metrics);
	}
}
