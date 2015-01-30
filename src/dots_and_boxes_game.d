module dots_and_boxes_game;

import frame_buf, frame_watch, sdl_gui;

enum Player : ubyte
{
	none,
	red,
	blue
}

enum BoxSide : ubyte
{
	empty	= 0b0000,
	up		= 0b0001,
	down	= 0b0010,
	left	= 0b0100,
	right	= 0b1000,
	all		= 0b1111,
}

BoxSide opposite(BoxSide side)
{
	switch (side) with (BoxSide)
	{
		case up: return BoxSide.down;
		case down: return BoxSide.up;
		case left: return BoxSide.right;
		case right: return BoxSide.left;
		default: assert(0);
	}
}

BoxSide getFreeSide(BoxSide boxSides)
{
	foreach (side; getSides())
		if ((boxSides & side) == 0)
			return side;
	
	return BoxSide.all;
}

immutable(BoxSide[]) getSides()
{
	static immutable BoxSide[] sides = [BoxSide.up, BoxSide.down, BoxSide.left, BoxSide.right];
	return sides;
}

struct BoxState
{
	BoxSide sides;
	Player belongsTo;

	this(BoxSide sides, Player belongsTo)
	{
		if (sides == BoxSide.all)
			assert(belongsTo == Player.red || belongsTo == Player.blue);
		else if (sides < BoxSide.all)
			assert(belongsTo == Player.none);

		this.belongsTo = belongsTo;
		this.sides = sides;
	}
}

struct Move
{
	Point position;
	BoxSide side;
	bool noMoreMoves = false;
}

struct GameBoard
{
	private ubyte w;
	private ubyte h;
	private BoxState[] board;
	private Player currentPlayer_;

	private long[2] playerPoints;

	@property Player currentPlayer() inout { return this.currentPlayer_; }

	@property long redPlayerPoints() inout { return playerPoints[Player.red - 1]; }
	@property long bluePlayerPoints() inout { return playerPoints[Player.blue - 1]; }

	@property long totalPointsWon() inout { return redPlayerPoints + bluePlayerPoints; }
	@property long remainingPoints() inout { return w * h - totalPointsWon; }

	@property Player winningPlayer() inout
	{
		if (redPlayerPoints > bluePlayerPoints)
			return Player.red;
		else if (redPlayerPoints < bluePlayerPoints)
			return Player.blue;
		else
			return Player.none;
	}

	void reset(ubyte gameWidth, ubyte gameHeight, Player startingPlayer)
	{
		assert(startingPlayer == Player.red || startingPlayer == Player.blue);
		assert(gameWidth > 0 && gameHeight > 0);
		auto newBoard = new BoxState[gameWidth * gameHeight];

		this.w = gameWidth;
		this.h = gameHeight;
		this.board = newBoard;
		this.currentPlayer_ = startingPlayer;
		playerPoints = [0, 0];
	}

	GameBoard clone() inout
	{
		GameBoard res;
		res.reset(w, h, currentPlayer);

		auto newBoard = new BoxState[w * h];
		newBoard[] = this.board[];
		res.board = newBoard;		

		return res;
	}

	BoxState get(Point pos) inout
	{
		return this[pos.x, pos.y];
	}

	private ref inout(BoxState) opIndex(uint x, uint y) inout
	{
		if (!(x < w))
			assert(0);
		if (!(y < h))
			assert(0);

		return board[y * w + x];
	}

	@property Size size()
	{
		return Size(w, h);
	}

	bool set(Move m)
	{
		ubyte i = m.position.x;
		ubyte j = m.position.y;

		assert((this[i, j].sides & m.side) == 0 &&
		       this[i, j].sides != BoxSide.all);

		this[i, j].sides |= m.side;

		auto neighbour = m.position.neighbour(m.side);
		auto neighbourSide = m.side.opposite;

		if (this.size.inRange(neighbour))
		{
			assert((this[neighbour.x, neighbour.y].sides & neighbourSide) == 0 &&
			       this[neighbour.x, neighbour.y].sides != BoxSide.all);

			this[neighbour.x, neighbour.y].sides |= neighbourSide;

			claimBox(neighbour);
		}

		if (this[i, j].sides == BoxSide.all || (this.size.inRange(neighbour) && this.get(neighbour).sides == BoxSide.all))
			this.claimBox(m.position); // Gain additional turn
		else
			this.changeTurn();

		return remainingPoints != 0;
	}

