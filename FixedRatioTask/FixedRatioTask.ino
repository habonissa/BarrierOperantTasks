// THIS CODE IS A FIXED RATIO 1 CODE
// It opens 1+ door(s) with one nose poke
// It closes 1+ door(s) with an entry of 'c' into serial monitor
// Plug your arduino into a non-usb power source (5V) for stable results
// CREDITS TO:
// 1) https://www.makerguides.com/28byj-48-stepper-motor-arduino-tutorial/ (for stepper motor control)


//STEP 1: INITIALIZE
#include <Stepper.h>
// Define number of steps per rotation:
const int stepsPerRevolution = 1500; //this specifies how much to open or close
// Create stepper object called 'myStepper', note the pin order:
Stepper myStepper = Stepper(stepsPerRevolution, 8, 10, 9, 11);
int trial = 1; // basic trial counter
int Stat = 0; // whether door is open or closed
int NOSEpoke=A0; //analog input
// text reader components to register 'c' for door close:
int message = 0; 
String txtMsg = "";
unsigned int lastStringLength = txtMsg.length();

//STEP 2: COMPONENTS TO REGISTER ONCE
void setup() {
  // Set the speed to 5 rpm:
  myStepper.setSpeed(15); //can go up to 10-15rpm depending on where you're plugged in
Serial.begin(9600); //initialize serial monitor with 9600 baud
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  // send an intro:
  Serial.println("Begin fixed-ratio task");
  Serial.println("Trial: 1");
  pinMode(NOSEpoke,INPUT);// define a pin for touch module
}
//STEP 3: COMPONENTS TO LOOP THROUGH FOR TASK
void loop() { //FIRST OPEN
    // read the state of the pushbutton value:
 int NOSEReading = analogRead(NOSEpoke); //read input
  delay(5);
if ( NOSEReading >=999 && Stat ==0) { //"If capacative touch sensor is NOT being touched AND the door is in an opened state"... blah (sensorState == LOW when u get LeDs baack)
    Serial.println("Touched");
      myStepper.step(stepsPerRevolution);
      delay(500);
      //now cool off the stepper motor pins to avoid errors:
      digitalWrite(8, LOW);
      digitalWrite(9, LOW);
      digitalWrite(10, LOW);
      digitalWrite(11, LOW);
      digitalWrite(NOSEpoke, LOW);
       Stat = 1;
       while(analogRead(NOSEpoke>=999)); //lets touch sensor cool down from stepper motor
       while(Serial.read()>=0); //discards everything in the buffer (so that only 1 'c' at the right time closes the door later)
       trial = trial + 1;
       Serial.print("Trial: ");
       Serial.println(trial);
       }
  else if (Serial.available() > 0) { //Check if there's a new message
       char message = Serial.read(); //Read that message
  if ( message == 'c' && Stat == 1) {
      myStepper.step(-stepsPerRevolution);
      delay(500);
      //now cool off the stepper motor pins to avoid errors:
      digitalWrite(8, LOW);
      digitalWrite(9, LOW);
      digitalWrite(10, LOW);
      digitalWrite(11, LOW);
      digitalWrite(NOSEpoke, LOW); // if needed, will also help touch sensor cool down
       Stat = 0;
       while(analogRead(NOSEpoke>=999)); //lets touch sensor cool down from stepper motor
       }
    }

    }
    
