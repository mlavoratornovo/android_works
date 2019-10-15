#include <XBee.h>

#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define SETUP 'S'
#define COMANDO 'C'
#define RICHIESTASETUP 'T'

/*Attuatore per il salvaschermo con cavo FTDI TTL-232 cable -  TTL-232R 3.3V. Collegare: Rosso con i 3.3v di arduino, Nero con il gnd di Arduino e Grigio/Marrone CTS con output 8
* di arduino
* nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino
*/
const int relayPin =  8;
XBee xbee = XBee();
XBeeAddress64 addr64;
byte indirizzoValido = 0;
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
ZBRxResponse rx = ZBRxResponse();
ZBTxRequest zbTx;
uint8_t payload[] = {' ',' '};
int xbee_pin = 12;

void setup() {
  pinMode(xbee_pin,OUTPUT);
  digitalWrite(xbee_pin,LOW);
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH);
  xbee.begin(9600);
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
            indirizzoValido = 1;
        }
      }else{
        //Errore
      }
    
  }
}

void disattivaRelay(){
      digitalWrite(relayPin, HIGH);
}

void attivaRelay(){
      digitalWrite(relayPin, LOW);
}



