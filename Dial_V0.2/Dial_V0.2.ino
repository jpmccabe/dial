#include <RFduinoBLE.h>

#define INCREASE_VOLUME 'i'
#define DECREASE_VOLUME 'd'
#define SINGLE_BUTTON 's'
#define DOUBLE_BUTTON 'w'
#define HOLD_BUTTON 'h'

#define PIN_HIGHBIT (4)
#define PIN_LOWBIT  (3)
#define BUTTON (2)

#define BAUD    (9600)

#define VOLUME_CHANGE_DELAY (70)
#define BUTTON_HOLD_TIME (800)
#define BUTTON_DEBOUNCE (30)
#define BUTTON_DOUBLE_CLICK_MAX (350)
#define TIME_BEFORE_SLEEP (3000)
#define SLEEP_TIME_CONNECTED (300)
#define SLEEP_TIME_DISCONNECTED (
)


// globals
int state, prevState = 0;
/* old state, new state, change (+ means clockwise)
 * 0 2 +
 * 1 0 +
 * 2 3 +
 * 3 1 +
 * 0 1 -
 * 1 3 -
 * 2 0 -
 * 3 2 -
 */
int encoderStates[4][4] = {
 {  0, -1,  1,  0 }, 
 {  1,  0,  0, -1 }, 
 { -1,  0,  0,  1 }, 
 {  0,  1, -1,  0 }, 
};



unsigned long lastVolumeAdjust = 0;
unsigned long lastButtonPress = 0;
int sleepTime = SLEEP_TIME_DISCONNECTED;


void setup(){
  RFduinoBLE.customUUID = "80f290c5-278e-41cb-a2f9-6c1cbe18b730";
   
  pinMode(PIN_HIGHBIT, INPUT_PULLUP);
  pinMode(PIN_LOWBIT, INPUT_PULLUP);
  pinMode(BUTTON, INPUT_PULLUP);
  RFduino_pinWake(BUTTON, LOW);
  
  //Serial.begin(BAUD);
  RFduinoBLE.begin();
}



void loop(){
  checkButton();
  adjustVolume();
    
  if((millis() - lastVolumeAdjust > TIME_BEFORE_SLEEP) && (millis() - lastButtonPress > TIME_BEFORE_SLEEP)){
    //Serial.println("sleeping");
    RFduino_ULPDelay(sleepTime);
    if(RFduino_pinWoke(BUTTON)){
      RFduino_resetPinWake(BUTTON);
    }
  } 
}



void adjustVolume(){
  state = (digitalRead(PIN_HIGHBIT) << 1) | digitalRead(PIN_LOWBIT);
  int value = encoderStates[prevState][state];
  
  if(state != prevState){
    unsigned long elapsedSinceVolumeChange = millis() - lastVolumeAdjust;
    if(elapsedSinceVolumeChange >= VOLUME_CHANGE_DELAY){
      if(value == -1){
       // Serial.print(DECREASE_VOLUME);
        RFduinoBLE.sendByte(DECREASE_VOLUME);
        lastVolumeAdjust = millis();
      }
      else if(value == 1){
        //Serial.print(INCREASE_VOLUME);
        RFduinoBLE.sendByte(INCREASE_VOLUME);
        lastVolumeAdjust = millis();
      }
    }
  }
  prevState = state;
}




void checkButton(){
  boolean buttonDown = (digitalRead(BUTTON) == LOW);
  
  if(buttonDown){
    unsigned long buttonDownStartTime = millis();
    delay(BUTTON_DEBOUNCE);
    
    while(digitalRead(BUTTON) == LOW){
      if(millis()-buttonDownStartTime >= BUTTON_HOLD_TIME){
        RFduinoBLE.sendByte(HOLD_BUTTON);
        //Serial.println(HOLD_BUTTON);
        break;
      }
    }
    
    delay(BUTTON_DEBOUNCE);

    if(digitalRead(BUTTON) == HIGH){
       unsigned long buttonUpStartTime = millis();
       delay(BUTTON_DEBOUNCE);
       while(digitalRead(BUTTON) == HIGH){
         if(millis() - buttonUpStartTime > BUTTON_DOUBLE_CLICK_MAX){
          RFduinoBLE.sendByte(SINGLE_BUTTON);
          //Serial.println(SINGLE_BUTTON);
          break;
         }
       }
       delay(BUTTON_DEBOUNCE);
       if(digitalRead(BUTTON) == LOW){
         RFduinoBLE.sendByte(DOUBLE_BUTTON);
         //Serial.println(DOUBLE_BUTTON);
       }
    }
    
    while(digitalRead(BUTTON) == LOW){}
    lastButtonPress = millis();
    delay(BUTTON_DEBOUNCE);
  }
  
}


void RFduinoBLE_onConnect(){
  sleepTime = SLEEP_TIME_CONNECTED;
}

void RFduinoBLE_onDisconnect(){
  sleepTime = SLEEP_TIME_DISCONNECTED;
}

