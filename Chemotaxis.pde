int cols = 20;
int rows = 20;
int cellSize = 40;
int spawnX = cols / 2;
int spawnY = rows - 2;
float margin = 4;

Agent[] agents;
PVector target;


int[][] directions = {
  {0, -1}, // up
  {0, 1},  // down
  {-1, 0}, // left
  {1, 0}   // right
};

int numAgents = 50;
int lifespan = 100;
int generation = 0;
float mutationRate = 0.05;
int frameCountInGen = 0;
int archiveCount = 0;
int maxArchiveSize = 500;
PVector[] noveltyArchive = new PVector[maxArchiveSize];
float noveltyThreshold = 5.0;

boolean simRunning = false;

boolean[][] wallGrid = new boolean[cols][rows];

void setup() {
  size(cols * cellSize + 100, rows * cellSize);
  frameRate(100);
  target = new PVector(cols / 2, 2);
  agents = new Agent[numAgents];
  for (int i = 0; i < numAgents; i++) {
    agents[i] = new Agent();
  }
}

void draw() {
  background(0);
  drawGrid();

  // target
  fill(0, 255, 0);
  noStroke();
  int tx = (int)target.x;
  int ty = (int)target.y;
  rect(tx * cellSize + margin, ty * cellSize + margin, cellSize - 2 * margin, cellSize - 2 * margin);

  // walls
  fill(150);
  noStroke();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (wallGrid[x][y]) {
        rect(x * cellSize, y * cellSize, cellSize, cellSize);
      }
    }
  }

  // run agents
  if (simRunning) {
    for (int i = 0; i < numAgents; i++) {
      agents[i].update();
      agents[i].show();
    }

    frameCountInGen++;
    if (frameCountInGen >= lifespan) {
      evolve();
      frameCountInGen = 0;
      generation++;
    }
  }
  else {
    for (int i = 0; i < numAgents; i++)
      agents[i].show();
  }

  int centerX = cols * cellSize + 50;
  fill(255);
  textAlign(CENTER);
  text("Generation: " + generation, centerX, 20);
}

void drawGrid() {
  noStroke();
  fill(255);
  for (int i = 1; i <= cols; i++) {
    int x = i * cellSize;
    rect(x - 1, 0, 2, height);
  }
  for (int j = 1; j < rows; j++) {
    int y = j * cellSize;
    rect(0, y - 1, cols * cellSize, 2);
  }
}

void evolve() {
  for (int i = 0; i < numAgents; i++) {
    while (agents[i].step < lifespan) {
      agents[i].update();
    }
  }

  // stores better half in memory
  int topCount = numAgents / 2;
  Agent[] topAgents = new Agent[topCount];
  for (int i = 0; i < topCount; i++) {
    float bestFitness = 999999;
    int bestIndex = -1;
    for (int j = 0; j < numAgents; j++) {
      boolean alreadySelected = false;
      for (int k = 0; k < i; k++) {
        if (agents[j] == topAgents[k]) {
          alreadySelected = true;
          break;
        }
      }
      if (!alreadySelected && agents[j].getFitness() < bestFitness) {
        bestFitness = agents[j].getFitness();
        bestIndex = j;
      }
    }
    topAgents[i] = agents[bestIndex];
  }

  Agent[] newAgents = new Agent[numAgents];
  for (int i = 0; i < numAgents; i++) {
    Agent parent = topAgents[i % topCount];
    newAgents[i] = parent.reproduce();
  }
  agents = newAgents;

  for (int i = 0; i < numAgents; i++) {
    if (agents[i].behavior != null) {
      float novelty = computeNovelty(agents[i].behavior);
      if (novelty > noveltyThreshold && archiveCount < maxArchiveSize) {
        noveltyArchive[archiveCount] = agents[i].behavior;
        archiveCount++;
      }
    }
  }
}

float computeNovelty(PVector behavior) {
  if (behavior == null) return Float.MAX_VALUE;

  int k = 10;
  float[] distances = new float[archiveCount];
  int validCount = 0;

  for (int i = 0; i < archiveCount; i++) {
    if (noveltyArchive[i] != null) {
      distances[validCount] = PVector.dist(behavior, noveltyArchive[i]);
      validCount++;
    }
  }

  // bubble sort
  for (int i = 0; i < validCount - 1; i++) {
    for (int j = 0; j < validCount - i - 1; j++) {
      if (distances[j] > distances[j + 1]) {
        float temp = distances[j];
        distances[j] = distances[j + 1];
        distances[j + 1] = temp;
      }
    }
  }

  float novelty = 0;
  for (int i = 0; i < min(k, validCount); i++) {
    novelty += distances[i];
  }
  return novelty / max(1, k); // avoid divide by zero
}

void mousePressed() {
  int gx = int(mouseX / cellSize);
  int gy = int(mouseY / cellSize);

  int tx = int(target.x);
  int ty = int(target.y);

  boolean isTarget = (gx == tx && gy == ty);
  boolean isSpawn = (gx == spawnX && gy == spawnY);

  if (gx >= 0 && gx < cols && gy >= 0 && gy < rows && !isTarget && !isSpawn) {
    wallGrid[gx][gy] = !wallGrid[gx][gy];
  }
}

void keyPressed() {
  if (key == ' ') {
    simRunning = !simRunning;
  }
}

class Agent {
  PVector gridPos;
  int[][] dna;
  int step = 0;
  PVector behavior;

  Agent() {
    gridPos = new PVector(spawnX, spawnY);
    dna = new int[lifespan][2];
    for (int i = 0; i < lifespan; i++) {
      int dir = (int)(Math.random() * 4);
      dna[i] = directions[dir];
    }
  }

  Agent(int[][] parentDNA) {
    gridPos = new PVector(spawnX, spawnY);
    dna = new int[lifespan][2];
    for (int i = 0; i < lifespan; i++) {
      dna[i][0] = parentDNA[i][0];
      dna[i][1] = parentDNA[i][1];
      if (Math.random() < mutationRate) {
        int dir = (int)(Math.random() * 4);
        dna[i] = directions[dir];
      }
    }
  }

  void update() {
    if (step < lifespan) {
      int dx = dna[step][0];
      int dy = dna[step][1];
      int newX = (int)gridPos.x + dx;
      int newY = (int)gridPos.y + dy;

      if (newX >= 0 && newX < cols && newY >= 0 && newY < rows && !wallGrid[newX][newY]) {
        gridPos.x = newX;
        gridPos.y = newY;
      }
      step++;
    }

    if (step == lifespan) {
      behavior = new PVector(gridPos.x, gridPos.y);
    }
  }

  void show() {
    fill(255, 0, 0, 150);
    noStroke();
    rect(gridPos.x * cellSize + margin, gridPos.y * cellSize + margin,
         cellSize - 2 * margin, cellSize - 2 * margin);
  }

float getFitness() {
if (behavior == null) return Float.MAX_VALUE;
float goalDist = dist(gridPos.x, gridPos.y, target.x, target.y);
float novelty = computeNovelty(behavior);
return 0.5 * goalDist + 0.5 * novelty;
}

  Agent reproduce() {
    return new Agent(this.dna);
  }
}