	private void changeTurn()
	{
		final switch(this.currentPlayer_)
		{
			case Player.blue: currentPlayer_ = Player.red; break;
			case Player.red: currentPlayer_ = Player.blue; break;
			case Player.none: assert(0, "Invalid turn");
		}
	}

	private void claimBox(Point pos)
	{
		assert(this[pos.x, pos.y].belongsTo == Player.none);

		if (this[pos.x, pos.y].sides == BoxSide.all)
		{
			this[pos.x, pos.y].belongsTo = this.currentPlayer;

			playerPoints[currentPlayer - 1]++;
		}
	}

	bool nextPossibleMove(ref Move m)
	{
		foreach(ubyte y; 0 .. this.h)
			foreach (ubyte x; 0 .. this.w)
				if (this.get(Point(x, y)).sides != BoxSide.all)
				{
					auto box = this.get(Point(x, y));
					
					m = Move(Point(x, y), box.sides.getFreeSide);
					
					return true;
				}
		
		return false;
	}

	bool nextRandomPossibleMove(ref Move m)
	{
		if (remainingPoints == 0)
			return false;

		import std.random : uniform;

		BoxSide side = BoxSide.all;
		size_t idx;

		while (side == BoxSide.all)
		{
			idx = uniform(0, board.length);

			side = board[idx].sides.getFreeSide;
		}

		m = Move(Point(cast(ubyte)(idx % w), cast(ubyte)(idx / w)), side);
		return true;
	}

	long score(Player p) inout
	{
		Player enemy = p == Player.red? Player.blue : Player.red;

		return playerPoints[p - 1] - playerPoints[enemy - 1];
	}

	Move[] generatePossibleMoves() inout
	{
		Move[] result;

		foreach(ubyte y; 0 .. this.h)
		{
			foreach (ubyte x; 0 .. this.w)
			{
				if (this.get(Point(x, y)).sides != BoxSide.all)
				{
					auto box = this.get(Point(x, y));
					auto move =  Move(Point(x, y), box.sides.getFreeSide);
					result ~= move;
				}
			}
		}

		return result;
	}

	static Move choice;
	enum maxDepth = 3;

	import std.typecons : Tuple, tuple;

	alias MinimaxRes = Tuple!(long, Move);

	static MinimaxRes minimax(const ref GameBoard game, Player targetPlayer, uint depth)
	{
		if (game.remainingPoints == 0 || depth >= maxDepth)
			return tuple(game.score(targetPlayer), Move.init);

		auto allPossibleMoves = game.generatePossibleMoves();
		size_t len = allPossibleMoves.length;

		import std.stdio : writefln;
		writefln("minimax at %s depth, %s possible moves", depth, len);

		import std.algorithm : min, max;
		if (game.currentPlayer == targetPlayer) // This is the max calculation
		{			
			long bestValue = long.min;
			Move bestMove;

			foreach (move; allPossibleMoves)
			{
				auto possible_game = game.clone();
				possible_game.set(move);
				long val = minimax(possible_game, targetPlayer, depth + 1)[0];

				if (val > bestValue)
				{
					bestValue = val;
					bestMove = move;
				}
			}
			
			return tuple(bestValue, bestMove);
		}
		else // This is the min calculation
		{			
			long bestValue = long.max;
			Move bestMove;

			foreach (move; allPossibleMoves)
			{
				auto possible_game = game.clone();
				possible_game.set(move);
				long val = minimax(possible_game, targetPlayer, depth + 1)[0];
				
				if (val < bestValue)
				{
					bestValue = val;
					bestMove = move;
				}
			}

			return tuple(bestValue, bestMove);
		}
	}

