#include <NewSoftSerial.h>
#include <XBee.h>

#define SETUP 'S'
#define MAX 28
#define INITIALIZE 29
#define MAXXBEE 29
#define TEMPOPERMANENZA 4000
#define RILEVAZIONENUOVOUTENTE 'A'
#define MANCATANUOVOUTENTE 'B'
#define TAGSCARTATO 'X'
#define RICHIESTASETUP 'T'

//28byte 1 da 0 a 27, 2 da 28 a 55, 3 da 56 a 83, 4 da 84 a 111, 5 da 112 a 139, 6 da 140 a 167, 7 da 168 a 195, 8 da 196 a 223, 9 da 224 a 251, 10 da 252 a 279
NewSoftSerial mySerial(2, 3);
byte corrente[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid1[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid2[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid3[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid4[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid5[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid6[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid7[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid8[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid9[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
byte rfid10[INITIALIZE]/*={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}*/;
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
uint8_t payload[]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
ZBRxResponse rx = ZBRxResponse();
ZBTxRequest zbTx;

void setup(){
  mySerial.begin(9600);
  xbee.begin(9600);
  delay(10000);
  addr64 = XBeeAddress64(0x00000000,0x0000ffff);
  ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
  payload[0] = RICHIESTASETUP;
  xbee.send(zbTx);
}

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
    if(valid1) trovato=controllo(rfid1,&time1);
    if(!trovato&&valid2) trovato=controllo(rfid2,&time2);
    if(!trovato&&valid3) trovato=controllo(rfid3,&time3);
    if(!trovato&&valid4) trovato=controllo(rfid4,&time4);
    if(!trovato&&valid5) trovato=controllo(rfid5,&time5);
    if(!trovato&&valid6) trovato=controllo(rfid6,&time6);
    if(!trovato&&valid7) trovato=controllo(rfid7,&time7);
    if(!trovato&&valid8) trovato=controllo(rfid8,&time8);
    if(!trovato&&valid9) trovato=controllo(rfid9,&time9);
    if(!trovato&&valid10) trovato=controllo(rfid10,&time10);

    //se non e in memoria lo memorizzo in un array se uno e disponibile altrimenti viene scartato
    if(!trovato){
      if(!valid1)trovato=memorizza(rfid1,&time1,&valid1);
      else if(!valid2)trovato=memorizza(rfid2,&time2,&valid2);
      else if(!valid3)trovato=memorizza(rfid3,&time3,&valid3);
      else if(!valid4)trovato=memorizza(rfid4,&time4,&valid4);
      else if(!valid5)trovato=memorizza(rfid5,&time5,&valid5);
      else if(!valid6)trovato=memorizza(rfid6,&time6,&valid6);
      else if(!valid7)trovato=memorizza(rfid7,&time7,&valid7);
      else if(!valid8)trovato=memorizza(rfid8,&time8,&valid8);
      else if(!valid9)trovato=memorizza(rfid9,&time9,&valid9);
      else if(!valid10)trovato=memorizza(rfid10,&time10,&valid10);
    }
    //Tag da scartare gia quattro titolari
    if(!trovato){
      sendEccezione(TAGSCARTATO,corrente);
    }
  }
  uscitaTag(rfid1,&time1,&valid1);
  uscitaTag(rfid2,&time2,&valid2);
  uscitaTag(rfid3,&time3,&valid3);
  uscitaTag(rfid4,&time4,&valid4);
  uscitaTag(rfid5,&time5,&valid5);
  uscitaTag(rfid6,&time6,&valid6);
  uscitaTag(rfid7,&time7,&valid7);
  uscitaTag(rfid8,&time8,&valid8);
  uscitaTag(rfid9,&time9,&valid9);
  uscitaTag(rfid10,&time10,&valid10);
}

byte memorizza(byte rfid[],unsigned long *time,byte *valido){
  //Memorizzo un nuovo RFID in memoria
  for(int j=0;j<MAX;j++){
    rfid[j]=corrente[j];
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
    xbee.send(zbTx);
  }
}

byte controllo(byte rfid[],unsigned long *time){
  //verifico se il RFID e gia presente in memoria nel qual caso aggiorno il tempo di rilevamento
  byte presente = 0;
  for(int j=0;j<MAX;j++){
    if(rfid[j]!=corrente[j]){
      return presente;
    }
  }
  presente = 1;
  *time = correnteTime;
  return presente;
}

void uscitaTag(byte rfid[],unsigned long *time,byte *valido){
  unsigned long diff = 0;
  if(*valido){
    diff = correnteTime - *time;
    if(diff > (TEMPOPERMANENZA+2000)){
      *valido = 0;
      sendEccezione(MANCATANUOVOUTENTE,rfid);
    }
  }
}
