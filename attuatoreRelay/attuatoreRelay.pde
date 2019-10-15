#include <XBee.h>

#define APRI 3
#define CHIUDI 4
#define RIPRISTINA 1
#define SETUP 'S'
#define COMANDO 'C'
#define RICHIESTASETUP 'T'

/*Attuatore per un relay. Relay collegato al pin 8
nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino
*/
const int relayPin =  8;
XBee xbee = XBee();
XBeeAddress64 addr64;
byte indirizzoValido = 0;
uint8_t payload[]={0,0};
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
ZBRxResponse rx = ZBRxResponse();
ZBTxRequest zbTx;
int xbee_pin = 12;


void setup() {
  pinMode(relayPin, OUTPUT);
  pinMode(xbee_pin,OUTPUT);
  digitalWrite(xbee_pin,LOW);
  //pinMode(12, OUTPUT);
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


/*void flashLed(int times, int wait) {
    
    for (int i = 0; i < times; i++) {
      digitalWrite(12, HIGH);
      delay(wait);
      digitalWrite(12, LOW);
      
      if (i + 1 < times) {
        delay(wait);
      }
    }
}*/

void loop(){
  xbee.readPacket();
  if(xbee.getResponse().isAvailable()){
      if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {        
        xbee.getResponse().getZBTxStatusResponse(txStatus);
      }
      else if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {        
          xbee.getResponse().getZBRxResponse(rx);
       // flashLed(1,1000);
        if(rx.getData(0)==COMANDO){
          if(rx.getData(1)==APRI){
            digitalWrite(relayPin, HIGH);
          }
          else if(rx.getData(1)==CHIUDI){
            digitalWrite(relayPin, LOW);
          }
          else if(rx.getData(1)==RIPRISTINA){
            digitalWrite(relayPin, LOW);
          }
        }
        if(rx.getData(0)==SETUP){
            addr64 = rx.getRemoteAddress64();
            indirizzoValido = 1;
        }
      }    
  }
}



