import java.util.Collections;

int cols = 20;
int rows = 20;
int cellSize = 40;
int spawnX = cols / 2;
int spawnY = rows - 2;
float margin = 4;
boolean[][] wallGrid = new boolean[cols][rows];
ArrayList<PVector> noveltyArchive = new ArrayList<PVector>();
float noveltyThreshold = 5.0; // tweak based on grid size

int[][] directions = {
  {0, -1}, // up
  {0, 1},  // down
  {-1, 0}, // left
  {1, 0}   // right
};

int numAgents = 50;
int lifespan = 100;
int generation = 0;
int frameCountInGen = 0;

Agent[] agents;
PVector target;

int mousePressCount = 0;
boolean simRunning = false;

void settings() {
  size(cols * cellSize + 100, rows * cellSize);
}

void setup() {
  surface.setResizable(true);
  frameRate(10); // slow rate
  target = new PVector(cols / 2, 2); // grid coords
  agents = new Agent[numAgents];
  for (int i = 0; i < numAgents; i++) {
    agents[i] = new Agent();
  }
}

void draw() {
  background(0);
  drawGrid();
  fill(0, 255, 0);
  noStroke();
  rect(target.x * cellSize + margin, target.y * cellSize + margin,
     cellSize - 2 * margin, cellSize - 2 * margin);
     
  fill(150);
  noStroke();
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (wallGrid[x][y]) {
        rect(x * cellSize, y * cellSize, cellSize, cellSize);
      }
    }
  }

  if (simRunning) {
    for (Agent a : agents) {
      a.update();
      a.show();
    }
 
    frameCountInGen++;
    if (frameCountInGen >= lifespan) {
      evolve();
      frameCountInGen = 0;
      generation++;
    }
    }
    else {
      // agents frozen
      for (Agent a : agents) {
        a.show();
      }
    }


  fill(255);
  textAlign(CENTER);
  text("Generation: " + generation, 850, 20);
}

void drawGrid() {
  noStroke();
  fill(255);

  // vert. bars
  for (int i = 1; i <= cols; i++) {
    int x = i * cellSize;
    rect(x - 1, 0, 2, height); // 2-pixel vert bar
  }

  // Horizontal bars
  for (int j = 1; j < rows; j++) {
    int y = j * cellSize;
    rect(0, y - 1, cols * cellSize, 2); // 2-pixel hori. bar
  }
}

void evolve() {
  int topCount = numAgents / 2;
  Agent[] topAgents = new Agent[topCount];
  for (int i = 0; i < topCount; i++) {
    float bestFitness = Float.MAX_VALUE;
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
 
  for (Agent a : agents) {
    if (computeNovelty(a.behavior) > noveltyThreshold) {
      noveltyArchive.add(a.behavior);
    }
  }
}

float computeNovelty(PVector behavior) {
  int k = 10;
  ArrayList<Float> distances = new ArrayList<Float>();
  for (PVector b : noveltyArchive) {
    distances.add(PVector.dist(behavior, b));
  }
  Collections.sort(distances);
  float novelty = 0;
  for (int i = 0; i < min(k, distances.size()); i++) {
    novelty += distances.get(i);
  }
  return novelty / k;
}

void mousePressed() {
  int gx = mouseX / cellSize;
  int gy = mouseY / cellSize;

  boolean isTarget = (gx == (int)target.x && gy == (int)target.y);
  boolean isSpawn = (gx == spawnX && gy == spawnY);

  if (gx >= 0 && gx < cols && gy >= 0 && gy < rows && !isTarget && !isSpawn) {
    wallGrid[gx][gy] = !wallGrid[gx][gy]; // toggle wall state
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
    gridPos = new PVector(cols / 2, rows - 2);
    dna = new int[lifespan][2];
    for (int i = 0; i < lifespan; i++) {
      dna[i][0] = parentDNA[i][0];
      dna[i][1] = parentDNA[i][1];
      if (Math.random() < 0.01) {
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
 
    // Update behavior at end of life
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
    float goalDist = dist(gridPos.x, gridPos.y, target.x, target.y);
    float novelty = computeNovelty(behavior);
    return 0.5 * goalDist + 0.5 * novelty; // hybrid fitness
  }

  Agent reproduce() {
    return new Agent(this.dna);
  }
}
