agent[] bob = new agent[10];

int CELL_SIZE = 50;
int CANVAS_SIZE = 800;
int GRID_SIZE = CANVAS_SIZE / CELL_SIZE;

int genLength = 5 * GRID_SIZE;
int genTime = 0;
int genCount = 0;

float flipChance = 0.6f;

int[][][] topMoves = new int[bob.length / 2][genLength][2];
int[][][] bestBob = new int[100][genLength][2];
int bestBobCount = 0;

class agent {
  int x, y;
  double dis;
  int stepIndex;
  int[][] movementHistory;

  agent() {
    x = 0;
    y = 0;
    dis = 0;
    stepIndex = 0;
    movementHistory = new int[genLength][2];
  }

  void show() {
    fill(255, 0, 0, 150);
    rect(CELL_SIZE * x + 5, CELL_SIZE * y + 5, CELL_SIZE - 5, CELL_SIZE - 5);
  }

  void move() {
    int dx = 0, dy = 0;
    int count = 0;

    for (int[][] path : topMoves) {
      if (stepIndex < path.length) {
        dx += path[stepIndex][0];
        dy += path[stepIndex][1];
        count++;
      }
    }

    if (count > 0 && Math.random() > flipChance) {
      dx = dx / count + (int)(Math.random() * 2 - 0.5);
      dy = dy / count + (int)(Math.random() * 2 - 0.5);
      if (Math.random() < flipChance) dx *= -1;
      if (Math.random() < flipChance) dy *= -1;
    }
    else {
      dx = new int[]{-1, 0, 1}[(int)(Math.random() * 3)];
      dy = new int[]{-1, 0, 1}[(int)(Math.random() * 3)];
    }

    x += dx;
    y += dy;
    x = constrain(x, 0, GRID_SIZE - 1);
    y = constrain(y, 0, GRID_SIZE - 1);

    if (stepIndex < genLength) {
      movementHistory[stepIndex][0] = dx;
      movementHistory[stepIndex][1] = dy;
      stepIndex++;
    }
  }

  void dis() {
    int tx = GRID_SIZE - 1;
    int ty = GRID_SIZE - 1;
    dis = 1.0 / (dist(x, y, tx, ty) + 1);
  }

  void reset() {
    x = 0;
    y = 0;
    dis = 0;
    stepIndex = 0;
  }
}

void settings() {
  size(CANVAS_SIZE + 5, CANVAS_SIZE + 5);
}

void setup() {
  frameRate(10);
  for (int i = 0; i < bob.length; i++)
    bob[i] = new agent();
}

void draw() {
  background(0);

  // grid
  for (int i = 0; i <= CANVAS_SIZE; i += CELL_SIZE) {
    fill(255);
    noStroke();
    rect(i, 0, 5, CANVAS_SIZE + 5);
    rect(0, i, CANVAS_SIZE + 5, 5);
  }

  // target
  fill(0, 255, 0);
  rect(CELL_SIZE * (GRID_SIZE - 1) + 5, CELL_SIZE * (GRID_SIZE - 1) + 5, CELL_SIZE - 5, CELL_SIZE - 5);

  // show + move agents
  for (int i = 0; i < bob.length; i++) {
    bob[i].show();
    bob[i].move();
  }

  genTime++;

  // selection logic
  if (genTime >= genLength) {
    for (int i = 0; i < bob.length; i++) {
      bob[i].dis();
    }

    // sort bob[] by fitness descending (manual bubble sort)
    for (int i = 0; i < bob.length - 1; i++) {
      for (int j = 0; j < bob.length - i - 1; j++) {
        if (bob[j].dis < bob[j + 1].dis) {
          agent temp = bob[j];
          bob[j] = bob[j + 1];
          bob[j + 1] = temp;
        }
      }
    }

    for (int i = 0; i < bob.length / 2; i++) {
      for (int j = 0; j < genLength; j++) {
        topMoves[i][j][0] = bob[i].movementHistory[j][0];
        topMoves[i][j][1] = bob[i].movementHistory[j][1];
      }
    }

    if (genCount > 0 && bestBobCount < bestBob.length) {
      for (int j = 0; j < genLength; j++) {
        bestBob[bestBobCount][j][0] = bob[0].movementHistory[j][0];
        bestBob[bestBobCount][j][1] = bob[0].movementHistory[j][1];
      }
      bestBobCount++;

      for (int j = 0; j < genLength; j++) {
        topMoves[topMoves.length - 1][j][0] = bestBob[bestBobCount - 1][j][0];
        topMoves[topMoves.length - 1][j][1] = bestBob[bestBobCount - 1][j][1];
      }
    }

    for (agent a : bob) 
      a.reset();

    flipChance -= 0.05f * (float)Math.tanh(genCount / 10.0);
    genTime = 0;
    genCount++;
  }
}
