#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define COMANDO 'C'

/*Attuatore per il salvaschermo con cavo FTDI TTL-232 cable -  TTL-232R 3.3V. Collegare: Rosso con i 3.3v di arduino, Nero con il gnd di Arduino e Grigio/Marrone CTS con output 8
di arduino
*/
const int relayPin =  8;

void setup() {
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH);
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
            attivaRelay();
        }
        else if(first==CHIUDI){
            disattivaRelay();
        }
        else if(first==RIPRISTINA){
            disattivaRelay();
        }
      }
    }
  }
}

void disattivaRelay(){
      digitalWrite(relayPin, HIGH);
}

void attivaRelay(){
      digitalWrite(relayPin, LOW);
}



