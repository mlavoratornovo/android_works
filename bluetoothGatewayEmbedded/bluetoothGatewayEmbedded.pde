#include <Wire.h>

#include <Fat16.h>
#include <Fat16util.h>
#include <NewSoftSerial.h>
#include <EEPROM.h>
#include <DS1307.h>

#define MAX 28
#define MAXBT 30
#define INITIALIZE 32
#define MAXXBEE 29
#define TEMPOPERMANENZA 4000
#define TOLLERANZA 2000
#define RILEVAZIONENUOVOUTENTE 'A'
#define MANCATANUOVOUTENTE 'B'
#define TAGSCARTATO 'X'
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

SdCard card;
Fat16 file;

int RTCValues[7];

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
byte indirizzoValido = 0;

NewSoftSerial debug(4,5);
NewSoftSerial mySerial(2,3);

byte bufCMD[63];
byte xbeeAntenna[8] = {0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x1};

byte defimpianto[17];
byte defutente[60];
byte defpermesso[18];

uint8_t hour=0;
uint8_t minute=0;
uint8_t second=0;
uint8_t week=0;
uint8_t year=0;
uint8_t month=0;
uint8_t date=0;

volatile int cassettoApertoVal = -1;
int switchCassettoAperto = 2;
byte openCommand = 3;
byte closeCommand = 4;
byte restoreCommand = 1;
char command = 'C';
char lastCommand = ' ';
int fineCorsaApriVal = -1;
int fineCorsaChiudiVal = -1;
boolean sendopen = false;
int  EN1 =   5; 
int  IN1 =   4;

boolean stopme =true;
void setup() 
{ 
    Serial.begin(115200);
    debug.begin(9600);
    DS1307.begin();
    mySerial.begin(9600);
    TF_card_init();
    pinMode(switchCassettoAperto, INPUT);
    fineCorsaApriVal = LOW;
    fineCorsaChiudiVal = HIGH;
    resetBufCMD();

} 
 
