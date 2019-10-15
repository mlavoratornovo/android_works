#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define COMANDO 'C'
#define ECCEZIONE 'X'

/*Attuatore per un relay e uno switch di controllo. Relay collegato al pin 8 e switch collegato al pin 2. Invia un byte valorizzato 8 se lo switch passa da High a Low
quando il relay non e' attivo, oppure se dopo tre secondi dalla disattivazione del relay lo switch e' in stato Low.
*/
const int relayPin =  8;
const int switchPin = 2;
byte valid = 1;
uint8_t payload[] = {' ',' '};

void setup() {
  pinMode(relayPin, OUTPUT);
  pinMode(switchPin, INPUT);
  Serial.begin(38400);
}

void loop(){
  aperturaPorta();
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

void attivaRelay(){
    valid = 0;
    digitalWrite(relayPin, HIGH);
}

void sendEccezione(){
    payload[0] = ECCEZIONE;
    payload[1] = 8;
    Serial.write(payload,2);
}

void disattivaRelay(){
    digitalWrite(relayPin, LOW);
    valid = 1;
}

void aperturaPorta(){
    int stato = digitalRead(switchPin);
    if(valid){
      if(stato==LOW){
        sendEccezione();
        valid = 0;
      }
    }
}



