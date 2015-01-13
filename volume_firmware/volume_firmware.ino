#define INCREASE_VOLUME 'i'
#define DECREASE_VOLUME 'd'
#define ALIVE 'a'
#define BUTTON_SINGLE 'm'

#define PIN_HIGHBIT (4)
#define PIN_LOWBIT  (3)
#define PIN_PWR     (2)
#define BAUD    (9600)
#define DEBUG         (1)
#define VOLUME_CHANGE_DELAY 200
#define ALIVE_TIME 500
#define MUTE_DELAY 500

#define BUTTON (5)

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


unsigned long lastAlive = 0;
unsigned long lastVolumeAdjust = 0;
unsigned long lastButtonPress = 0;


void setup(){
  pinMode(PIN_HIGHBIT, INPUT);
  pinMode(PIN_LOWBIT, INPUT);
  pinMode(PIN_PWR, OUTPUT);
  pinMode(BUTTON, INPUT);
  digitalWrite(BUTTON, HIGH);
  digitalWrite(PIN_PWR, LOW);
  digitalWrite(PIN_LOWBIT, HIGH);
  digitalWrite(PIN_HIGHBIT, HIGH);
  Serial.begin(BAUD); 
}


void loop(){
  adjustVolume();
  checkButton();
  stayAlive();
}



void stayAlive(){
  unsigned long elapsedTimeSinceLastAlive = millis() - lastAlive;
  unsigned long elapsedSinceLastVolumeChange = millis() - lastVolumeAdjust;
  unsigned long elapsedSinceButtonPressed = millis() - lastButtonPress;
  
  if((elapsedTimeSinceLastAlive >= ALIVE_TIME) && (elapsedSinceLastVolumeChange >= ALIVE_TIME)
      && (elapsedSinceButtonPressed >= ALIVE_TIME)){
    Serial.print(ALIVE);
    lastAlive = millis();
  }
}



void adjustVolume(){
  state = (digitalRead(PIN_HIGHBIT) << 1) | digitalRead(PIN_LOWBIT);
  int value = encoderStates[prevState][state];
  
  if(state != prevState){
    unsigned long elapsedSinceVolumeChange = millis() - lastVolumeAdjust;
    if(elapsedSinceVolumeChange >= VOLUME_CHANGE_DELAY){
      if(value == -1){
        Serial.print(DECREASE_VOLUME);
        lastVolumeAdjust = millis();
      }
      else if(value == 1){
        Serial.print(INCREASE_VOLUME);
        lastVolumeAdjust = millis();
      }
    }
  }
  
  prevState = state;
}



void checkButton(){
  boolean buttonPressed = (digitalRead(BUTTON) == LOW);
  unsigned long elapsedSinceButtonPress = millis() - lastButtonPress;
  
  if(buttonPressed && (elapsedSinceButtonPress >= MUTE_DELAY)){
    Serial.print(BUTTON_SINGLE);
    lastButtonPress = millis();
  }
}


