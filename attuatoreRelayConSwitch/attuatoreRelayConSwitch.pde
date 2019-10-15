#include <XBee.h>

#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define SETUP 'S'
#define COMANDO 'C'
#define RICHIESTASETUP 'T'
#define ECCEZIONE 'X'

/*Attuatore per un relay e uno switch di controllo. Relay collegato al pin 8 e switch collegato al pin 2. Invia un byte valorizzato 8 se lo switch passa da High a Low
quando il relay non e' attivo, oppure se dopo tre secondi dalla disattivazione del relay lo switch e' in stato Low.
nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino
*/
const int relayPin =  8;
const int switchPin = 2;
byte valid = 1;
XBee xbee = XBee();
XBeeAddress64 addr64;
byte indirizzoValido = 0;
uint8_t payload[] = {'0','0'};
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
ZBRxResponse rx = ZBRxResponse();
ZBTxRequest zbTx;
int xbee_pin = 12;

void setup() {
  pinMode(xbee_pin,OUTPUT);
  digitalWrite(xbee_pin,LOW);
  pinMode(relayPin, OUTPUT);
  pinMode(switchPin, INPUT);
  xbee.begin(9600);
  //attachInterrupt(0, aperturaPorta,FALLING);
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
  aperturaPorta();
  xbee.readPacket();
  if(xbee.getResponse().isAvailable()){

      if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {        
        xbee.getResponse().getZBTxStatusResponse(txStatus);
      }
      else if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {        
          xbee.getResponse().getZBRxResponse(rx);
        if(rx.getData(0)==COMANDO){
          if(rx.getData(1)==APRI){
            attivaRelay();
          }
          else if(rx.getData(1)==CHIUDI){
            disattivaRelay();
          }
          else if(rx.getData(1)==RIPRISTINA){
            disattivaRelay();
          }
        }
        if(rx.getData(0)==SETUP){
            addr64 = rx.getRemoteAddress64();
            zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
            indirizzoValido = 1;
        }
      }else{
        //Errore
      }
    
  }
}

void attivaRelay(){
      //detachInterrupt(0);
      valid = 0;
      digitalWrite(relayPin, HIGH);
}

void sendEccezione(){
  if(indirizzoValido){
    payload[0] = ECCEZIONE;
    payload[1] = 8;
    zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
    //xbee.send(zbTx);
    sendX();
  }
}

void disattivaRelay(){
      digitalWrite(relayPin, LOW);
      valid = 1;
/*      delay(3000);
      int stato = digitalRead(switchPin);
      if(stato==LOW){
        sendEccezione();
      }
      valid = 1;*/
      //attachInterrupt(0, aperturaPorta,FALLING);
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



