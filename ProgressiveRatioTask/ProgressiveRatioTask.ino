//THIS IS A PROGRESSIVE RATIO DOOR OPENING CODE
// It opens 1+ door(s) with one nose poke on trial one, and increasing nose pokes on subsequent trials
// It closes 1+ door(s) with an entry of 'c' into serial monitor
// Plug your arduino into a non-usb power source (5V) for stable results
//CREDITS TO:
// 1) Robojax.com Touch counter 20181027 (for touch counting mechanism)
// 2) https://www.makerguides.com/28byj-48-stepper-motor-arduino-tutorial/ (for stepper motor control)

//STEP 1: INITIALIZE
#include <Stepper.h>
// Define number of steps per rotation:
const int stepsPerRevolution = 1500; //this specifies how far to open
// Create stepper object called 'myStepper', note the pin order:
Stepper myStepper = Stepper(stepsPerRevolution, 8, 10, 9, 11);
const int touchPin = A0;// the input pin where touch sensor is connected
const int touchDelay = 10;//millisecond delay between each touch
// text reader components to register 'c' for door close:
int message = 0; // to make 'r' work
String txtMsg = ""; // to make 'r' work
unsigned int lastStringLength = txtMsg.length(); 
int count=1; // variable holding the touch count number
int ratio = 1; // ratio for a particular PR trial
int Stat = 0; // binary to indicate whether door is open or closed

//STEP 2: COMPONENTS TO REGISTER ONCE
void setup() {
   // Set the speed to 5 rpm:
  myStepper.setSpeed(15); //can go up to 10-15rpm depending on where you're plugged in
  Serial.begin(9600);// initialize serial monitor with 9600 baud
    while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  Serial.println("Begin progressive-ratio task");  
  Serial.print("Ratio is: ");
  Serial.println(1);
  pinMode(touchPin,INPUT);// define a pin for touch module
  // see video ( http://bit.ly/pushbutton-resistor) on using PULLUP
   
}

//STEP 3: COMPONENTS TO LOOP THROUGH FOR TASK
void loop() {
  int touchValue = analogRead(touchPin);// read touchPin and store it in touchValue
  // if touchValue is HIGH
  // TO COUNT TOUCHES WHILE THE MOUSE TOUCH NUMBER IS BELOW RATIO:
  if(touchValue >= 999 && count <ratio&& Stat == 0) {
        count++;
        Serial.println("Touched ");
        delay(touchDelay);// touch delay time
        while(analogRead(touchPin>=999)); 
              digitalWrite(touchPin, LOW); //if needed; will also help touch sensor cool down  
  }
  // TO OPEN THE DOOR (AND COUNT THAT LAST TOUCH) ONCE THE MOUSE TOUCH NUMBER IS AT RATIO:
  else if (touchValue >= 999 && count==ratio && Stat == 0) {
    count++; //count touches in increments (of 1)
    //drive the stepper motor
    Serial.println("Touched");
      myStepper.step(stepsPerRevolution);
      delay(500);
      //now cool off the stepper motor pins to avoid errors:
      digitalWrite(8, LOW);
      digitalWrite(9, LOW);
      digitalWrite(10, LOW);
      digitalWrite(11, LOW);
      digitalWrite(touchPin, LOW); //if needed; will also help touch sensor cool down
    while(analogRead(touchPin>=999)); //this means mouse has to let go and touch again (not just hold) to have multiple touches registered; also lets touch sensor cool down
    ratio = ratio + 1; // add for PR
    count = 1; // reset touch count for next PR trial
    //print the info:
    Serial.print("Ratio is: "); 
    Serial.println(ratio);
    Stat = 1; //a binary to indicate the door is in an open state
    while(Serial.read()>=0); //discards everything in the buffer (so that only 1 'c' at the right time closes the door later)

  }
  // TO CLOSE THE DOOR:
   else if (Serial.available() > 0 && Stat == 1) { //Check if there's a new message
       char message = Serial.read(); //Read that message
  if (message == 'c' && Stat == 1) {
      myStepper.step(-stepsPerRevolution); // - before stepsPerRevolution to rotate doors in opposite diection
      delay(500);
      //now cool off the stepper motor to avoid errors:
      digitalWrite(8, LOW);
      digitalWrite(9, LOW);
      digitalWrite(10, LOW);
      digitalWrite(11, LOW);
      digitalWrite(touchPin, LOW); // if needed, will also help touch sensor cool down
      while(analogRead(touchPin>=999)); //lets touch sensor cool down from stepper motor
      Stat = 0;
  }
  
     }
}