void loop() 
{ 
  //if (mySerial.available()){
   leggiRFID();
// } 
  cassettoApertoVal = digitalRead(switchCassettoAperto);  
  if ((lastCommand == closeCommand) && (fineCorsaChiudiVal == LOW) && (cassettoApertoVal == HIGH)){
    chiudiM1(255);
  }
  
 doChangeswitchCassettoAperto();
 /*
 int bufpos = 0;
 while (Serial.available() > 0){
   bufCMD[bufpos] = Serial.read();
   bufpos++;
   delay(25);
   stopme = false;    
 }

 if (!stopme){
   for (int i = 0; i < 63; i++){
     if (i < 62){
       debug.print(bufCMD[i]);
     }else{
       debug.println(bufCMD[i]);
     }
   }
   stopme = true;
 } 
 */

 int bufpos = 0;
 while (Serial.available() > 0){
   bufCMD[bufpos] = Serial.read();
   bufpos++;
   delay(25);

 }

    
 if ((bufCMD[0] == 0x7C) && (bufCMD[3] == 0x7C)){
   
   if ((bufCMD[1] != 0x0) && (bufCMD[2] != 0x0)){
     debug.println(bufCMD[1],HEX);
     debug.println(bufCMD[2],HEX);
  //   resetBufCMD();
   }
   
   if ((bufCMD[1] == 0x4B) && (bufCMD[2] == 0x53)){
         
     resetBufCMD();
     debug.println("richiesta rfid");
     sendLetturaRFID();          
        
   }else if ((bufCMD[1] == 0x49) && (bufCMD[2] == 0x55)){
         
     resetBufCMD();
     debug.println("inizio utenti");
     file.remove("UTENTI.TXT");
     debug.println("canc utenti");
     if (!file.open("UTENTI.TXT", O_CREAT | O_WRITE)){debug.println("err create utenti");}// flashled(errorLed, 5, 1000);
         
   }else if ((bufCMD[1] == 0x49) && (bufCMD[2] == 0x50)){
         
     resetBufCMD();
     debug.println("inizio permessi");
     file.remove("PERMESSI.TXT");
     debug.println("canc permessi");
     if (!file.open("PERMESSI.TXT", O_CREAT | O_WRITE)){debug.println("err create permessi");}// flashled(errorLed, 5, 1000);
         
   }else if ((bufCMD[1] == 0x49) && (bufCMD[2] == 0x56)){
         
     resetBufCMD();
     debug.println("inizio verbosita");
     file.remove("VERBOSIT.TXT");
     debug.println("canc verbosita");
     if (!file.open("VERBOSIT.TXT", O_CREAT | O_WRITE)){debug.println("err create verbosita");}// flashled(errorLed, 5, 1000);
         
   }else if (((bufCMD[1] == 0x46) && (bufCMD[2] == 0x55)) || 
             ((bufCMD[1] == 0x46) && (bufCMD[2] == 0x50)) || 
             ((bufCMD[1] == 0x46) && (bufCMD[2] == 0x56))){
         
     resetBufCMD();
     debug.println("chiudi file");
     file.close();
         
   }else if ((bufCMD[1] == 0x52) && (bufCMD[2] == 0x55)){
        
     for (int i=4; i < 63; i++){
       file.print(bufCMD[i], BYTE);
     }
     file.println();     
     debug.println("fine scrittura utente");
     resetBufCMD();
      
   }else if ((bufCMD[1] == 0x52) && (bufCMD[2] == 0x50)){
        
     for (int i=4; i < 22; i++){
       file.print(bufCMD[i], BYTE);
     }
     file.println();     
     debug.println("fine scrittura permesso");
     resetBufCMD();
      
   }else if ((bufCMD[1] == 0x52) && (bufCMD[2] == 0x56)){
        
     for (int i=4; i < 7; i++){
       file.print(bufCMD[i], BYTE);
     }
     file.println();     
     debug.println("fine scrittura verbosita");
     resetBufCMD();
      
   }else if ((bufCMD[1] == 0x43) && (bufCMD[2] == 0x4B)){
     
     char dataval[13];
     int x = 0;
     debug.print("impostazione data");     
     
     for (int i=4; i < 17; i++){
       dataval[x] = (char)bufCMD[i];
       debug.print(x);
       debug.print("-");
       x++;
     }
     debug.println("inizio impostazione ora");
     setDataTime(dataval);
     debug.println("fine impostazione ora");
     resetBufCMD();
      
   }else if ((bufCMD[1] == 0x54) && (bufCMD[2] == 0x4F)){
  // if di debug setting ora   
     getRtcTime();
     debug.print("anno : ");
     debug.println(year,DEC);
     debug.print("mese : ");
     debug.println(month,DEC);
     debug.print("giorno : ");
     debug.println(date,DEC);
     debug.print("ora : ");
     debug.println(hour,DEC);
     debug.print("minuti : ");
     debug.println(minute,DEC);
     debug.print("secondi : ");
     debug.println(second,DEC);
     resetBufCMD();
     
   }else if ((bufCMD[1] == 0x4C) && (bufCMD[2] == 0x4C)){

     sendLogFile();
     debug.println("fine invio log");
     resetBufCMD();
      
   }else{
     resetBufCMD();
   }
      
 }else{       
   resetBufCMD();
 }            
     
 

} 

void sendLogFile(){
  
  uint8_t payload[67];
  byte result[63];
  int i = 1;
  payload[0] = '|';
  payload[1] = 'R';
  payload[2] = 'L';
  payload[3] = '|';
  
  while (getLogLine(i, result)) {
    i++;
    for (int x=0; x<63; x++){
      payload[x+4] = result[x];
     }
     Serial.write(payload,67);
   }
   delay(500);
   Serial.print("|FL|");
}


void resetBufCMD(){
  for (int i = 0; i <63; i++){
    bufCMD[i] = 0x0;
  }
}

