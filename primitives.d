module primitives;

struct Point
{
	uint x;
	uint y;

	this(uint x, uint y)
	{
		this.x = x;
		this.y = y;
	}

	this(uint x, uint y, Size pixelSize)
	{
		this.x = x / pixelSize.x;
		this.y = y / pixelSize.y;
	}

	Point opBinary(string op)(Point other) if (op == "+" || op == "-")
	{
		return Point(x + other.x, y + other.y);
	}
}

alias Size = Point;

struct Line
{
	Point start;
	Point end;
}
