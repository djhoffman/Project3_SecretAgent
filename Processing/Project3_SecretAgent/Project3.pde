/*
  Project 3
  by DJ Hoffman

  Expects a string of comma-delimted Serial data from Arduino:
  ** field is 0 or 1 as a string (switch) — not used
  ** second fied is 0-4095 (potentiometer)
  ** third field is 0-4095 (LDR) — not used, we only check for 2 data fields
    
 */
 

// Importing the serial library to communicate with the Arduino 
import processing.serial.*;    

// Sound libraries
import processing.sound.*;
SoundFile lobby;
SoundFile startup;
SoundFile accessgranted;
SoundFile missiles;
SoundFile spikes;
SoundFile grapplinghook;
SoundFile phone;
SoundFile goodwork;
SoundFile scanner;
SoundFile miss;
SoundFile spi;
SoundFile hook;
SoundFile ring;

// Initializing a vairable named 'myPort' for serial communication
Serial myPort;      

// Data coming in from the data fields
// data[0] = "1" or "0"                  -- BUTTON
// data[1] = 0-4095, e.g "2049"          -- POT VALUE
// data[2] = 0-4095, e.g. "1023"        -- LDR value
String [] data;

int switchValue = 0;
int potValue = 0;
int ldrValue = 0;

// Change to appropriate index in the serial list — YOURS MIGHT BE DIFFERENT
int serialIndex = 2;

// display text
PFont drawFont;

// mapping pot values
float minPotValue = 0;
float maxPotValue = 4095;

// mapping LDR values
float minLDRValue = 0;
float maxLDRValue = 4095;

float minScan = 100;
float maxScan = 1000;

// state machine
int state;
int stateStartup = 1;
int stateMissiles = 2;
int stateSpikes = 3;
int stateGrapplingHook = 4;
int statePhoneCall = 5;
int stateFinish = 6;

//background image stuff
PImage [] bg = new PImage[4];
PImage [] watch = new PImage[4];
PImage startButton;
PImage finishButton;
PImage [] missilesAnimated = new PImage[4];
PImage [] spikesAnimated = new PImage[5];
PImage [] hooksAnimated = new PImage[5];
PImage [] phoneAnimated = new PImage[5];


//finger print scanner stuff
int y; 
int fingerPrintTop = 350;
int fingerPrintBottom = 530;

//access granted
int mouse;

// button start
int rect1Left = 765;
int rect1Top = 443;
int rect1Width = 212;
int rect1Height = 91;

// button missiles
int missLeft = 645;
int missTop = 12;
int missWidth = 72;
int missHeight = 72;

// button spikes
int spikeLeft = 736;
int spikeTop = 12;
int spikeWidth = 72;
int spikeHeight = 72;

// button grappling hook
int hookLeft = 827;
int hookTop = 12;
int hookWidth = 72;
int hookHeight = 72;

// button phone
int phoneLeft = 919;
int phoneTop = 12;
int phoneWidth = 72;
int phoneHeight = 72;

// button finish
int finishLeft = 765;
int finishTop = 443;
int finishWidth = 212;
int finishHeight = 91;

float pot = 0;
float minPot = 100;
float maxPot = 1000;

//sound button stuff SWITCH
boolean missButton = false;
boolean spiButton = false;
boolean hookButton = false;
boolean ringButton = false;

