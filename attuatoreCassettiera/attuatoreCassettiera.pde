/* il firmware apre e chiude una serratura sino a quando il meccanismo non arriva a fine corsa sia in apertura che in chiusura.
*  Se viene aperto il cassetto (cassettoApertoVal == LOW) quando la serratura è chiusa (fineCorsaChiudiVal == HIGH) viene inviata una eccezione
* all'unita logica.
* L'inidirizzo dell'unità logica viene inviato all'attuatore con il comando 'S' che lo registra in una variabile.
* I comandi sono composti da due byte il primo e in tipo di messaggio inviato 1 = comando e il secondo è il comando.
* nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino
*/

#include <XBee.h>
#define RICHIESTASETUP 'T'
#define ECCEZIONE 'X'

XBee xbee = XBee();
ZBRxResponse rx = ZBRxResponse();
XBeeAddress64 addr64;
uint8_t payload[] = {'0','0'};
ZBTxRequest zbTx;
int xbee_pin = 12;

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
  pinMode(xbee_pin,OUTPUT);
  digitalWrite(xbee_pin,LOW);
  xbee.begin(9600);
  pinMode(switchCassettoAperto, INPUT);
  pinMode(switchFineCorsaApri, INPUT);
  pinMode(switchFineCorsaChiudi, INPUT);
  //pinMode(debugLed, OUTPUT);
  
  int i;
  for(i=4;i<8;i++)
    pinMode(i, OUTPUT);
  
  fineCorsaApriVal = digitalRead(switchFineCorsaApri);
  fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
  cassettoApertoVal = digitalRead(switchCassettoAperto);  
//  attachInterrupt(0, doChangeswitchCassettoAperto, FALLING);
  delay(10000);
  digitalWrite(xbee_pin,HIGH);
  addr64 = XBeeAddress64(0x00000000,0x0000ffff);
  payload[0] = RICHIESTASETUP;
  zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
  //xbee.send(zbTx);
  sendX();
  delay(1000);
  sendX();
}

void sendX(){
  digitalWrite(xbee_pin,LOW);
  delay(10);
  xbee.send(zbTx);
  delay(10);
  digitalWrite(xbee_pin,HIGH);
}


void loop(){
  cassettoApertoVal = digitalRead(switchCassettoAperto);  
  if ((lastCommand == closeCommand) && (fineCorsaChiudiVal == LOW) && (cassettoApertoVal == HIGH)){
    chiudiM1(255);
  }
  
  doChangeswitchCassettoAperto();
   
  xbee.readPacket();
  
  if(xbee.getResponse().isAvailable()){
   if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {        
     xbee.getResponse().getZBRxResponse(rx);
     if (rx.getData(0) == command){
       lastCommand = rx.getData(1);
       
       if (lastCommand == openCommand){
         apriM1(255);
       }
       
       if (lastCommand == closeCommand){
         cassettoApertoVal = digitalRead(switchCassettoAperto);  
         chiudiM1(255);
       }
     }
     if (rx.getData(0) == setupAddressCommand){       
         addr64 = rx.getRemoteAddress64();
         indirizzoValido = 1;
     }
   }
  
    
  }
  
}

void sendEccezione(){
  if(indirizzoValido){
    payload[0] = ECCEZIONE;
    payload[1] = 8;
    zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
    sendX();
    //xbee.send(zbTx);
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

/*void debugled(int number, int time){
  for (int i = 0; i < number; i++){
   digitalWrite(debugLed,HIGH);
   delay(time);
   digitalWrite(debugLed,LOW);
   delay(time);
  }
}*/

