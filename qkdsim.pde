import java.io.*;
import java.text.DecimalFormat;

// r to reset the graph
// c to take a picture, saved within the working directory under the folder "output"

// if N is -1, vary k for simple binning or vary n for other binning schemes
// otherwise, just use the given value as n for all bins and assume a bin size of k=1 for simple binning
public static final int N = 8;

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
long[][][] info; // stores "experimental" raw key rate

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

void refineGraph(int n, int iterations) {
  
  for(int k=0;k<graph.length;k++) { // A.
  
    SimpleBin bin = bins[k];
    
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
    
    for(int i=0;i<graph[0].length;i++) { // B.
      
      long bitsSent = info[k][i][0]; // how many time units did we transmit?
      long rawBits = info[k][i][1]; // how many output bits did we end up extracting from the input?
      
      // send in an arbitrary amount of bits, the more bits the more precise and hopefully accurate the figure
      float p = ((float)i/graph[0].length);
      
      float entropy = (-p*log(p)-(1-p)*log(1-p))/log(2);
      
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
          //print(bit?'1':'.');
          rawBits++;
        }
        
      }
      
      info[k][i][0] = bitsSent;
      info[k][i][1] = rawBits;
      
      graph[k][i] = bitsSent==0?0:(float)((double)rawBits/bitsSent/entropy);;
      //println(graph[i]);
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
  info = new long[graph.length][width][2];
  
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

void keyPressed() {
  switch(key) {
    case 'r': { // reset
      for(int i=0;i<info.length;i++) {
      for(int j=0;j<info[0].length;j++) {
      for(int k=0;k<info[0][0].length;k++) {
        info[i][j][k] = 0;
      }
      }
      }
    } break;
    case 'c': { // camera
      saveFrame("output/out.png");
    } break;
  }
}

void draw() {
  
  // allow viewer to scale the graph vertically using the mouse
  // because the graph can be pretty squished at first
  if(mousePressed) {
    scale = (1-(float)mouseY/height)*(mouseButton==LEFT?20:5);
  }
  
  background(0);
  noFill();
  
  float border = 50; // margin of 50px from the edge of the screen
  
  // draw the background
  stroke(255);
  line(border,border,border,height-border);
  line(border,height-border,width-border,height-border);
  fill(255);
  DecimalFormat df = new DecimalFormat("#.#");
  for(float i=0;i<=1;i+=.1) {
    float y = height-border-(height-border*2)*scale*i;
    line(border-5,y,border,y);
    textAlign(RIGHT,CENTER);
    text(df.format(i),border-7,y);
  }
  for(float i=0;i<=1;i+=.1) {
    float x = border+(width-border*2)*i;
    line(x,height-border+5,x,height-border);
    textAlign(CENTER,TOP);
    text(df.format(i),x,height-border+7);
  }
  
  // actually draw the graph
  noFill();
  for(int k=0;k<graph.length;k++) {
    stroke(palette[k]);
    plot(graph[k],
      border,
      height-border,
      width-border*2,
      -scale*(height-border*2));
  }
  
  surface.setTitle("FPS: "+frameRate);
}