// ----------------------------SETUP----------------------------------
void setup ( ) {
  size (1000,  562);    
  
  //bg imgs
  bg[0] = loadImage("images/home.jpg");
  bg[1] = loadImage("images/bgTwo.jpg");
  bg[2] = loadImage("images/finish.png");
  bg[3] = loadImage("images/redbg.jpg");
  
  // watch imgs
  watch[0] = loadImage("images/missiles.png");
  watch[1] = loadImage("images/spikes.png");
  watch[2] = loadImage("images/grapplinghook.png");
  watch[3] = loadImage("images/phone.png");
  
  // other imgs
  startButton = loadImage("images/startbutton.png");
  finishButton = loadImage("images/finishbutton.png");
  
  smooth();
  //make animations slower
  frameRate( 12 );
  
  // missiles
  missilesAnimated[0] = loadImage( "images/miss1.png" );
  missilesAnimated[1] = loadImage( "images/miss2.png" );
  missilesAnimated[2] = loadImage( "images/miss3.png" );
  missilesAnimated[3] = loadImage( "images/miss4.png" );
  
  // spikes
  spikesAnimated[0] = loadImage( "images/spike1.png" );
  spikesAnimated[1] = loadImage( "images/spike2.png" );
  spikesAnimated[2] = loadImage( "images/spike3.png" );
  spikesAnimated[3] = loadImage( "images/spike4.png" );
  spikesAnimated[4] = loadImage( "images/spike5.png" );
  
  // hooks
  hooksAnimated[0] = loadImage( "images/hook1.png" );
  hooksAnimated[1] = loadImage( "images/hook2.png" );
  hooksAnimated[2] = loadImage( "images/hook3.png" );
  hooksAnimated[3] = loadImage( "images/hook4.png" );
  hooksAnimated[4] = loadImage( "images/hook5.png" );
  
  // phone
  phoneAnimated[0] = loadImage( "images/phone1.png" );
  phoneAnimated[1] = loadImage( "images/phone2.png" );
  phoneAnimated[2] = loadImage( "images/phone3.png" );
  phoneAnimated[3] = loadImage( "images/phone3.png" );
  phoneAnimated[4] = loadImage( "images/phone3.png" );
  
  textAlign(CENTER);
  drawFont = createFont("Helvetica", 32);
 
  // List all the available serial ports
  printArray(Serial.list());
  
  // Set the com port and the baud rate according to the Arduino IDE
  //-- use your port name
  myPort  =  new Serial (this, "/dev/cu.SLAB_USBtoUART",  115200); 
  
  //initialize at startup state
  state = stateStartup;
  
  //load sound
  loadSamples();
  
  // finger print scanner
  y = fingerPrintTop;

} 
// ----------------------------CHECK SERIAL----------------------------------
// We call this to get the data 
void checkSerial() {
  while (myPort.available() > 0) {
    String inBuffer = myPort.readString();  
    
    print(inBuffer);
    
    // This removes the end-of-line from the string 
    inBuffer = (trim(inBuffer));
    
    // This function will make an array of TWO items, 1st item = switch value, 2nd item = potValue
    data = split(inBuffer, ',');
   
   // we have THREE items — ERROR-CHECK HERE
   if( data.length >= 3 ) {
      switchValue = int(data[0]);           // first index = switch value 
      potValue = int(data[1]);               // second index = pot value
      ldrValue = int(data[2]);               // third index = LDR value
      
      // switch down indicates whether we are going to be playing a cymbal or not
      missButton = boolean(switchValue);      // convert to boolean
      spiButton = boolean(switchValue);      // convert to boolean
      hookButton = boolean(switchValue);      // convert to boolean
      ringButton = boolean(switchValue);      // convert to boolean
   } 
  }
} 
// ----------------------------DRAW----------------------------------
void draw ( ) {
  checkSerial();
  
  // POT not working?? IDK
  changeStuff();
  
  if( state == stateStartup ) {
     stateStartup();
    }
  else if( state == stateMissiles ) {
    stateMissiles();
    }
  else if( state == stateSpikes ) {
    stateSpikes();
    }
  else if( state == stateGrapplingHook ) {
    stateGrapplingHook();
    }
  else if( state == statePhoneCall ) {
    statePhoneCall();
  }
  else if( state == stateFinish ) {
    stateFinish();
  }
  else if(pot < 300) {
    println("NODFODF");
  }
  
  //~~~~~~~TESTING helpful stuff ~~~~~~~
  //~~~ mouse coordinates
   //text( "x: " + mouseX + " y: " + mouseY, mouseX, mouseY );
   ////~~~ testing for start button
   //fill(255, 35, 56, 200);
   //noStroke();
   //rect(765, 443, 212, 91, 35); // start
   ////ellipse(682, 47, 72, 72); // missile
   ////ellipse(773, 47, 72, 72); // spike
   ////ellipse(864, 47, 72, 72); // grappling hook
   ////ellipse(955, 47, 72, 72); // phone
   //rect(645, 12, 72, 72); // missile
   //rect(736, 12, 72, 72); // spike
   //rect(827, 12, 72, 72); // grappling hook
   //rect(919, 12, 72, 72); // phone
 
  }  

// ----------------------------CHANGE STATES BUTTONS----------------------------------
void mousePressed() {
  if( isMouseInRect(rect1Left, rect1Top, rect1Width, rect1Height))
    println("START BUTTON WAS PRESSED!");
  if( isMouseInMissile(missLeft, missTop, missWidth, missHeight))
    println("MISSILE BUTTON WAS PRESSED!");
  if( isMouseInSpikes(spikeLeft, spikeTop, spikeWidth, spikeHeight))
    println("SPIKES BUTTON WAS PRESSED!");
  if( isMouseInHook(hookLeft, hookTop, hookWidth, hookHeight))
    println("GRAPPLING HOOK BUTTON WAS PRESSED!");
  if( isMouseInPhone(phoneLeft, phoneTop, phoneWidth, phoneHeight))
    println("PHONE BUTTON WAS PRESSED!");
  if (state == statePhoneCall){
    if( isMouseInFinish(finishLeft, finishTop, finishWidth, finishHeight))
    println("FINISH BUTTON WAS PRESSED!");
  }
}

