#include <RX8025.h>
#include <Wire.h>
#include <Fat16.h>
#include <Fat16util.h>
#include <XBee.h>
#include <NewSoftSerial.h>

uint8_t ssRX = 9;
uint8_t ssTX = 10;
NewSoftSerial nss(ssRX, ssTX);

SdCard card;
Fat16 file;

XBee xbee = XBee();
ZBRxResponse rx = ZBRxResponse();
ZBTxStatusResponse txStatus = ZBTxStatusResponse();

byte defimpianto[17];
byte defutente[60];
byte defpermesso[18];
byte xbeeAddress[8] = {0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};

uint32_t mbsCoordinator;
uint32_t lbsCoordinator;
uint32_t mbsMy;
uint32_t lbsMy;

unsigned char hour=0;
unsigned char minute=0;
unsigned char second=0;
unsigned char week=0;
unsigned char year=0;
unsigned char month=0;
unsigned char date=0;
unsigned char RX8025_time[7]={0x01,0x52,0x13,0x01,0x11,0x04,0x11};  //second, minute, hour, week, date, month, year, BCD forma


void setup() {  
  xbee.begin(9600);
  delay(10000);
  nss.begin(9600);
  Wire.begin();
  RX8025_init();
  TF_card_init();
//  setMySerialHL();
  sendLogicUnitAddress();     
  askCoordinatorAddress();
  byte key[1] = {0};

}

void loop() {

  xbee.readPacket();
  
  if(xbee.getResponse().isAvailable()){
    
     if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {        
        xbee.getResponse().getZBTxStatusResponse(txStatus);
     }else if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {        

       xbee.getResponse().getZBRxResponse(rx);
//      nss.println(rx.getData(0),DEC);
    
      if (rx.getData(0) == 'A'){  
        getRtcTime();
        nss.println("---- inizio ciclo login");
        castAddress64ToArray(rx.getRemoteAddress64(),xbeeAddress);
        doLoginLogout(xbeeAddress, rx.getData(), rx.getDataLength(), true);
        nss.println("---- fine ciclo login");
      }      
      if (rx.getData(0) == 'B'){
        getRtcTime();
        nss.println("---- inizio ciclo logout");
        castAddress64ToArray(rx.getRemoteAddress64(),xbeeAddress);
        doLoginLogout(xbeeAddress, rx.getData(), rx.getDataLength(), false);
        nss.println("---- fine ciclo logout");
      }
      if (rx.getData(0) == 'C'){
        getRtcTime();
        byte idimpianto[4] = {rx.getData(2),rx.getData(3),rx.getData(4),rx.getData(5)};
        doIstantCMD(idimpianto,rx.getData(1));
      }
/*      if (rx.getData(0) == 'R'){
        setDataTime(rx.getData());
      }*/
      if (rx.getData(0) == 'X'){
        getRtcTime();
        byte msbarray[4];
        byte lsbarray[4];       
        int32ToArrayOfByte(rx.getRemoteAddress64().getMsb(),msbarray);
        int32ToArrayOfByte(rx.getRemoteAddress64().getLsb(),lsbarray);
        byte serial[8];
        for (int i = 0;i < 4;i++){
          serial[i] = msbarray[i];
        }
        for (int i = 0;i < 4;i++){
          serial[4+i] = lsbarray[i];
        }
        
        if (isInImpianto(serial)){
          forwardException((int)rx.getData(1));
        }
      }
      if (rx.getData(0) == 'S'){
//       nss.println("ricevuto coordinator address");
       setCoordinatorAddress(rx.getRemoteAddress64().getMsb(), rx.getRemoteAddress64().getLsb());
       setDataTime(rx.getData()); 
       getRtcTime();
       sendException(16,0,0,1);    
      }
      if (rx.getData(0) == 'T'){
   //     nss.println("ricevuta richiesta indirizzo");
        byte msbarray[4];
        byte lsbarray[4];       
        int32ToArrayOfByte(rx.getRemoteAddress64().getMsb(),msbarray);
        int32ToArrayOfByte(rx.getRemoteAddress64().getLsb(),lsbarray);
        byte serial[8];
        for (int i = 0;i < 4;i++){
          serial[i] = msbarray[i];
        }
        for (int i = 0;i < 4;i++){
          serial[4+i] = lsbarray[i];
        }

        if (isInImpianto(serial)){ 
   //       nss.println("device presente in impianto");
          sendSetUpMessage(rx.getRemoteAddress64().getMsb(), rx.getRemoteAddress64().getLsb());
        }
      }
      if (rx.getData(0) == 'P'){
        file.remove("IMPIANTO.TXT");
        if (!file.open("IMPIANTO.TXT", O_CREAT | O_WRITE)){};// flashled(errorLed, 5, 1000);
      }
      if (rx.getData(0) == 'L'){
        file.remove("PERMESSI.TXT");
        if (!file.open("PERMESSI.TXT", O_CREAT | O_WRITE)){};// flashled(errorLed, 5, 1000);
      }
      if (rx.getData(0) == 'N'){
        file.remove("VERBOSIT.TXT");
        if (!file.open("VERBOSIT.TXT", O_CREAT | O_WRITE)){};// flashled(errorLed, 5, 1000);
      }
      if (rx.getData(0) == 'H'){
        file.remove("UTENTI.TXT");
        if (!file.open("UTENTI.TXT", O_CREAT | O_WRITE)){};// flashled(errorLed, 5, 1000);
      }
      if (
          (rx.getData(0) == 'D') || (rx.getData(0) == 'E') || (rx.getData(0) == 'F') || 
          (rx.getData(0) == 'G')){
            
        for(int i=1;i<rx.getDataLength();i++) {
          file.print(rx.getData(i), BYTE);
        }
        file.println();
        
      }
      if (
          (rx.getData(0) == 'I') || (rx.getData(0) == 'M') || (rx.getData(0) == 'O') || 
          (rx.getData(0) == 'Q')){
       if (!file.close()){};// flashled(errorLed, 5, 1000);        
      }
      if(rx.getData(0) == 'V'){
        sendLogFile();
        file.remove("ZLOG.TXT"); 
        byte xbeeSender[8] = {0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0};
        isInImpianto(xbeeSender);        
      }
     }
  }
}

