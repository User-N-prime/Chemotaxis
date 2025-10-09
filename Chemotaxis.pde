agent[] bob = new agent[10];

int CELL_SIZE = 20;
int GRID_SIZE = 800 / CELL_SIZE;
int CANVAS_SIZE = GRID_SIZE * CELL_SIZE;

int genLength = 5 * GRID_SIZE;
int genTime = 0;
int genCount = 0;

float flipChance = 0.6;

ArrayList<ArrayList<int[]>> topMoves = new ArrayList<>();
ArrayList<ArrayList<int[]>> bestBob = new ArrayList<>();

class agent {
  int x, y;
  double fitness;
 
  ArrayList<int[]> movementHistory;

  agent() {
    x = 0;
    y = 0;
    fitness = 0;
    movementHistory = new ArrayList<int[]>();
  }

  void show() {
    fill(255, 0, 0, 150);
    rect(CELL_SIZE * x + 5, CELL_SIZE * y + 5, CELL_SIZE - 5, CELL_SIZE - 5);
  }

  void move() {
    int stepIndex = movementHistory.size();
    int dx = 0, dy = 0;
    int count = 0;
   
    for (ArrayList<int[]> path : topMoves) {
      if (path.size() > stepIndex) {
        dx += path.get(stepIndex)[0];
        dy += path.get(stepIndex)[1];
        count++;
      }
    }
   
    if (count > 0) {
      if (Math.random() > flipChance) {
        dx = dx / count + (int)(Math.random() * 2 - 0.5);
        dy = dy / count + (int)(Math.random() * 2 - 0.5);
        if (Math.random() < flipChance)
          dx *= -1;
        if (Math.random() < flipChance)
          dy *= -1;
      }
    }

    else {
      dx = new int[]{-1, 0, 1}[(int)(Math.random() * 3)];
      dy = new int[]{-1, 0, 1}[(int)(Math.random() * 3)];
    }
   
    x += dx;
    y += dy;
    x = constrain(x, 0, GRID_SIZE - 1);
    y = constrain(y, 0, GRID_SIZE - 1);
    movementHistory.add(new int[]{dx, dy});
  }

  void evaluateFitness() {
    int tx = GRID_SIZE - 1;
    int ty = GRID_SIZE - 1;
    fitness = 1.0 / (dist(x, y, tx, ty) + 1);
  }
 
  void reset() {
    x = 0;
    y = 0;
    fitness = 0;
    movementHistory.clear();
  }
}

void settings() {
  size(CANVAS_SIZE + 5, CANVAS_SIZE + 5);
}

void setup() {
  frameRate(1000);
  for (int i = 0; i < bob.length; i++)
    bob[i] = new agent();
}

void draw() {
  background(0);

  // Draw grid
  for (int i = 0; i <= CANVAS_SIZE; i += CELL_SIZE) {
    fill(255);
    noStroke();
    rect(i, 0, 5, CANVAS_SIZE + 5);
    rect(0, i, CANVAS_SIZE + 5, 5);
  }

  // Draw target
  fill(0, 255, 0);
  rect(CELL_SIZE * (GRID_SIZE - 1) + 5, CELL_SIZE * (GRID_SIZE - 1) + 5, CELL_SIZE - 5, CELL_SIZE - 5);

  // Show and move agents
  for (int i = 0; i < bob.length; i++) {
    bob[i].show();
    bob[i].move();
  }

  genTime++;

  // Selection logic
  if (genTime >= genLength) {
    topMoves.clear();
    for (int i = 0; i < bob.length; i++) {
      bob[i].evaluateFitness();
    }

    // Sort agents by fitness (descending)
    for (int i = 0; i < bob.length - 1; i++) {
      for (int j = i + 1; j < bob.length; j++) {
        if (bob[j].fitness > bob[i].fitness) {
          agent temp = bob[i];
          bob[i] = bob[j];
          bob[j] = temp;
        }
      }
    }
   
    for (int i = 0; i < bob.length / 2; i++)
      topMoves.add(new ArrayList<int[]>(bob[i].movementHistory));
     
    if (genCount > 0)
      bestBob.add(new ArrayList<int[]>(bob[0].movementHistory));
     
    if (!bestBob.isEmpty()) {
      // Replace the last (worst) entry in topMoves with the most recent best from bestBob
      topMoves.set(topMoves.size() - 1, new ArrayList<int[]>(bestBob.get(bestBob.size() - 1)));
    }
   
    for (int i = 0; i < bob.length; i++) {
      bob[i].reset();
    }

    flipChance -= 0.05 * (float)Math.tanh(genCount / 10.00);
    genTime = 0;
    genCount++;
  }
}
