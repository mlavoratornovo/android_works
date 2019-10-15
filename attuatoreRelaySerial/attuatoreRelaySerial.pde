#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define COMANDO 'C'

/*Attuatore per un relay. Relay collegato al pin 8
*/
const int relayPin =  8;

void setup() {
  pinMode(relayPin, OUTPUT);
  Serial.begin(38400);
}

void loop(){
  if(Serial.available()){
    byte first =Serial.read();
    delay(25);
    if(first==COMANDO){
      if(Serial.available()){
        first = Serial.read();
        if(first==APRI){
          digitalWrite(relayPin, HIGH);
        }
        else if(first==CHIUDI){
          digitalWrite(relayPin, LOW);
        }
        else if(first==RIPRISTINA){
          digitalWrite(relayPin, LOW);
        }
      }
    }
  }
}    