//pot not working IDK????
void changeStuff() {
  if (state != stateStartup && state != stateFinish) {
    if (potValue < 1023) {
      stateMissiles();
    }
    else if (potValue > 1023 && potValue < 2046) {
      stateSpikes();
    }
    else if (potValue > 2046 && potValue < 3070) {
      stateGrapplingHook();
    }
    else if (potValue > 3070 && potValue < 4095) {
      statePhoneCall();
    }
  }
}

//start button
boolean isMouseInRect(int rectL, int rectT, int rectW, int rectH) {
    if(mouseX >= rectL && mouseX <= rectL + rectW && state == stateStartup && state != stateFinish) {
      if(mouseY >= rectT && mouseY <= rectT + rectH) {
        state = stateMissiles;
        accessgranted = new SoundFile(this, "samples/accessgranted.wav");
        accessgranted.amp(2);
        accessgranted.play();
        return true;
      }
    }
  return false;
}

// missile button
boolean isMouseInMissile(int missL, int missT, int missW, int missH) {
    if(mouseX >= missL && mouseX <= missL + missW && state != stateStartup && state != stateFinish) {
      if(mouseY >= missT && mouseY <= missT + missH) {
        state = stateMissiles;
        // load voice sound 
        missiles = new SoundFile(this, "samples/missiles.wav");
        missiles.amp(3);
        missiles.play();
        return true;
      }
    }
  return false;
}

// spikes button
boolean isMouseInSpikes(int spikeL, int spikeT, int spikeW, int spikeH) {
    if(mouseX >= spikeL && mouseX <= spikeL + spikeW && state != stateStartup && state != stateFinish) {
      if(mouseY >= spikeT && mouseY <= spikeT + spikeH) {
        state = stateSpikes;
        // load voice sound 
        spikes = new SoundFile(this, "samples/spikes.wav");
        spikes.amp(3);
        spikes.play();
        return true;
      }
    }
  return false;
}

// grappling hook button
boolean isMouseInHook(int hookL, int hookT, int hookW, int hookH) {
    if(mouseX >= hookL && mouseX <= hookL + hookW && state != stateStartup && state != stateFinish) {
      if(mouseY >= hookT && mouseY <= hookT + hookH) {
        state = stateGrapplingHook;
        // load voice sound 
        grapplinghook = new SoundFile(this, "samples/grapplinghook.wav");
        grapplinghook.amp(3);
        grapplinghook.play();
        return true;
      }
    }
  return false;
}

// phone button
boolean isMouseInPhone(int phoneL, int phoneT, int phoneW, int phoneH) {
    if(mouseX >= phoneL && mouseX <= phoneL + phoneW && state != stateStartup && state != stateFinish) {
      if(mouseY >= phoneT && mouseY <= phoneT + phoneH) {
        state = statePhoneCall;
        // load voice sound 
        phone = new SoundFile(this, "samples/phone.wav");
        phone.amp(3);
        phone.play();
        return true;
      }
    }
  return false;
}

//finish button
boolean isMouseInFinish(int finishL, int finishT, int finishW, int finishH) {
    if(mouseX >= finishL && mouseX <= finishL + finishW && state == statePhoneCall) {
      if(mouseY >= finishT && mouseY <= finishT + finishH) {
        state = stateFinish;
        goodwork = new SoundFile(this, "samples/goodwork.wav");
        goodwork.amp(3);
        goodwork.play();
        return true;
      }
    }
  return false;
}

