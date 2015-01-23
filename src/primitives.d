module primitives;

struct Metrics
{
	Size screenSize;
	Size pixelSize;

	@trusted this(Size screenSize, Size pixelSize)
	{
		this.screenSize = screenSize;
		this.pixelSize = pixelSize;
	}

	@disable this(this)
	{
	}
}

struct Point
{
	uint x;
	uint y;

	@system:

	this(uint x, uint y)
	{
		this.x = x;
		this.y = y;
	}

	this(Point p)
	{
		this(p.x, p.y);
	}

	this(this)
	{
	}

	@safe:

	this(uint x, uint y, const ref Metrics metrics)
	{
		this.x = x / metrics.pixelSize.x;
		this.y = y / metrics.pixelSize.y;
		assert(metrics.screenSize.inRange(this), "The point is outside of the screen!");
	}

	this(Point p, const ref Metrics metrics)
	{
		this(p.x, p.y, metrics);
	}
}

alias Size = Point;

struct Line
{
	Point start;
	Point end;


	@system:

	this(Point start, Point end)
	{
		this.start = start;
		this.end = end;
	}

	this(uint x1, uint y1, uint x2, uint y2)
	{
		this.start = Point(x1, y1);
		this.end = Point(x2, y2);
	}

	@trusted:

	this(uint x1, uint y1, uint x2, uint y2, const ref Metrics metrics)
	{
		Point p1 = Point(x1, y1), p2 = Point(x2, y2);
		this(p1, p2, metrics);
	}

	this(const ref Point start, const ref Point end, const ref Metrics metrics)
	{
		this.start = Point(start, metrics);
		this.end = Point(end, metrics);
	}

	this(Line l, const ref Metrics metrics)
	{
		this(l.start, l.end, metrics);
	}
}

struct Rectangle
{
	Point min;
	Point max;

	@system:
	this(Point min, Point max)
	{
		this.min = min;
		this.max = max;
	}

	@trusted
	this(const ref Point min, const ref Point max, const ref Metrics metrics)
	{
		this.min = Point(min, metrics);
		this.max = Point(max, metrics);
	}

	@trusted
	this(uint minX, uint minY, uint maxX, uint maxY, const ref Metrics metrics)
	{
		this.min = Point(minX, minY, metrics);
		this.max = Point(maxX, maxY, metrics);
	}
}

Point up(Point p) { return Point(p.x, p.y - 1); }
Point down(Point p) { return Point(p.x, p.y + 1); }
Point left(Point p) { return Point(p.x - 1, p.y); }
Point right(Point p) { return Point(p.x + 1, p.y); }

Point upLeft(Point p) { return Point(p.x - 1, p.y - 1); }
Point upRight(Point p) { return Point(p.x + 1, p.y - 1); }
Point downLeft(Point p) { return Point(p.x - 1, p.y + 1); }
Point downRight(Point p) { return Point(p.x + 1, p.y + 1); }
Point swap(Point p) { return Point(p.y, p.x); }


@safe bool inRange(const ref Size screenSize, const ref Point p)
{
	return (p.x >= 0 && p.x < screenSize.x) &&
		(p.y >= 0 && p.y < screenSize.y);
}

@safe uint distanceTo(const ref Point p1, const ref Point p2)
{
	int dx = p1.x - p2.x;
	int dy = p1.y - p2.y;
	return cast(uint)((dx ^^ 2.0 + dy ^^ 2.0) ^^ 0.5);
}