	bool nextPossibleMinMaxMove(ref Move m)
	{
		auto res = minimax(this, currentPlayer, 0);

		m = res[1];

		if (m != Move.init)
			return true;
		else
			return false;
	}
}

class DotsAndBoxesGame
{
	private
	{
		Player ai;
		GameBoard gameBoard;
		bool isGameRunning;

		DotsAndBoxesUI ui;
	}

	this(FrameBuf img, SdlGui gui, FrameWatch fw, ubyte gameWidth, ubyte gameHeight, Player startingPlayer = Player.red, Player ai = Player.none)
	{
		assert(ai == Player.none || ai == Player.red || ai == Player.blue);

		this.gameBoard.reset(gameWidth, gameHeight, startingPlayer);
		this.ui = new DotsAndBoxesUI(img, gui, fw, this);
		this.ai = ai;
		this.isGameRunning = true;
	}

	void gameLoop()
	{
		import std.datetime : msecs;

		ui.setTitle("Dots and boxes game");
		ui.clearFrameBuf();
		//ui.wait(500.msecs);
		ui.draw();

		while (gameRunning)
		{
			if (!this.nextMove())
				endGame();

			ui.draw();
			ui.wait(250.msecs);
		}
	}

	@property bool gameRunning()
	{
		return !ui.isQuitRequested && isGameRunning;
	}

	bool nextMove()
	{
		import std.stdio : writefln;

		Move move;

		do
		{
			move = getMove();

			"%s player clicked %s side of box at (%s, %s).".writefln(gameBoard.currentPlayer, move.side, move.position.x, move.position.y);
		}
		while (gameRunning && (move.side == BoxSide.empty
		       || (gameBoard.get(move.position).sides & move.side) != 0) && move.noMoreMoves != false);
		       
		ui.drawNewSide(move.position, move.side);

		if (gameRunning)
			return gameBoard.set(move);
		else
			return true;
	}

	Move getMove()
	{
		import std.string : format;

		ui.setTitle("%s player turn".format(gameBoard.currentPlayer));

		if (ai == gameBoard.currentPlayer)
			return getAIMove();
		else
			return ui.getPlayerMove();
	}
	
	Move getAIMove()
	{
		Move m;

		if (!gameBoard.nextPossibleMinMaxMove(m))
			m.noMoreMoves = true;

		return m;
	}

	void endGame()
	{
		import std.string : format;

		ui.draw();
		ui.setTitle("%s player won! Result: %s:%s".format(
			gameBoard.winningPlayer,
			gameBoard.redPlayerPoints,
			gameBoard.bluePlayerPoints));

		isGameRunning = false;
	}
}

private class DotsAndBoxesUI
{
	import color, primitives : ScreenPoint, ScreenSize;
	import std.datetime : msecs;

	FrameBuf img;
	SdlGui gui;
	FrameWatch frameWatch;
	DotsAndBoxesGame game;

	enum gameBoardRelLen = 0.8;
	enum dotRelRadius = 0.1;
	enum dotColor = Color(30, 30, 30);
	enum boxSideColor = Color.Gray;
	enum redPlayerColor = Color.Chocolate;
	enum bluePlayerColor = Color.SteelBlue;
	enum backgroundColor = Color.Gainsboro;

	enum animationStopTime = 0.msecs;

	this(FrameBuf img, SdlGui gui, FrameWatch fw, DotsAndBoxesGame game)
	{
		this.img = img;
		this.gui = gui;
		this.frameWatch = fw;
		this.game = game;
	}

	void setTitle(string title)
	{
		this.gui.setTitle(title);
	}

	void wait(Duration time)
	{
		frameWatch.throttleBack(time);
	}

	@property bool isQuitRequested()
	{
		return gui.isQuitRequested;
	}