// ----------------------------BACKGROUND----------------------------------
void drawBackground() {
  if (state == stateStartup) {
   background(bg[0]);
  }
  else if (state == stateMissiles) {
   background(bg[1]);
   image(watch[0], 0, 0);
   
     //// doesn't work hwo i want...
     //if( switchValue == 1 ) {
     ////red bg
     //background(bg[3]);
     //}
  }
  else if (state == stateSpikes) {
   background(bg[1]);
   image(watch[1], 0, 0);
  }
  else if (state == stateGrapplingHook) {
   background(bg[1]);
   image(watch[2], 0, 0);
  }
  else if (state == statePhoneCall) {
   background(bg[1]);
   image(watch[3], 0, 0);
  }
  else if (state == stateFinish) {
   background(bg[1]);
   image(bg[2], 0, 0);
  }
}
// ----------------------------SOUNDS----------------------------------
void loadSamples() {
  
   miss = new SoundFile(this, "samples/miss.wav");
   miss.amp(0.09);
   
   spi = new SoundFile(this, "samples/spi.wav");
   spi.amp(2);
   
   hook = new SoundFile(this, "samples/hook.wav");
   hook.amp(1);
   
   ring = new SoundFile(this, "samples/ring.wav");
   ring.amp(0.09);
   
  if (state == stateStartup) {
    // Load lobby sound, then play 
    lobby = new SoundFile(this, "samples/lobbymusic.wav");
    lobby.amp(0.009);
    lobby.loop();
    lobby.play();
    // load voice sound 
    startup = new SoundFile(this, "samples/startup.wav");
    startup.amp(1);
    startup.play();
  }
  else if (state == stateMissiles) {
  }
  else if (state == stateSpikes) {
  }
  else if (state == stateGrapplingHook) {
  }
  else if (state == statePhoneCall) {
  }
  else if (state == stateFinish) {
  }
}
// ----------------------------STATE STARTUP----------------------------------
void stateStartup() {
  drawBackground();
  
  //finger print scanner
  stroke(56, 252, 29); //green
  strokeWeight(5);
  line(70, y, 230, y);
  y++;
  if (y > fingerPrintBottom) {
    y = fingerPrintTop;
  }
  
  //Access Granted if light over LDR value is under 250
  if(ldrValue < 250){
    drawText();
    image(startButton, 0, 0, width, height);
    
    //// scanner sound not working very well
    //scanner = new SoundFile(this, "samples/scanner.wav");
    //scanner.amp(0.4);
    //scanner.play();
  }
  
}
// ----------------------------STATE MISSILES----------------------------------
void stateMissiles() {
  drawBackground();
  
  //--- when button pressed ---
  if( switchValue == 1 ) {
    
   // monitor print
    println("switch was pressed");
    
   // watch red light on
    noStroke();
    fill(255,0,0, 150); //opaque red
    ellipse(431, 396, 65, 65);
    
   // missiles animation
   image(missilesAnimated[frameCount%4], 0, 0 );
  }
  
  //play missile sound when button pressed
  if (missButton && state == stateMissiles)
  miss.play();
}

// ----------------------------STATE SPIKES----------------------------------
void stateSpikes() {
  drawBackground();
  
  //--- when button pressed ---
  if( switchValue == 1 ) {
   
   // monitor print
    println("switch was pressed");
    
   // watch red light on
    noStroke();
    fill(255,0,0, 150); //opaque red
    ellipse(431, 396, 65, 65);
    
   // missiles animation
   image(spikesAnimated[frameCount%5], 0, 0 );
  }
  //play spike sound when button pressed
  if (spiButton && state == stateSpikes)
  spi.play();
}

// ----------------------------STATE GRAPPLING HOOK----------------------------------
void stateGrapplingHook() {
  drawBackground();
  
  //--- when button pressed ---
  if( switchValue == 1 ) {
 
   // monitor print
    println("switch was pressed");
    
   // watch red light on
    noStroke();
    fill(255,0,0, 150); //opaque red
    ellipse(431, 396, 65, 65);
    
   // missiles animation
   image(hooksAnimated[frameCount%4], 0, 0 );
  }
  //play hook sound when button pressed
  if (hookButton && state == stateGrapplingHook)
  hook.play();
}

// ----------------------------STATE PHONE CALL----------------------------------
void statePhoneCall() {
  drawBackground();
  image(finishButton, 0, 0, width, height);
  
   //--- when button pressed ---
   if( switchValue == 1 ) {
    
   // monitor print
    println("switch was pressed");
    
   // watch red light on
    noStroke();
    fill(255,0,0, 150); //opaque red
    ellipse(431, 396, 65, 65);
    
   // missiles animation
   image(phoneAnimated[frameCount%4], 0, 0 );
  }
  //play hook sound when button pressed
  if (ringButton && state == statePhoneCall)
  ring.play();
}

// ----------------------------STATE FINISH----------------------------------
void stateFinish() {
  drawBackground();
}

// ----------------------------TEXT/FONT STUFF----------------------------------
void drawText() {
  if (state == stateStartup) {
    //Identity verified
    textFont(drawFont); // calling draw font
    fill(56, 252, 29); // green
    textSize(30); // size of text
    text( "Identity", 378, height-90 );
    text( "verified!", 378, height-50 );
  }
  else if (state == stateMissiles) {
  }
  else if (state == stateSpikes) {
  }
  else if (state == stateGrapplingHook) {
  }
  else if (state == statePhoneCall) {
  }
}
// ------------------------------------------------------------------------------
