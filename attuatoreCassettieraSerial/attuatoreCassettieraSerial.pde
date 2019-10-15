/* il firmware apre e chiude una serratura sino a quando il meccanismo non arriva a fine corsa sia in apertura che in chiusura.
*  Se viene aperto il cassetto (cassettoApertoVal == LOW) quando la serratura è chiusa (fineCorsaChiudiVal == HIGH) viene inviata una eccezione
* all'unita logica.
* L'inidirizzo dell'unità logica viene inviato all'attuatore con il comando 'S' che lo registra in una variabile.
* I comandi sono composti da due byte il primo e in tipo di messaggio inviato 1 = comando e il secondo è il comando.
*/

#define RICHIESTASETUP 'T'
#define ECCEZIONE 'X'

int switchFineCorsaApri = 8;
int switchFineCorsaChiudi = 9;
int switchCassettoAperto = 2;

int  EN1 =   5; 
int  IN1 =   4;
byte openCommand = 3;
byte closeCommand = 4;
byte restoreCommand = 1;
char setupAddressCommand = 'S';
char command = 'C';
byte indirizzoValido = 0;

char lastCommand = ' ';

int fineCorsaApriVal = -1;
int fineCorsaChiudiVal = -1;
volatile int cassettoApertoVal = -1;
boolean sendopen = false;

void setup() {
  Serial.begin(38400);
  pinMode(switchCassettoAperto, INPUT);
  pinMode(switchFineCorsaApri, INPUT);
  pinMode(switchFineCorsaChiudi, INPUT);
  
  int i;
  for(i=4;i<8;i++)
    pinMode(i, OUTPUT);
  
  fineCorsaApriVal = digitalRead(switchFineCorsaApri);
  fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
  cassettoApertoVal = digitalRead(switchCassettoAperto);  

}

void loop(){
  cassettoApertoVal = digitalRead(switchCassettoAperto);  
  if ((lastCommand == closeCommand) && (fineCorsaChiudiVal == LOW) && (cassettoApertoVal == HIGH)){
    chiudiM1(255);
  }
  
  doChangeswitchCassettoAperto();
  
  if (Serial.available() > 0) {
    
     char conType = Serial.read();
     delay(25);
     if (conType == command){
       lastCommand = Serial.read();
       
       if (lastCommand == openCommand){
         //debugled(1,500);
         apriM1(255);
       }
       
       if (lastCommand == closeCommand){
         //debugled(2,500);
         cassettoApertoVal = digitalRead(switchCassettoAperto);  
         chiudiM1(255);
       }
     }
   }
  
    
  
  
}

void doChangeswitchCassettoAperto(){
//  cassettoApertoVal = !cassettoApertoVal;
  fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
  if (fineCorsaChiudiVal == HIGH){
    cassettoApertoVal = digitalRead(switchCassettoAperto);
    if (cassettoApertoVal == LOW){
      if (!sendopen){
        sendEccezione();  
        sendopen=true;
      }
    }
  }
}

void apriM1(int pwm){
  fineCorsaApriVal = digitalRead(switchFineCorsaApri);
  if (fineCorsaApriVal != HIGH){
    analogWrite(EN1,pwm);
    digitalWrite(IN1,HIGH);
    while (fineCorsaApriVal == LOW){
      fineCorsaApriVal = digitalRead(switchFineCorsaApri);
    }
    analogWrite(EN1,0);
    //detachInterrupt(0);
  }   
}

void chiudiM1(int pwm){
  fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
  if ((cassettoApertoVal == HIGH) && (fineCorsaChiudiVal != HIGH)){
    analogWrite(EN1,pwm);
    digitalWrite(IN1,LOW);
    while (fineCorsaChiudiVal != HIGH){
      fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
    }
    analogWrite(EN1,0);
    sendopen=false;
    //attachInterrupt(0, doChangeswitchCassettoAperto, FALLING);
  }
}

void sendEccezione(){
    Serial.print(ECCEZIONE);
    Serial.print(8);
}

/*void debugled(int number, int time){
  for (int i = 0; i < number; i++){
   digitalWrite(debugLed,HIGH);
   delay(time);
   digitalWrite(debugLed,LOW);
   delay(time);
  }
}*/