	PointF topLeftRelative()
	{
		auto relSize = gameBoardSizeRelative();

		return PointF((1f - relSize.w) / 2, (1f - relSize.h) / 2);
	}

	ScreenSize topLeft()
	{
		auto size = gameBoardSize();

		return ScreenPoint.make((img.w - size.x) / 2, (img.h - size.y) / 2);
	}

	SizeF gameBoardSizeRelative()
	{
		auto size = gameBoardSize();

		return SizeF(size.x / cast(float)img.w, size.y / cast(float)img.h);
	}

	// For square boxes
	ScreenSize gameBoardSize()
	{
		// Because we want square boxes we need to determine
		// the length of the box side (or line length).
		// We use the longest of the two game board sides
		// (e.g. (3x5) -> 5; (7x2) -> 7)
		// and divide the corresponding image side by it
		// (after the whole image side is multiplied by the
		// desired relative size of the game bord.

		import std.math : round;

		Size sizeInUnits = game.gameBoard.size;
		ScreenSize sizeInPixels;
		uint lineLenInPixels;

		if (sizeInUnits.w > sizeInUnits.h)
		{
			sizeInPixels.x = cast(uint)round(img.w * gameBoardRelLen);
			lineLenInPixels = sizeInPixels.x / sizeInUnits.w;
			sizeInPixels.y = lineLenInPixels * sizeInUnits.h;
		}
		else
		{
			sizeInPixels.y = cast(uint)round(img.h * gameBoardRelLen);
			lineLenInPixels = sizeInPixels.y / sizeInUnits.h;
			sizeInPixels.x = lineLenInPixels * sizeInUnits.w;
		}

		return sizeInPixels;
	}

	uint lineLengthInPixels()
	{
		auto sizeInPixels = gameBoardSize();
		auto sizeInUnits = game.gameBoard.size;

		// we want square boxes
		assert (sizeInPixels.x / sizeInUnits.w == sizeInPixels.y / sizeInUnits.h);

		return sizeInPixels.x / sizeInUnits.w;
	}

	uint radiusInPixels()
	{
		import std.math : round;

		uint r = cast(uint)round(lineLengthInPixels() * dotRelRadius);
		return r > 3? r : 3;
	}

	BoxSide getClosestSide(float x, float y, float maxDelta = 0.1)
	{
		assert(x >= 0f && y >= 0f, "x and y should be >= 0!");
		assert(maxDelta > 0.0f && maxDelta < 0.5, "maxDelta should be in the range (0, 0.5)!");

		import std.math : modf, round;

		real tmp;
		float fracX = modf(x, tmp);
		float fracY = modf(y, tmp);

		if (fracX < fracY && fracX < maxDelta) return BoxSide.left;
		if (fracY < fracX && fracY < maxDelta) return BoxSide.up;

		if (fracX > fracY && (1 - fracX) <= maxDelta) { x = round(x); return BoxSide.right; }
		if (fracY > fracX && (1 - fracY) <= maxDelta) { y = round(y);  return BoxSide.down; }

		return BoxSide.empty;
	}

	Move getPlayerMove(string msg = null)
	{
		import primitives : ScreenPoint;
		import std.math : abs;

		auto pos = ScreenPoint(gui.getPoint(msg), img.metrics);

		auto topLeftRel = topLeftRelative();
		auto sizeRel = gameBoardSizeRelative();

		auto posWholeScreenRel = PointF(pos.x / cast(float)img.w, pos.y / cast(float)img.h);

		auto relPosGameBoard = (posWholeScreenRel - topLeftRel) / sizeRel;

		clamp(relPosGameBoard.x, 0.0, 0.975, 0.05);
		clamp(relPosGameBoard.y, 0.0, 0.975, 0.05);

		if (relPosGameBoard.x == float.infinity || relPosGameBoard.y == float.infinity)
			return Move.init;

		auto size = game.gameBoard.size();

		float xF = relPosGameBoard.x * size.w;
		float yF = relPosGameBoard.y * size.h;

		float maxDelta = dotRelRadius * 2;

		BoxSide closestSide = getClosestSide(xF, yF, maxDelta);

		ubyte x = cast(ubyte)xF;
		ubyte y = cast(ubyte)yF;

		return Move(Point(x, y), closestSide);
	}