void castAddress64ToArray(XBeeAddress64 address,byte serial[8]){
  byte msbarray[4];
  byte lsbarray[4]; 

  int32ToArrayOfByte(address.getMsb(),msbarray);
  int32ToArrayOfByte(address.getLsb(),lsbarray);
  for (int i = 0;i < 4;i++){
    serial[i] = msbarray[i];
  }
  for (int i = 0;i < 4;i++){
    serial[4+i] = lsbarray[i];
  }
}

void doLoginLogout(byte xbeeSender[8], byte* key, int keySize, boolean login){
  key = &key[1];
  keySize=keySize-1;
    
  if (isInImpianto(xbeeSender)){  //definisce defimpianto

    if (defimpianto[12] == 3){
      
      byte idantenna[]={defimpianto[8], defimpianto[9], defimpianto[10], defimpianto[11]};      
      
      if (getRowUtentiByIdantennaKey(idantenna, key, keySize, defutente)){

        nss.print("tipo utente :");
        nss.println(defutente[4],DEC);
        
        if ((defimpianto[13] == 0) && (defimpianto[14] == 0) &&
            (defimpianto[15] == 0) && (defimpianto[16] == 0)){
              
              byte idimpianto[4];
              subarray(8,11,defimpianto,idimpianto);

              if (login){                
                
                if (defutente[4] == 0){
                
                  byte idutente[] = {defutente[0], defutente[1], defutente[2], defutente[3]};
                
                  if (setIdUtenteImpiantoBySerial(xbeeSender, idutente)){

                    sendException(1,idimpianto,key,keySize);                          
                    sendException(7,idimpianto,key,keySize);                          
                    
                    int rownumber = 1;
                    boolean almostone = false;
                    while (rownumber > 0){                    
                      rownumber = getRowPermessiByIdantennaIdutente(idantenna, idutente, rownumber, defpermesso);
                                          
                      if (rownumber > 0){
                        almostone = true;
                        processPermesso(defpermesso,3);
                        rownumber++;
                      }else{             
                        if (!almostone){
                          sendException(10,idimpianto,key,keySize);                          
                        }
                        break;
                      }
                    }
                    
                  }else{
                    
                    byte idimpianto[4];
                    subarray(8,11,defimpianto,idimpianto);
                    sendException(17,idimpianto,key,keySize);
                    
                  }
                  
                }else{
                  
                  if (defutente[4] == 2){
                    sendException(3,idimpianto,key,keySize);
                    sendException(13,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 1){
                    sendException(3,idimpianto,key,keySize);
                  }
                  
                }
                
              }else{
                  if (defutente[4] == 0){
                    sendException(2,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 1){
                    sendException(4,idimpianto,key,keySize);
                    sendException(12,idimpianto,key,keySize);
                  }
                  if (defutente[4] == 2){
                    sendException(4,idimpianto,key,keySize);
                  }
                  
              }
        }else{

          if (login){       
            byte idimpianto[4];
            subarray(8,11,defimpianto,idimpianto);
            sendException(1,idimpianto,key,keySize);
            sendException(15,idimpianto,key,keySize);
          }else{
            if (getRowUtentiByIdantennaKey(idantenna, key, keySize, defutente)){
              byte idutente[] = {0x0, 0x0, 0x0, 0x0};              
              if (setIdUtenteImpiantoBySerial(xbeeSender, idutente)){
                byte idimpianto[4];
                subarray(8,11,defimpianto,idimpianto);              
                sendException(2,idimpianto,key,keySize);
                byte idutente[] = {defutente[0], defutente[1], defutente[2], defutente[3]};
              
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
              }
              
            }else{
              byte idimpianto[4];
              subarray(8,11,defimpianto,idimpianto);              
              sendException(2,idimpianto,key,keySize);
            }
          }
        }
      }else{
        byte idimpianto[4];
        subarray(8,11,defimpianto,idimpianto);

        if (login){
          sendException(9,idimpianto,key,keySize);
        }else{
          sendException(23,idimpianto,key,keySize); 
        }
        
      }
      
    }else{
      
      byte idimpianto[4];
      subarray(8,11,defimpianto,idimpianto);
      
      sendException(23,idimpianto,key,keySize); 
      
    }
    
  }else{
    byte idimpianto[4];
    subarray(8,11,defimpianto,idimpianto);
    sendException(23,idimpianto,key,keySize);
    
  }
  
}


void sendCommand(byte serial[8],byte command){
  
  byte msbarr[4] = {0x0,0x0,0x0,0x0};
  subarray(0,3,serial,msbarr);
  uint32_t msb = arrayOfByteToInt32(msbarr);
    
  byte lsbarr[4] = {0x0,0x0,0x0,0x0};
  subarray(4,7,serial,lsbarr);
  uint32_t lsb = arrayOfByteToInt32(lsbarr);
  
  uint8_t payload[] = {0,0};
  XBeeAddress64 addr64 = XBeeAddress64(msb, lsb); 
  payload[0] = 'C';
  payload[1] = command;
  ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
//  nss.println("inizio invio command");
  xbee.send(zbTx); 
 // nss.println("fine invio command");
}

void processPermesso(byte rowPermesso[18],byte action){
/*  nss.println("process permesso");
  nss.print("anno : ");
  nss.println(year,DEC);
  nss.print("mese : ");
  nss.println(month,DEC);
  nss.print("giorno : ");
  nss.println(date,DEC);
  nss.print("ora : ");
  nss.println(hour,DEC);
  nss.print("minuti : ");
  nss.println(minute,DEC);
  nss.print("secondi : ");
  nss.println(second,DEC);
  nss.print("gset : ");
  nss.println(week,DEC);
  */
  boolean inTime = false;

//  boolean inTime = true;
  
  if (rowPermesso[18] == 0){ 
    
    int workWeek = 0;
    if (week == 0){
      workWeek == 6;
    }else{
      workWeek == week-1;
    }
    /*
    for (int i=0;i<7;i++){
      nss.print(i);
      nss.print(":");
      if (i<6){
        nss.print(bitRead(rowPermesso[16],i));
        nss.print(" - ");
      }else{
        nss.println(bitRead(rowPermesso[16],i));
      }
    }
    */

    if (bitRead(rowPermesso[16],workWeek) == 1){
   /*   
      nss.print("ora : ");
      nss.println(hour,DEC);
      nss.print("min : ");
      nss.println(minute,DEC);     
      
      nss.print("orada : ");
      nss.println(rowPermesso[12],DEC);
      nss.print("minda : ");
      nss.println(rowPermesso[13],DEC);
      nss.print("oraA : ");
      nss.println(rowPermesso[14],DEC);
      nss.print("minA : ");
      nss.println(rowPermesso[15],DEC);
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
      
        byte idrisorsa[4];
        subarray(8,11,rowPermesso,idrisorsa);
        byte rowImpiantoRisorsa[17];
      /*  
         nss.print("idrisorsa :");
         for (int i = 0; i < 4; i++){
          if (i<3){
            nss.print(idrisorsa[i],DEC);
          }else{
            nss.println(idrisorsa[i],DEC);
          }
         }
        */
        getRowImpiantoById(idrisorsa,rowImpiantoRisorsa); 
        byte xbeeaddress[8];
        subarray(0,7,rowImpiantoRisorsa,xbeeaddress);
        /*
        nss.print("xbeeaddress :");
         for (int i = 0; i < 8; i++){
          if (i<7){
            nss.print(xbeeaddress[i],HEX);
            nss.print(" - ");
          }else{
            nss.println(xbeeaddress[i],HEX);
          }
         }
         */
        if (rowPermesso[17] == 0){ 
          sendCommand(xbeeaddress,action);    
        }
    }
    
  }
        
}

void sendException(int codException, byte idimpianto[4], byte* keyEx, int keySize){
  
  byte verbositarow[3] = {0x0,0x0,0x0};
  if (getRowVerbositaByCodiceEccez(codException, verbositarow)){
    if (verbositarow[2] = 1){
      uint8_t payload[13+keySize];
      
      payload[0]='X';
      
      payload[1] = (byte)year;
      payload[2] = (byte)month;
      payload[3] = (byte)date;
      payload[4] = (byte)hour;
      payload[5] = (byte)minute;
      payload[6] = (byte)second;
      payload[7] = (byte)week;
       
      int payloadindex = 8;
      for (int i=0; i<4; i++){
          payload[payloadindex] = idimpianto[i];
          payloadindex++;
      }
    
      payload[12] = codException;
    
      payloadindex = 13;
      for (int i=0; i< keySize; i++){
          payload[payloadindex] = keyEx[i];
          payloadindex++;
      }
    
      XBeeAddress64 addr64 = XBeeAddress64(mbsCoordinator, lbsCoordinator); 
      ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
      xbee.send(zbTx); 
    }
    
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

void forwardException(int codException){
  byte idimpianto[4] = {defimpianto[8], defimpianto[9], defimpianto[10],defimpianto[11]};
  byte keylogin[1] = {' '};
  sendException(codException,idimpianto,keylogin,1);
}

void doIstantCMD(byte idimpianto[4],byte command){
  
  byte rowimpianto[17];
  
  getRowImpiantoById(idimpianto,rowimpianto);
  byte xbeeAddress[8];
  subarray(0,7,rowimpianto,xbeeAddress);
  
  if ((command == 3) || (command == 4)){
    sendCommand(xbeeAddress,command);
    setPermessiDisable(idimpianto,true);
  }

  if (command == 1){
    sendCommand(xbeeAddress,4);
    setPermessiDisable(idimpianto,false);
  }
  
}

boolean isInImpianto(byte serial[8]){
  if (getRowImpiantoBySerial(serial,defimpianto)){
    return true;
  }else{
    return false;
  }
}

void subarray(int start,int finish, byte* arrayData,byte* subarray){
  int count = 0;
  for (int i = start; i<=finish; i++){
    subarray[count] = arrayData[i];
    count++;
  }
}

char* castIntToCharArray(int number){
  char value[10];
  sprintf(value, "%9d", number); 
  return value;
}

void setDataTime(byte data[8]){
   //second, minute, hour, week, date, month, year, BCD format
   RX8025_time[0] = data[6]; 
   RX8025_time[1] = data[5]; 
   RX8025_time[2] = data[4];
   RX8025_time[3] = data[7];
   RX8025_time[4] = data[3];
   RX8025_time[5] = data[2];
   RX8025_time[6] = data[1];
   setRtcTime();
}

void askCoordinatorAddress(){
    uint8_t payload[1] = {0};
    XBeeAddress64 addr64 = XBeeAddress64(0x00000000, 0x0000FFFF); 
    payload[0] = 'U';    
    
    nss.println("Invio richiesta indirizzo coordinator");
    ZBTxRequest zbTx = ZBTxRequest(addr64, payload, 1);
    xbee.send(zbTx);     
}

void setCoordinatorAddress(uint32_t mbs,uint32_t lbs){
  mbsCoordinator = mbs;
  lbsCoordinator = lbs;
}

void sendLogicUnitAddress(){
  int i = 1;
  byte rowimpianto[17];
  
  while (getRowImpianto(i,rowimpianto)){    
    
    byte xbeeAddress[8];
    subarray(0,7,rowimpianto,xbeeAddress);
  
    byte msbarr[4] = {0x00,0x00,0x00,0x00};
    subarray(0,3,xbeeAddress,msbarr);
    uint32_t msb = arrayOfByteToInt32(msbarr);
       
    byte lsbarr[4] = {0x00,0x00,0x00,0x00};
    subarray(4,7,xbeeAddress,lsbarr);
    uint32_t lsb = arrayOfByteToInt32(lsbarr);
    
    sendSetUpMessage(msb,lsb);
    i++;    
    
  }
  
}

void sendSetUpMessage(uint32_t msb, uint32_t lsb){
    uint8_t payload[1] = {0};
    XBeeAddress64 addr64 = XBeeAddress64(msb, lsb); 
    payload[0] = 'S';    
/*    
    nss.print("setup msb :");
    nss.println(msb,DEC);
    nss.print("setup lsb :");
    nss.println(lsb,DEC);
*/
    ZBTxRequest zbTx = ZBTxRequest(addr64, payload, 1);
    xbee.send(zbTx); 
}
/*
void setMySerialHL(){
  
  uint8_t shCmd[] = {'S','H'};
  uint8_t slCmd[] = {'S','L'};

  uint8_t sh[4] = {' ',' ',' ',' '};
  uint8_t sl[4] = {' ',' ',' ',' '};
  
  AtCommandRequest atRequest = AtCommandRequest(shCmd);
  AtCommandResponse atResponse = AtCommandResponse();
    
  sendAtCommand(atRequest,atResponse,sh);
  atRequest.setCommand(slCmd);
  sendAtCommand(atRequest,atResponse,sl);

  mbsMy = 0;
  lbsMy = 0;
  
  mbsMy = arrayOfByteToInt32(sh);
  int32ToArrayOfByte(mbsMy,sh);
  
  lbsMy = arrayOfByteToInt32(sl);
  
  uint8_t exitCmd[] = {'C','N'};
  atRequest.setCommand(exitCmd);
  sendAtCommand(atRequest,atResponse,sl);
}
*/
uint32_t arrayOfByteToInt32(byte bytearray[4]){
  
  uint32_t primo = 0;
  uint32_t secondo = 0;
  uint32_t terzo = 0;
  uint32_t quarto = 0;  

  primo = ((uint32_t)bytearray[0]) << 24;
  secondo = ((uint32_t)bytearray[1]) << 16;
  terzo = ((uint32_t)bytearray[2]) << 8;
  quarto = ((uint32_t)bytearray[3]) << 0;
  
  uint32_t returnValue = primo + secondo + terzo + quarto;  

  return returnValue;
  
}

void int32ToArrayOfByte(uint32_t value,uint8_t valueArray[4]){
  
  valueArray[0] = value >> 24;
  valueArray[1] = value >> 16;
  valueArray[2] = value >> 8;
  valueArray[3] = value >> 0;  
  
}

/*
void sendAtCommand(AtCommandRequest atRequest, AtCommandResponse atResponse, uint8_t returnValue[4]) {
  
  xbee.send(atRequest);

  if (xbee.readPacket(5000)) {
    if (xbee.getResponse().getApiId() == AT_COMMAND_RESPONSE) {
      xbee.getResponse().getAtCommandResponse(atResponse);

      if (atResponse.isOk()) {

        if (atResponse.getValueLength() > 0) {

             for (int i = 0; i < atResponse.getValueLength(); i++) {
                returnValue[i] = atResponse.getValue()[i];
            }

        }
      } 
    }
  }
  
}
*/
void sendLogFile(){
  
      uint8_t payload[64];
      byte result[63];
      int i = 1;
      payload[0] = 'K';
      XBeeAddress64 addr64 = XBeeAddress64(mbsCoordinator, lbsCoordinator); 

      while (getLogLine(i, result)) {
        i++;
        for (int x=0; x<63; x++){
          payload[x+1] = result[x];
        }
        ZBTxRequest zbTx = ZBTxRequest(addr64, payload, 64);
        xbee.send(zbTx);         
      }
      delay(500);
      uint8_t payloadEnd[1];
      payloadEnd[0] = 'Z';
      ZBTxRequest zbTx = ZBTxRequest(addr64, payloadEnd, 1);
      xbee.send(zbTx);               

}

//-----------------------------------------------------------------
//---------------------- FUNZIONI ACCESSO SD ----------------------
//-----------------------------------------------------------------
boolean getRowImpianto(int numeroriga, byte result[17]){
  if((countLines("IMPIANTO.TXT") < numeroriga) || (numeroriga < 1)) {
    return false;
  }
  if (!file.open("IMPIANTO.TXT", O_READ)) {
    return false;
  }
  int16_t b;
  int i = 0;
  int currentLine = 1;
  while ((b = file.read()) > -1) {
    if((char)b=='\n') {
      if(currentLine==numeroriga) {
        file.close();
        return true;
      } else {
        currentLine++;
        i=0;
      }
    }
    else {
      result[i] = b;
      i++;
    }
  }
  file.close();
  return false;
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

void TF_card_init(void) 
{
  pinMode(4,INPUT);//extern power
  if (!card.init());
  if (!Fat16::init(&card));
  file.writeError = false;
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
      for(i=0; i<keyReadSize; i++) {
        if(key[i]!=result[i+9]) {
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



void setPermessiDisable(byte idimpianto[4],boolean disable){

  int line = countLines("PERMESSI.TXT");

  if (!file.open("PERMESSI.TXT", O_RDWR)){}

  else{

    for(int i=0;i<line;i++){

      int pos = (i*20);

      file.seekSet(pos+8);

      byte buffer [4];

      file.read(buffer,sizeof(buffer));

      byte valido = 0;

      for(int j=0;j<4;j++){

        if(idimpianto[j]!=buffer[j])break;

        if(j==3)valido=1;

      }

      if(valido){

        //Serial.println("Trovato Permessi");

        file.seekSet(pos+17);

        uint8_t val;

        if(disable)val = 1;

        else val = 0;

        file.write(val);

      }

    }

    file.close();

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


/*
void print_RX8025_time(void)
{
  nss.print(year,DEC);
  nss.print("/");
  nss.print(month,DEC);
  nss.print("/");
  nss.print(date,DEC);
  switch(week)
  {
  case 0x00:
    {
      nss.print("/Sunday  ");   
      break;
    }
  case 0x01:
    {
      nss.print("/Monday  ");
      break;
    }
  case 0x02:
    {
      nss.print("/Tuesday  ");
      break;
    }
  case 0x03:
    {
      nss.print("/Wednesday  ");
      break;
    }
  case 0x04:
    {
      nss.print("/Thursday  ");
      break;
    }
  case 0x05:
    {
      nss.print("/Friday  ");
      break;
    }
  case 0x06:
    {
      nss.print("/Saturday  ");
      break;
    }
  }
  nss.print(hour,DEC);
  nss.print(":");
  nss.print(minute,DEC);
  nss.print(":");
  nss.println(second,DEC);
}
*/

