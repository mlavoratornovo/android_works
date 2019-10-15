#include <NewSoftSerial.h>
#include <XBee.h>
#include <EEPROM.h>

#define SETUP 'S'
#define MAX 28
#define INITIALIZE 29
#define MAXXBEE 29
#define TEMPOPERMANENZA 4000
#define TOLLERANZA 2000
#define RILEVAZIONENUOVOUTENTE 'A'
#define MANCATANUOVOUTENTE 'B'
#define TAGSCARTATO 'X'
#define RICHIESTASETUP 'T'
#define OF1 0
#define OF2 28
#define OF3 56
#define OF4 84
#define OF5 112
#define OF6 140
#define OF7 168
#define OF8 196
#define OF9 224
#define OF10 251

NewSoftSerial mySerial(2, 3);
byte corrente[INITIALIZE];
byte valid1 = 0;
byte valid2 = 0;
byte valid3 = 0;
byte valid4 = 0;
byte valid5 = 0;
byte valid6 = 0;
byte valid7 = 0;
byte valid8 = 0;
byte valid9 = 0;
byte valid10 = 0;
unsigned long time1=0;
unsigned long time2=0;
unsigned long time3=0;
unsigned long time4=0;
unsigned long time5=0;
unsigned long time6=0;
unsigned long time7=0;
unsigned long time8=0;
unsigned long time9=0;
unsigned long time10=0;
unsigned long correnteTime=0;
XBee xbee = XBee();
XBeeAddress64 addr64;
byte indirizzoValido = 0;
uint8_t payload[]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
ZBRxResponse rx = ZBRxResponse();
ZBTxRequest zbTx;
int xbee_pin = 12;

//Attuatore per rilevare taf RFID. TX0(HV) del converter sul Pin2 di arduino. RX1 (HV) del converter sul Pin3 di arduino. Sia Xbee che il lettore Rfid hanno baud a 9600 nel caso 
// in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino
void setup(){
  pinMode(xbee_pin,OUTPUT);
  digitalWrite(xbee_pin,LOW);
  xbee.begin(9600);
  mySerial.begin(9600);
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
      digitalWrite(11, HIGH);
      delay(wait);
      digitalWrite(11, LOW);
      
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
        if(rx.getData(0)==SETUP){
            addr64 = rx.getRemoteAddress64();
            zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
            indirizzoValido = 1;
            //flashLed(1,1000);
        }
      }
  }
  byte i = 0;
  correnteTime=millis();
  while(mySerial.available()){
    //leggo un RFID dalla seriale
    corrente[i] = mySerial.read();
    if(i==MAX)break;
    i++;
  }
  if(i){
  //Controllo se e' gia memorizzato
    byte trovato = 0;
    if(valid1) trovato=controllo(OF1,&time1);
    if(!trovato&&valid2) trovato=controllo(OF2,&time2);
    if(!trovato&&valid3) trovato=controllo(OF3,&time3);
    if(!trovato&&valid4) trovato=controllo(OF4,&time4);
    if(!trovato&&valid5) trovato=controllo(OF5,&time5);
    if(!trovato&&valid6) trovato=controllo(OF6,&time6);
    if(!trovato&&valid7) trovato=controllo(OF7,&time7);
    if(!trovato&&valid8) trovato=controllo(OF8,&time8);
    if(!trovato&&valid9) trovato=controllo(OF9,&time9);
    if(!trovato&&valid10) trovato=controllo(OF10,&time10);

    //se non e in memoria lo memorizzo in un array se uno e disponibile altrimenti viene scartato
    if(!trovato){
      if(!valid1)trovato=memorizza(OF1,&time1,&valid1);
      else if(!valid2)trovato=memorizza(OF2,&time2,&valid2);
      else if(!valid3)trovato=memorizza(OF3,&time3,&valid3);
      else if(!valid4)trovato=memorizza(OF4,&time4,&valid4);
      else if(!valid5)trovato=memorizza(OF5,&time5,&valid5);
      else if(!valid6)trovato=memorizza(OF6,&time6,&valid6);
      else if(!valid7)trovato=memorizza(OF7,&time7,&valid7);
      else if(!valid8)trovato=memorizza(OF8,&time8,&valid8);
      else if(!valid9)trovato=memorizza(OF9,&time9,&valid9);
      else if(!valid10)trovato=memorizza(OF10,&time10,&valid10);
    }
    //Tag da scartare gia quattro titolari
    if(!trovato){
      sendEccezione(TAGSCARTATO,corrente);
    }
  }
  uscitaTag(OF1,&time1,&valid1);
  uscitaTag(OF2,&time2,&valid2);
  uscitaTag(OF3,&time3,&valid3);
  uscitaTag(OF4,&time4,&valid4);
  uscitaTag(OF5,&time5,&valid5);
  uscitaTag(OF6,&time6,&valid6);
  uscitaTag(OF7,&time7,&valid7);
  uscitaTag(OF8,&time8,&valid8);
  uscitaTag(OF9,&time9,&valid9);
  uscitaTag(OF10,&time10,&valid10);
}

byte memorizza(int offset,unsigned long *time,byte *valido){
  //Memorizzo un nuovo RFID in memoria
  for(int j=0;j<MAX;j++){
     EEPROM.write(j+offset, corrente[j]);
    //rfid[j]=corrente[j];
  }
  *time = correnteTime;
  *valido = 1;
  sendEccezione(RILEVAZIONENUOVOUTENTE,corrente);
  //Rilevazione nuovo tag in memoria
  return 1;
}

void sendEccezione(byte eccezione,byte rfid[]){
  if(indirizzoValido){
    payload[0] = eccezione;
    for(int k=1;k<MAXXBEE;k++){
      payload[k] = rfid[k-1];
    }
    zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
    //xbee.send(zbTx);
    //flashLed(1,2000);
    sendX();
  }
}

void sendEccezione(byte eccezione,int offset){
  if(indirizzoValido){
    payload[0] = eccezione;
    for(int k=1;k<MAXXBEE;k++){
      int j = k-1;
      payload[k] = EEPROM.read(j+offset);
      //rfid[k-1];
    }
    zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
    //xbee.send(zbTx);
    //flashLed(1,2000);
    sendX();
  }
}

byte controllo(int offset,unsigned long *time){
  //verifico se il RFID e gia presente in memoria nel qual caso aggiorno il tempo di rilevamento
  byte presente = 0;
  for(int j=0;j<MAX;j++){
    byte tmp = EEPROM.read(j+offset);
    if(tmp!=corrente[j]){
      return presente;
    }
  }
  presente = 1;
  *time = correnteTime;
  return presente;
}

void uscitaTag(int offset,unsigned long *time,byte *valido){
  unsigned long diff = 0;
  if(*valido){
    diff = correnteTime - *time;
    if(diff > (TEMPOPERMANENZA+TOLLERANZA)){
      *valido = 0;
      sendEccezione(MANCATANUOVOUTENTE,offset);
    }
  }
}