	void drawNewSide(Point pos, BoxSide newSide)
	{
		gui.drawWithFiber(img, new Fiber(
		{
			drawBox(pos, lineLengthInPixels(), radiusInPixels(), newSide);
		}), frameWatch, animationStopTime);
	}

	void drawSlowly()
	{
		gui.drawWithFiber(img, new Fiber(
		{
			draw();
		}), frameWatch, animationStopTime);
	}

	void clearFrameBuf()
	{
		img.clear(backgroundColor);
		gui.draw(img);
	}

	void draw()
	{
		auto sizeInUnits = game.gameBoard.size;
		uint lineLen = lineLengthInPixels();
		uint r = radiusInPixels();
		
		foreach (ubyte j; 0 .. sizeInUnits.h)
			foreach (ubyte i; 0 .. sizeInUnits.w)
				drawBox(Point(i, j), lineLen, r);

		gui.draw(img);
	}

	void drawBox(Point pos, uint lineLength, uint dotRadius, BoxSide newSide = BoxSide.empty)
	{
		import primitives : ScreenLine; import std.stdio : writefln;
		import raster_methods : drawBresenhamCircle, drawBresenhamLine, SimpleFloodFill_4;

		auto start = topLeft();
		uint xStart = start.x, yStart = start.y;
		uint lineLen = lineLengthInPixels();
		auto x = xStart + pos.x * lineLen;
		auto y = yStart + pos.y * lineLen;

		auto p1 =  ScreenPoint.make(x, y);
		auto p2 = ScreenPoint.make(x + lineLength, y);
		auto p3 = ScreenPoint.make(x, y + lineLength);
		auto p4 = ScreenPoint.make(x + lineLength, y + lineLength);

		auto pCenter = ScreenPoint.make(x + lineLength / 2, y + lineLength / 2);

		auto box = game.gameBoard.get(pos);

		if (newSide == BoxSide.empty)
		{
			if (pos.x == 0 && pos.y == 0) img.drawBresenhamCircle(p1, dotRadius, dotColor);
			if (pos.x >= 0 && pos.y == 0) img.drawBresenhamCircle(p2, dotRadius, dotColor);
			if (pos.x == 0 && pos.y >= 0) img.drawBresenhamCircle(p3, dotRadius, dotColor);
			if (pos.x >= 0 && pos.y >= 0) img.drawBresenhamCircle(p4, dotRadius, dotColor);
			
			
			if ((box.sides & BoxSide.up) && (pos.y == 0))
				img.drawBresenhamLine(ScreenLine(p1, p2), boxSideColor);
			
			if (box.sides & BoxSide.right)
				img.drawBresenhamLine(ScreenLine(p2, p4), boxSideColor);
			
			if (box.sides & BoxSide.down)
				img.drawBresenhamLine(ScreenLine(p4, p3), boxSideColor);
			
			if ((box.sides & BoxSide.left) && (pos.x == 0))
				img.drawBresenhamLine(ScreenLine(p3, p1), boxSideColor);
		}
		else
		{
			if (newSide == BoxSide.up)
				img.drawBresenhamLine(ScreenLine(p1, p2), boxSideColor);

			else if (newSide == BoxSide.right)
				img.drawBresenhamLine(ScreenLine(p2, p4), boxSideColor);

			else if (newSide == BoxSide.down)
				img.drawBresenhamLine(ScreenLine(p3, p4), boxSideColor);

			else if (newSide == BoxSide.left)
				img.drawBresenhamLine(ScreenLine(p3, p1), boxSideColor);
			else
				assert(0, "newSide should be up, left, down, or right!");
		}


		if (box.belongsTo == Player.red)
			img.SimpleFloodFill_4(pCenter, redPlayerColor, backgroundColor);
		if (box.belongsTo == Player.blue)
			img.SimpleFloodFill_4(pCenter, bluePlayerColor, backgroundColor);
	}
}

