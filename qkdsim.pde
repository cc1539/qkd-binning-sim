import java.io.*;
import java.text.DecimalFormat;
import java.math.BigInteger;
import java.math.BigDecimal;

// r to reset the graph
// c to take a picture, saved within the working directory under the folder "output"

// if N is -1, vary k for simple binning or vary n for other binning schemes
// otherwise, just use the given value as n for all bins and assume a bin size of k=1 for simple binning
public static final int N = 32;

// which binning schemes are we using for each k or each n
SimpleBin[] bins = {
  
  new SimpleBin(),
  new AdaptiveBin(),
  new AdaptiveAggregatedBin(),
  new AdaptiveFraming()
  
  /*
  new SimpleBin(),
  new SimpleBin(),
  new SimpleBin(),
  new SimpleBin(),
  new SimpleBin(),
  new SimpleBin()
  */
};

float[][] graph;
float[][] theoreticalGraph;
long[][][] info; // stores "experimental" raw key rate

RandomBitStream[][] randomInfo;
float[][] randomGraph;

// color used for each plot
color[] palette = {
  color(0,0,255),   // k = 1 OR n = 2
  color(255,0,0),   // k = 2 OR n = 4
  color(255,255,0), // k = 4 OR n = 8
  color(255,0,255), // k = 8 OR n = 16
  color(0,255,255), // k = 16 OR n = 32
  color(0,255,0),   // k = 32 OR n = 64
};

float scale = 1; // scale the height of the graph

void plot(float[] data, float x, float y, float w, float h) {
  if(data==null) {
    return;
  }
  beginShape();
  for(int i=0;i<data.length;i++) {
    vertex((float)i/(data.length-1)*w+x,data[i]*h+y);
  }
  endShape();
}

void updateBinSettings(SimpleBin bin, int k, int n) {
  if(n==-1) {
    if(!bin.getClass().toString().equals("class qkdsim$SimpleBin")) {
      bin.setFrameSize((int)pow(2,k+1)); // all n are powers of 2
    } else {
      bin.setFrameSize((int)pow(2,graph.length)); // n = 2*(maximum k)
      bin.setBinSize((int)pow(2,k)); // all k are powers of 2
    }
  } else {
    bin.setFrameSize(n);
    bin.setBinSize(1);
  }
}

void refineGraph(int n, int iterations) {
  
  for(int k=0;k<graph.length;k++) { // A.
  
    SimpleBin bin = bins[k];
    updateBinSettings(bin,k,n);
    
    for(int i=0;i<graph[0].length;i++) { // B.
      
      long bitsSent = info[k][i][0]; // how many time units did we transmit?
      long rawBits = info[k][i][1]; // how many output bits did we end up extracting from the input?
      
      // send in an arbitrary amount of bits, the more bits the more precise and hopefully accurate the figure
      float p = ((float)i/graph[0].length);
      
      float entropy = (-p*log(p)-(1-p)*log(1-p))/log(2);
      
      //BitBuffer memory = new BitBuffer();
      
      for(int j=0;j<iterations;j++) {
        
        {
          boolean bit = Math.random()<p;
          bin.write(bit);
          //if(bit) { // only count photons, ignore empty time units . . . or not?
            bitsSent++;
          //}
        }
        
        // extract the bits using the chosen binning scheme.
        // for now, all we're concerned with is counting the bits.
        while(bin.ready()) {
          boolean bit = bin.read();
          //memory.write(bit);
          //outputMemory[k][i].write(bit);
          randomInfo[k][i].write(bit);
          //print(bit?'1':'.');
          rawBits++;
        }
        
      }
      
      info[k][i][0] = bitsSent;
      info[k][i][1] = rawBits;
      
      graph[k][i] = bitsSent==0?0:(float)((double)rawBits/bitsSent/entropy);
      randomGraph[k][i] = randomInfo[k][i].getRandomness();
    }
    
  }
  
}

void calculateTheoreticalGraph(int n) {
  
  for(int k=0;k<graph.length;k++) { // A.
  
    SimpleBin bin = bins[k];
    updateBinSettings(bin,k,n);
    
    for(int i=0;i<theoreticalGraph[0].length;i++) { // B.
      float p = ((float)i/theoreticalGraph[0].length);
      float entropy = (-p*log(p)-(1-p)*log(1-p))/log(2);
      theoreticalGraph[k][i] = bin.getTheoreticalRawKeyRate(p)/entropy;
    }
    
  }
  
}

void setup() {
  size(1040,840);
  noSmooth();
  
  
  // A. first dimension corresponds to bin size k in the case of simple binning
  //    OR frame size n in the case of the adaptive binning schemes
  // B. second dimension corresponds to probability of photon detection in any one time unit
  graph = new float[bins.length][width];
  theoreticalGraph = new float[bins.length][width];
  info = new long[graph.length][width][2];
  
  randomInfo = new RandomBitStream[bins.length][width];
  randomGraph = new float[bins.length][width];
  for(int i=0;i<bins.length;i++) {
  for(int j=0;j<width;j++) {
    randomInfo[i][j] = new RandomBitStream();
  }
  }
  
  
  new Thread(){public void run(){
    println("calculating theoretical graphs...");
    calculateTheoreticalGraph(N);
    println("theoretical graphs calculated");
  }}.start();
  
  new Thread(){public void run(){
    while(true) {
      try {
        Thread.sleep(1);
        // if first argument is -1, vary k for simple binning or vary n for other binning schemes
        // otherwise, just use the given value as n and assume a bin size of k=1 for simple binning
        refineGraph(N,5000);
      } catch(Exception e) {}
    }
  }}.start();
}

