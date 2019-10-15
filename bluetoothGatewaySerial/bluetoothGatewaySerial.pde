#include <NewSoftSerial.h>

NewSoftSerial LUSerial(6,7);

char[] bufCMD = new char[2];
  
void setup() 
{ 
    Serial.begin(115200);
    LUSerial.begin(9600);
} 
 
void loop() 
{ 

 if (Serial.available() > 0){
   while (Serial.available() > 0){
     LUSerial.print(Serial.read(),BYTE);
   }
 }

} 