unittest
{
	auto bRed = BoxState(BoxSides.all, Player.red);
	auto bBlue = BoxState(BoxSides.all, Player.blue);

	auto bLeftOnly = BoxState(cast(BoxSides)(BoxSides.up | BoxSides.down | BoxSides.right), Player.none);
	auto bRightOnly = BoxState(cast(BoxSides)(BoxSides.up | BoxSides.down | BoxSides.left), Player.none);
	auto bUpOnly = BoxState(cast(BoxSides)(BoxSides.down | BoxSides.left | BoxSides.right), Player.none);
	auto bDownOnly = BoxState(cast(BoxSides)(BoxSides.up | BoxSides.left | BoxSides.right), Player.none);

	auto bUp = BoxState(BoxSides.up, Player.none);
	auto bDown = BoxState(BoxSides.down, Player.none);
	auto bLeft = BoxState(BoxSides.left, Player.none);
	auto bRight = BoxState(BoxSides.right, Player.none);

	assert(bRed.getFreeSide == BoxSides.all);
	assert(bBlue.getFreeSide == BoxSides.all);

	assert(bLeftOnly.getFreeSide == BoxSides.left);
	assert(bRightOnly.getFreeSide == BoxSides.right);
	assert(bUpOnly.getFreeSide == BoxSides.up);
	assert(bDownOnly.getFreeSide == BoxSides.down);

	assert(bUp.getFreeSide != BoxSides.all && bUp.getFreeSide != BoxSides.all && bUp.getFreeSide != BoxSides.up);
	assert(bDown.getFreeSide != BoxSides.all && bDown.getFreeSide != BoxSides.all && bDown.getFreeSide != BoxSides.down);
	assert(bLeft.getFreeSide != BoxSides.all && bLeft.getFreeSide != BoxSides.all && bLeft.getFreeSide != BoxSides.left);
	assert(bRight.getFreeSide != BoxSides.all && bRight.getFreeSide != BoxSides.all && bRight.getFreeSide != BoxSides.right);
}

struct Point
{
	ubyte x;
	ubyte y;

	Point neighbour(BoxSide side)
	{
		switch (side) with (BoxSide)
		{
			case up: return Point(x, cast(ubyte)(y - 1));
			case down: return Point(x, cast(ubyte)(y + 1));
			case left: return Point(cast(ubyte)(x - 1), y);
			case right: return Point(cast(ubyte)(x + 1), y);
			default: assert(0);
		}
	}
}

struct Size
{
	ubyte w;
	ubyte h;

	bool inRange(Point p)
	{
		return p.x >= 0 && p.x < this.w &&
			p.y >= 0 && p.y < this.h;
	}
}

struct PointF
{
	float x;
	float y;

	PointF opSub(PointF other)
	{
		return PointF(x - other.x, y - other.y);
	}

	PointF opDiv(SizeF size)
	{
		return PointF(x / size.w, y / size.h);
	}
}

struct SizeF
{
	float w;
	float h;
}

float clamp(ref float val, float min, float max, float maxDelta)
{
	if (val >= min && val <= max)
		return val;
	
	if (val < min && min - val < maxDelta)
		val = min;
	else if (val > max && val - max < maxDelta)
		val = max;
	else
		val = float.infinity;
	
	return val;
}

size_t maxPos(uint[] arr)
{
	uint max = uint.min;
	size_t pos = 0;

	foreach (i, x; arr)
		if (x >= max)
		{
			max = x;
			pos = i;
		}

	return pos;
}

size_t minPos(uint[] arr)
{
	uint min = uint.max;
	size_t pos = 0;

	foreach (i, x; arr)
		if (x <= min)
		{
			min = x;
			pos = i;
		}

	return pos;
}