void leggiRFID(){
  
  byte i = 0;
  correnteTime=millis();
  while(mySerial.available()){
    //leggo un RFID dalla seriale
    corrente[i] = mySerial.read();
    if(i==MAX)break;
    i++;
  }
   
  if(i){
   /*  for (int z = 0; z < INITIALIZE; z++){
        if (z<INITIALIZE-1){
          debug.print(corrente[z]);
        }else{
          debug.println(corrente[z]);
        }    
      }
*/
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
      //scrittura eccezione file log
//      sendEccezione(TAGSCARTATO,corrente);
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

void doChangeswitchCassettoAperto(){
//  cassettoApertoVal = !cassettoApertoVal;
//  fineCorsaChiudiVal = digitalRead(switchFineCorsaChiudi);
  if (fineCorsaChiudiVal == HIGH){
    cassettoApertoVal = digitalRead(switchCassettoAperto);
    if (cassettoApertoVal == LOW){
      if (!sendopen){
//        sendEccezione();  mettere versione del metodo con firma del firmware unitalogicamega
        sendopen=true;
      }
    }
  }
}

void apriM1(int pwm){
    debug.println("apriM1");
/*  if (fineCorsaApriVal != HIGH){
    analogWrite(EN1,pwm);
    digitalWrite(IN1,HIGH);
    delay(1000);
    analogWrite(EN1,0);

    fineCorsaApriVal == HIGH;
  }   */
}

void chiudiM1(int pwm){
  debug.println("chiudiM1");
/*  if ((cassettoApertoVal == HIGH) && (fineCorsaChiudiVal != HIGH)){
    analogWrite(EN1,pwm);
    digitalWrite(IN1,LOW);
    delay(1000);
    analogWrite(EN1,0);

    sendopen=false;
  }*/
}

void uscitaTag(int offset,unsigned long *time,byte *valido){
  
  unsigned long diff = 0;
  if(*valido){
    diff = correnteTime - *time;
    if(diff > (TEMPOPERMANENZA+TOLLERANZA)){
      *valido = 0;
  //    debug.println("uscita tag");    
      doLoginLogout(xbeeAntenna, corrente, INITIALIZE-4, false);
      //sendEccezione(MANCATANUOVOUTENTE,offset); sostituire con azione logout
    }
  }
}

byte memorizza(int offset,unsigned long *time,byte *valido){
  //Memorizzo un nuovo RFID in memoria
  for(int j=0;j<MAX;j++){
     EEPROM.write(j+offset, corrente[j]);
    //rfid[j]=corrente[j];
  }
  *time = correnteTime;
  *valido = 1;
 // sendException
//  sendEccezione(RILEVAZIONENUOVOUTENTE,corrente);
  doLoginLogout(xbeeAntenna, corrente, INITIALIZE-4, true);
  //Rilevazione nuovo tag in memoria
  return 1;
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
//  debug.print("correnteTime : ");
//  debug.println(correnteTime);
  return presente;
}

void TF_card_init(void) 
{
  pinMode(8,OUTPUT);
  digitalWrite(8,HIGH);
  if (!card.init());
  if (!Fat16::init(&card));
  file.writeError = true;
}

void getRtcTime(){
    DS1307.getDate(RTCValues);
    year = RTCValues[0];
    month = RTCValues[1];
    date = RTCValues[2];
    hour = RTCValues[4];
    minute = RTCValues[5];
    second = RTCValues[6];
}

void sendLetturaRFID(){
  int i = 3;
  corrente[0] = '|';
  corrente[1] = 'K';
  corrente[2] = 'S';
  corrente[31] = '|';
  
  while(true){

    while(mySerial.available()){
      corrente[i] = mySerial.read();
      if(i==MAXBT)break;
      i++;
    }
    
    if ((corrente[3] != 0x0) && (corrente[4] != 0x0) && (corrente[5] != 0x0)){
      debug.print("invio rfid :");    
      Serial.write(corrente,32);
      delay(50);      
      for (int x = 0; x < 32; x++){
        debug.print(corrente[x],BYTE);
        corrente[x] = 0x0;
      }
      debug.println("");      
      break;
      
    }
  }
}

void doLoginLogout(byte xbeeSender[8], byte* key, int keySize, boolean login){
  debug.print("login");
  debug.println(login,HEX);
//  key = &key[1];
//  keySize=keySize-1;
/*      if (!login){    
      debug.print("xbeeSender : ");          
      for (int z = 0; z < 8; z++){
        if (z<7){
          debug.print(xbeeSender[z],HEX);
        }else{
          debug.println(xbeeSender[z],HEX);
        }    
      }
      debug.print("key : ");          
      for (int z = 0; z < keySize; z++){
        if (z<keySize-1){
          debug.print(key[z],HEX);
        }else{
          debug.println(key[z],HEX);
        }    
      }
      }    
  */
  if (isInImpianto(xbeeSender)){  
        
    if (defimpianto[12] == 3){
      byte idantenna[]={defimpianto[8], defimpianto[9], defimpianto[10], defimpianto[11]};      
/*
      if (!login){    
      debug.print("id antenna : ");          
      for (int z = 0; z < 4; z++){
        if (z<3){
          debug.print(idantenna[z],HEX);
        }else{
          debug.println(idantenna[z],HEX);
        }    
      }
      debug.print("key : ");          
      for (int z = 0; z < keySize; z++){
        if (z<keySize-1){
          debug.print(key[z],HEX);
        }else{
          debug.println(key[z],HEX);
        }    
      }
      }    
      */
      if (getRowUtentiByIdantennaKey(idantenna, key, 50, defutente)){
/*
        debug.print("tipo utente :");
        debug.println(defutente[4],DEC);
  */     
        if ((defimpianto[13] == 0) && (defimpianto[14] == 0) &&
            (defimpianto[15] == 0) && (defimpianto[16] == 0)){
    //          debug.print("nessun titolare :");
              byte idimpianto[4];
              subarray(8,11,defimpianto,idimpianto);

              if (login){                
                
                if (defutente[4] == 0){
                
                  byte idutente[] = {defutente[0], defutente[1], defutente[2], defutente[3]};
      //            debug.println("prima set titolare");               
                  if (setIdUtenteImpiantoBySerial(xbeeSender, idutente)){
        //            debug.println("dopo set titolare");               
      /*              sendException(1,idimpianto,key,keySize);                          
                    sendException(7,idimpianto,key,keySize);                          
        */            
                    int rownumber = 1;
                    boolean almostone = false;
                    while (rownumber > 0){           
          //            debug.print("rownumber : ");
                      rownumber = getRowPermessiByIdantennaIdutente(idantenna, idutente, rownumber, defpermesso);
            //          debug.println(rownumber);                    
                      if (rownumber > 0){
                        almostone = true;
                        processPermesso(defpermesso,3);
                        rownumber++;
                      }else{             
                        if (!almostone){
                   //       sendException(10,idimpianto,key,keySize);                          
                        }
                        break;
                      }
                    }
                    
                  }else{
                    
                    byte idimpianto[4];
                    subarray(8,11,defimpianto,idimpianto);
              //      sendException(17,idimpianto,key,keySize);
                    
                  }
                  
                }else{
                  
                  if (defutente[4] == 2){
                //    sendException(3,idimpianto,key,keySize);
                //    sendException(13,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 1){
                  //  sendException(3,idimpianto,key,keySize);
                  }
                  
                }
                
              }else{
                  if (defutente[4] == 0){
               //     sendException(2,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 1){
               //     sendException(4,idimpianto,key,keySize);
               //     sendException(12,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 2){
               //     sendException(4,idimpianto,key,keySize);
                  }
                  
              }
        }else{
          byte idimpianto[4];
          subarray(8,11,defimpianto,idimpianto);
  //        debug.println("titolare esiste");
          if (login){       
            //byte idimpianto[4];
            //subarray(8,11,defimpianto,idimpianto);
            if (defutente[4] == 0){
        //      sendException(1,idimpianto,key,keySize);
        //      sendException(15,idimpianto,key,keySize);
            }
            if (defutente[4] == 2){
          //    sendException(3,idimpianto,key,keySize);
          //    sendException(13,idimpianto,key,keySize);
            }
            if (defutente[4] == 1){
         //     sendException(3,idimpianto,key,keySize);
            }
          }else{
     //       debug.println("sono in logout");
            if (defutente[4] == 0){
              if (getRowUtentiByIdantennaKey(idantenna, key, 50, defutente)){
       //         debug.println("dopo getRowutenti");
                byte idutente2[] = {0x0, 0x0, 0x0, 0x0};
                byte titolare [] = {defimpianto[13],defimpianto[14],defimpianto[15],defimpianto[16]};              
                byte idutente[] = {defutente[0], defutente[1], defutente[2], defutente[3]};
                boolean stesso = true;
                for(int j=0;j<4;j++){
                  if(titolare[j]!=idutente[j]){
                    stesso = false;
                    break;
                  }
                }
                  if (stesso && setIdUtenteImpiantoBySerial(xbeeSender, idutente2)){
      //              debug.println("dopo stesso");
                    //byte idimpianto[4];
                    //subarray(8,11,defimpianto,idimpianto);              
              //      sendException(2,idimpianto,key,keySize);
                  
                    int rownumber = 1;
                    while (rownumber > 0){                    
                      rownumber = getRowPermessiByIdantennaIdutente(idantenna, idutente, rownumber ,defpermesso);
                      if (rownumber > 0){
                        processPermesso(defpermesso,4);
                        rownumber++;
                      }else{
                        break;
                      }
                    }
                  }else{
                    //byte idimpianto[4];
                    //subarray(8,11,defimpianto,idimpianto);              
        //            sendException(2,idimpianto,key,keySize);
                  }
                }else{
                  //byte idimpianto[4];
                  //subarray(8,11,defimpianto,idimpianto);              
          //        sendException(2,idimpianto,key,keySize);
                }
            }
            if (defutente[4] == 1){
        //      sendException(4,idimpianto,key,keySize);
        //      sendException(12,idimpianto,key,keySize);
            }
            if (defutente[4] == 2){
        //      sendException(4,idimpianto,key,keySize);
            }
          }
        }
      }else{
        byte idimpianto[4];
        subarray(8,11,defimpianto,idimpianto);

        if (login){
  //        sendException(9,idimpianto,key,keySize);
        }else{
  //        sendException(17,idimpianto,key,keySize); 
        }
        
      }
      
    }else{
      
      byte idimpianto[4];
      subarray(8,11,defimpianto,idimpianto);
      
//      sendException(23,idimpianto,key,keySize); 
      
    }
    
  }else{
    byte idimpianto[4];
    subarray(8,11,defimpianto,idimpianto);
//    sendException(23,idimpianto,key,keySize);
    
  }

}

boolean isInImpianto(byte serial[8]){
  if (getRowImpiantoBySerial(serial,defimpianto)){
    return true;
  }else{
    return false;
  }
}

boolean getRowUtentiByIdantennaKey(byte idantenna[4], byte* key, int keyParamSize, byte* result) {
  boolean retVal = false;
  if (!file.open("UTENTI.TXT", O_READ)) {}
  int16_t b;
  boolean eof = false;
  while (!eof) {
    int keyReadSize = 0;
    boolean found=true;
    int i = 0;
    while ((b = file.read()) > -1) {
     if((char)b=='\r') {
       file.read();
       break;
      }
      if(i < 9+keyParamSize ) {
        result[i] = b;
      }
      if(i>8) {
         keyReadSize++;
      }
      i++;
    } 
    if(b<0) {
      eof=true;
      break;
    }
        
    if(keyParamSize != keyReadSize) {
      found = false;
    }    
    if(found) {
      for(i=0;i<4;i++) {
        if(idantenna[i]!=result[i+5]) {
          found = false;    
          break;
        }
      }
    }
    if(found) {
      for(i=0; i<28; i++) {
/*        debug.print("i : ");
        debug.println(i);
        debug.print("key = ");
        debug.print(key[i],HEX);
        debug.print(" --> ");
        debug.print("keyfile = ");
        debug.println(result[i+31],HEX);*/
        
        if(key[i]!=result[i+31]){
          
          found = false;    
          break;
        }
      }
    }
    if(found) {
      retVal=true;
      break;
    } 
  }
  file.close();
  return retVal;
}

void subarray(int start,int finish, byte* arrayData,byte* subarray){
  int count = 0;
  for (int i = start; i<=finish; i++){
    subarray[count] = arrayData[i];
    count++;
  }
}

boolean setIdUtenteImpiantoBySerial(byte serial[8], byte idutente[4]){

  boolean isOk = false;

  int line = countLines("IMPIANTO.TXT");

  if (!file.open("IMPIANTO.TXT", O_RDWR)){}

  else{

    for(int i=0;i<line;i++){

      int pos = (i*19);

      file.seekSet(pos);

      byte buffer [8];

      file.read(buffer,sizeof(buffer));

      byte valido = 0;

      for(int j=0;j<8;j++){

        if(serial[j]!=buffer[j])break;

        if(j==7)valido=1;

      }

      if(valido){

        file.seekSet(pos+13);

        for(int j=0;j<4;j++){

          file.write(idutente[j]);

        }

        //Serial.println("Trovato Impianto");

        isOk = true;

        break;

      }

    }

    file.close();

  }

  return isOk;

}

void sendException(int codException, byte idimpianto[4], byte* keyEx, int keySize){
  
  byte verbositarow[3] = {0x0,0x0,0x0};
  if (getRowVerbositaByCodiceEccez(codException, verbositarow)){
    
    if (verbositarow[1] = 1){
      byte data[7] = {0x0,0x0,0x0,0x0,0x0,0x0,0x0};      
      data[0] = (byte)year;
      data[1] = (byte)month;
      data[2] = (byte)date;
      data[3] = (byte)hour;
      data[4] = (byte)minute;
      data[5] = (byte)second;
      data[6] = (byte)week;
/*      
      nss.print("data :");
      for (int i = 0; i < 7; i++){
        nss.print(data[i],DEC);      
      }
      nss.println();
      
      nss.print("impianto :");
      for (int i = 0; i < 7; i++){
        nss.print(idimpianto[i],DEC);      
      }
      nss.println();
      
      nss.print("key :");
      for (int i = 0; i < keySize; i++){
        nss.print(keyEx[i],DEC);      
      }
      nss.println();
      
  */    
      addLogLine(data, idimpianto, codException, keyEx, keySize);
    
    }
    
  }
}

int getRowPermessiByIdantennaIdutente(byte idantenna[4], byte idutente[4], int pos, byte result[18]){

  int value = 0;

  int line = countLines("PERMESSI.TXT");

  if (!file.open("PERMESSI.TXT", O_READ)){// error("getRowPermessiByIdantennaIdutente");

  }else{

    int current = pos-1;

    for(int i=current;i<line;i++){

      int pos = (i*20);

      file.seekSet(pos);

      

      byte valido = 0;

      for(int j=0;j<8;j++){

        result[j]=file.read();

        if(j<4){

          if(idutente[j]!=result[j])break;

        }

        else {

          if(idantenna[j-4]!=result[j])break;

        }

        if(j==7)valido=1;

      }

      if(valido){

        for(int j=8;j<18;j++){

          result[j] = file.read();

        }

        value = i+1;

        break;

      }

    }

  }

  file.close();

  return value;

}

byte getRowVerbositaByCodiceEccez(byte codice, byte result[3]) {

  boolean retVal = false;

  if (!file.open("VERBOSIT.TXT", O_READ)){}  //error("open");

  int16_t n;

  uint8_t buf[5];// size 3+2

  uint8_t i;

  while ((n = file.read(buf, sizeof(buf))) > 0) {

    boolean found = true;

    if(buf[0] == codice) {

      for(i=0; i<4; i++) {

        result[i]=buf[i];

      }

      retVal=true;

      break;

    }

  }

  file.close();

  return retVal;

}

boolean addLogLine(byte date[7], byte idimpianto[4], byte codEccezione, byte* key, int keySize) {

  byte line[13+50];

  if (file.open("ZLOG.TXT", O_CREAT | O_APPEND | O_WRITE)){

    for(int i=0; i<7; i++){
  
      line[i]=date[i];
  
    }
  
    for(int i=0; i<4; i++){
  
      line[7+i]=idimpianto[i];
  
    }
  
    line[11] = codEccezione;
  
    line[12] = keySize;
  
    for(int i=0; i<keySize; i++){
  
      line[13+i]=key[i];
  
    }
  
    for(int i=0; i<(50-keySize); i++) {
  
      line[13+keySize+i] = 0x00;
  
    }
  
    file.writeError=false;
  
    for(int i=0; i<sizeof(line); i++) {
  
      file.print(line[i],BYTE);
  
    }
  
    file.println();
  
    file.close();
  
    return(! file.writeError);  
  }else{
    return false;
  }

}

void processPermesso(byte rowPermesso[18],byte action){
  debug.println("process permesso");

     getRtcTime();
/*     debug.print("anno : ");
     debug.println(year,DEC);
     debug.print("mese : ");
     debug.println(month,DEC);
     debug.print("giorno : ");
     debug.println(date,DEC);
     debug.print("ora : ");
     debug.println(hour,DEC);
     debug.print("minuti : ");
     debug.println(minute,DEC);
     debug.print("secondi : ");
     debug.println(second,DEC);
*/
  boolean inTime = false;

//  boolean inTime = true;
  
  if (rowPermesso[17] == 0){ 
    
    int workWeek = 0;
    if (week == 0){
      workWeek == 6;
    }else{
      workWeek == week-1;
    }
    /*
    for (int i=0;i<7;i++){
      debug.print(i);
      debug.print(":");
      if (i<6){
        debug.print(bitRead(rowPermesso[16],i));
        debug.print(" - ");
      }else{
        debug.println(bitRead(rowPermesso[16],i));
      }
    }
    */

    if (bitRead(rowPermesso[16],workWeek) == 1){
      /*
      debug.print("ora : ");
      debug.println(hour,DEC);
      debug.print("min : ");
      debug.println(minute,DEC);     
      
      debug.print("orada : ");
      debug.println(rowPermesso[12],DEC);
      debug.print("minda : ");
      debug.println(rowPermesso[13],DEC);
      debug.print("oraA : ");
      debug.println(rowPermesso[14],DEC);
      debug.print("minA : ");
      debug.println(rowPermesso[15],DEC);
     */
      if ((rowPermesso[12] <= hour) && (rowPermesso[14] >= hour)){
        inTime = true;
        if ((rowPermesso[12] == hour) && (rowPermesso[13] >= minute)){
          inTime = true;
        }else if ((rowPermesso[14] == hour) && (rowPermesso[15] <= minute)){
          inTime = true;
        }
      }
    }
    
    if (inTime){
   //     debug.println("in Time");
        byte idrisorsa[4];
        subarray(8,11,rowPermesso,idrisorsa);
        byte rowImpiantoRisorsa[17];
        if (action == 3){
         
          apriM1(255);
        }
        if (action == 4){
         
          chiudiM1(255);
        }
          
    }
    
  }
        
}

boolean getRowImpiantoBySerial(byte serial[8], byte result[17]) {  
  boolean retVal = false;
  if (!file.open("IMPIANTO.TXT", O_READ)){}
  int16_t n;
  uint8_t buf[8]="";// size 8!
  uint8_t buf2[9]; 
  uint8_t endCh[2];
  uint8_t i;
  while ((n = file.read(buf, sizeof(buf))) > 0) {
    boolean found = true;
    for (i = 0; i < n; i++)  {
      if(serial[i] != buf[i]) {
        found = false;
        break;
      } else {
        result[i] = buf[i];
      }
    }
    n = file.read(buf2, sizeof(buf2));
    if(found) {
      for (i = 0; i < n; i++)  {
        result[8+i] = buf2[i];
      }
      retVal = true;
      break;
    } 
    n = file.read(endCh, sizeof(endCh));
    if(n!=2) {
      break;
    }
  }
  file.close();
  return retVal;
}

int countLines(char* nomeFile) {
  int16_t b;
  int counter = 0;
  if (!file.open(nomeFile, O_READ)){}
  while ((b = file.read()) > -1) {
    if((char)b=='\n') {
      counter++;
    }
  }
  file.close();
  return counter;
}

boolean getRowImpiantoById(byte id[4], byte result[17]) {

  boolean retVal = false;

  if (!file.open("IMPIANTO.TXT", O_READ)) 

  {

   // error("open");

  }

  int16_t n;

  uint8_t buf[17], endCh[2], i;

  while ((n = file.read(buf, sizeof(buf))) > 0) {

    boolean found = true;

    for (i = 0; i < n; i++)  {

      result[i] = buf[i];   

      if( (i>7 && i<12) && id[i-8] != buf[i]) {

        found = false;

        break;

      } else {

        result[i] = buf[i];

      }

    }   

    if(found) {

      retVal=true;

      break;

    } else {

      n = file.read(endCh, sizeof(endCh));

      if(n!=2) {

        break;

      }

    }

  }

  file.close();

  return retVal;

}

boolean getLogLine(int lineNumber, byte result[63]) {

  if (file.open("ZLOG.TXT", O_READ)){ //error("getLogLineERR");

    if(file.seekSet(65*(lineNumber-1)) == 0) return false;
  
    for(int i=0; i<63; i++) {
  
      result[i] = file.read();      
  
    }
  
    file.close();
  
    return true;
    
  }else{
    return false;
  }

}


void sendCommand(byte serial[8],byte command){
  //PARTE DI GESTIONE DEL MOTORINO
}
 
void setDataTime(char dateTime[13]){
  
    year = 10 * (dateTime[0] - 48) + (dateTime[1] - 48);
    month = 10 * (dateTime[2] - 48) + (dateTime[3] - 48);
    date = 10 * (dateTime[4] - 48) + (dateTime[5] - 48);
    week = (dateTime[13] - 48);
    hour = 10 * (dateTime[7] - 48) + (dateTime[8] - 48);
    minute = 10 * (dateTime[9] - 48) + (dateTime[10] - 48);
    second = 10 * (dateTime[11] - 48) + (dateTime[12] - 48);
    
 //   debug.println("letturadati data");
    
    DS1307.setDate(year, month, date, week, hour, minute, second);
 //   debug.println("fine set data");
}