void reset() {
  for(int i=0;i<info.length;i++) {
  for(int j=0;j<info[0].length;j++) {
  for(int k=0;k<info[0][0].length;k++) {
    info[i][j][k] = 0;
  }
  }
  }
  for(int i=0;i<randomInfo.length;i++) {
  for(int j=0;j<randomInfo[0].length;j++) {
    randomGraph[i][j] = 0;
    randomInfo[i][j].clear();
  }
  }
}

void setRefractoryPeriod(int time) {
  if(time!=bins[0].getRefractoryPeriod()) {
    for(int i=0;i<bins.length;i++) {
      bins[i].setRefractoryPeriod(time);
    }
    reset();
  }
}

void keyPressed() {
  switch(keyCode) {
    case RIGHT: {
      setRefractoryPeriod(bins[0].getRefractoryPeriod()+1);
    } break;
    case LEFT: {
      setRefractoryPeriod(bins[0].getRefractoryPeriod()-1);
    } break;
    default: {
      if(key!=CODED) {
        switch(key) {
          case 'r': { // reset
            reset();
          } break;
          case 'c': { // camera
            saveFrame("output/####.png");
          } break;
          default: {
            if(key>='0' && key<='9') {
              int time = floor(pow(2,key-'0'-1));
              // set refractory periods
              setRefractoryPeriod(time);
            }
          } break;
        }
      }
    } break;
  }
}

public void drawGraph(float border) {
  noFill();
  for(int k=0;k<graph.length;k++) {
    
    float x = border;
    float y = height-border;
    float w = width-border*2;
    float h = -scale*(height-border*2);
    
    if(keyPressed && key=='z') {
      stroke(lerpColor(palette[k],color(0),.5));
      plot(graph[k],x,y,w,h);
      stroke(palette[k]);
      plot(theoreticalGraph[k],x,y,w,h);
    } else if(keyPressed && key=='x') {
      stroke(palette[k]);
      plot(randomGraph[k],x,y,w,h);
    } else {
      stroke(palette[k]);
      plot(graph[k],x,y,w,h);
    }
    
  }
}

public void drawLegend(float x, float y) {
  for(int i=0;i<bins.length;i++) {
    noStroke();
    fill(palette[i]);
    rect(x,y,10,10);
    fill(255);
    textAlign(LEFT,CENTER);
    text(bins[i].getAbbreviation(),x+13,y+4);
    y += 14;
  }
}

public void drawGrid(float border) {
  
  stroke(255);
  line(border-1,border,border-1,height-border);
  line(border,height-border+1,width-border,height-border+1);
  fill(255);
  DecimalFormat df = new DecimalFormat("#.#");
  for(float i=0;i<=1.01;i+=.1) {
    float y = height-border-(height-border*2)*scale*i;
    if(scale*i>1.01) {
      continue;
    }
    line(border-5-1,y,border-1,y);
    textAlign(RIGHT,CENTER);
    text(df.format(i),border-7,y);
  }
  for(float i=0;i<=1.01;i+=.1) {
    float x = border+(width-border*2)*i;
    line(x,height-border+5+1,x,height-border+1);
    textAlign(CENTER,TOP);
    text(df.format(i),x,height-border+7);
  }
  
  // draw the grid
  stroke(64);
  for(float i=0;i<=1;i+=.1) {
    float y = height-border-(height-border*2)*scale*i;
    if(scale*i>1.01) {
      continue;
    }
    line(border,y,width-border,y);
  }
  for(float i=0;i<=1;i+=.1) {
    float x = border+(width-border*2)*i;
    line(x,height-border,x,border);
  }
  
}

public void drawLabel(float border) {
  fill(255);
  textAlign(CENTER,TOP);
  text("Probability (p)",width/2,height-border+30);
  textAlign(CENTER,BOTTOM);
  ArrayList<String> info = new ArrayList<String>();
  info.add("n = "+((N==-1)?(int)pow(2,bins.length):N));
  info.add("d.t. = "+bins[0].refractoryPeriod+" units");
  text(String.join(" , ",info),width/2,border-10);
  pushMatrix();
  translate(border-30,height/2);
  rotate(-HALF_PI);
  text((keyPressed && key=='x')?"Randomness":"Photon Utilization (r/h(p))",0,-10);
  popMatrix();
}

void draw() {
  
  // allow viewer to scale the graph vertically using the mouse
  // because the graph can be pretty squished at first
  if(mousePressed) {
    scale *= exp((mouseY-pmouseY)*-1e-2);
  }
  
  background(0);
  noFill();
  
  float border = 75; // margin of 50px from the edge of the screen
  drawGrid(border); // draw the tick marks
  drawGraph(border); // actually draw the graph
  drawLegend(mouseX,mouseY);  // draw the legend
  drawLabel(border); // label the graph
  
  surface.setTitle("FPS: "+frameRate);
}
