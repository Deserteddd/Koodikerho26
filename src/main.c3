module orm;
import std::io;
import std::collections::list;
import std::math::random;
import std::core::string;
import raylib5;

const int SCREENSIZE = 900;
const int CELLCOUNT  = 30;
const int CELLSIZE	 = SCREENSIZE / CELLCOUNT;
const float TICKRATE = 10;


enum Direction : (float base)
{
	UP    = 0,
	RIGHT = 1,
	DOWN  = 2,
	LEFT  = 3,
}

alias Vec2 = int[<2>];
// alias Body = List {Vec2};

struct BodySegment
{
	Vec2      pos;
	Direction dir;
}

struct Snake
{
	Direction  		  dir;
	List{BodySegment} body;
}

struct Food
{
	Vec2 pos;
	int index;
}

Food food = {
	.pos = {5, 5},
	.index = 0
};

float time_since_tick;
int score = 30;
bool paused;
Direction new_dir;

struct Assets
{
	Texture2D[4] fruits;
	Texture2D    tile;
	Texture2D	 head;
	Texture2D    mid;
	Texture2D	 tail;
	Texture2D    turn;
}

fn int main(String[] args)
{

    // The string "sum of 10 and 20 is 30" is stored
    // into buffer instead of printing on stdout

	rl::initWindow(SCREENSIZE, SCREENSIZE, "ORM");
	rl::setTargetFPS(240);

	Snake snake;
	snake.body.init_with_array(mem, {
		{{4, 10}, LEFT},
		{{5, 10}, LEFT},
		{{6, 10}, LEFT},
	});
	snake.dir = LEFT;

	Assets assets;
	assets.fruits[0] = rl::loadTexture("resources/apple.png");
	assets.fruits[1] = rl::loadTexture("resources/banana.png");
	assets.fruits[2] = rl::loadTexture("resources/grape.png");
	assets.fruits[3] = rl::loadTexture("resources/orange.png");
	assets.tile      = rl::loadTexture("resources/greytile.png");

	assets.head = rl::loadTexture("resources/snake_head.png");
	assets.mid  = rl::loadTexture("resources/snake_mid.png");
	assets.tail = rl::loadTexture("resources/snake_tail.png");
	assets.turn = rl::loadTexture("resources/snake_turn.png");

	while (!rl::windowShouldClose())
	{
		time_since_tick += rl::getFrameTime();
		if (!update(&snake)) break;
		draw(snake, assets);
	}
	io::printfn("Game over. You reached a score of: %d", score);
	return 0;
}

// returns: boolean indicating if game should continue
fn bool update(Snake* snake)
{
	if (rl::isKeyDown(rl::KEY_W) && snake.dir != DOWN)  new_dir = UP;
	if (rl::isKeyDown(rl::KEY_S) && snake.dir != UP)    new_dir = DOWN;
	if (rl::isKeyDown(rl::KEY_A) && snake.dir != RIGHT) new_dir = LEFT;
	if (rl::isKeyDown(rl::KEY_D) && snake.dir != LEFT)  new_dir = RIGHT;


	if (time_since_tick < 1/TICKRATE)
	{
		return true;
	} else {
		time_since_tick = 0;
	}

	if (rl::isKeyDown(rl::KEY_P)) paused = !paused;
	if (paused) return true;

	snake.dir = new_dir;
	BodySegment next_head = snake.body[0];
	next_head.dir = new_dir;
	switch (snake.dir)
	{
		case UP:
			next_head.pos.y -= 1;
			if (next_head.pos.y < 0) next_head.pos.y = CELLCOUNT-1;
		case DOWN:
			next_head.pos.y += 1;
			if (next_head.pos.y == CELLCOUNT) next_head.pos.y = 0;
		case LEFT:
			next_head.pos.x -= 1;
			if (next_head.pos.x < 0) next_head.pos.x = CELLCOUNT-1;
		case RIGHT:
			next_head.pos.x += 1;
			if (next_head.pos.x == CELLCOUNT) next_head.pos.x = 0;
	}


	snake.body.push_front(next_head);
	if (next_head.pos != food.pos) 
	{
		snake.body.pop()!!;
	} else {
		// Ollaan osuttu ruokaan
		score += 10;
		while (food.pos == next_head.pos)
		{
			food.pos = {rand(CELLCOUNT-1), rand(CELLCOUNT-1)};
			food.index = rand(4);
		}
	}

	// Tarkasta, osuuko käärmeen pää johonkin ruumiin osaan
	foreach (index, body_segment : snake.body)
	{
		if (index == 0) continue;
		if (body_segment.pos == snake.body[0].pos) // jos osan sijainti on sama kuin pään sijainti
		{
			return false; // Käärme törmäsi itseensä -> palauta false -> peli loppuu
		}
	}
	return true;
}

fn void draw(Snake snake, Assets assets)
{
	rl::beginDrawing();
	rl::clearBackground(rl::WHITE);

	for (int i = 0; i < CELLCOUNT; i += 2)
	{
		for (int j = 0; j < CELLCOUNT; j += 2)
		{
			Texture2D tile = assets.tile;
			rl::drawTexturePro(
				tile,
				{0, 0, tile.width, tile.height},
				{(float)i * CELLSIZE, (float)j * CELLSIZE, 2 * CELLSIZE, 2 * CELLSIZE},
				{},
				0,
				{20, 255, 100, 200}
			);
		}
	}

	// Piirretään käärme
	BodySegment previous;
	foreach (index, segment : snake.body)
	{
		defer previous = segment;
        Texture2D tex = assets.mid;

        Rectangle dest = {
            (float)(segment.pos.x * CELLSIZE + CELLSIZE/2), 
            (float)(segment.pos.y * CELLSIZE + CELLSIZE/2),
            (float)CELLSIZE, (float)CELLSIZE
        };

        float rotation = segment.dir.base * 90;

		Rectangle source = {0, 0, tex.width, tex.height};
		Vector2   origin = {(float)tex.width/2, (float)tex.height/2};

		rl::drawTexturePro(tex, source, dest, origin, rotation, rl::WHITE);
	}

	// Tää on iha huono tehdään paremmin
	Texture2D fruit = assets.fruits[food.index];

	rl::drawTexturePro(
		fruit,
		{8, 8, (float)fruit.width - 16, (float)fruit.height - 16},
		{(float)food.pos.x * CELLSIZE, (float)food.pos.y * CELLSIZE, CELLSIZE, CELLSIZE},
		{0, 0},
		0,
		rl::WHITE	
	);

	char[10] buffer;
    String score_string = string::bformat(&buffer, "%s", score);
	rl::drawText((ZString)score_string, 10, 10, 32, rl::GREEN);
	rl::endDrawing();
}