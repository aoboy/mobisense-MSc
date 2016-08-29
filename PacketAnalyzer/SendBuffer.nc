
/*KTH - The Royal Institute of Technology
 +School of Electrical Engineering/School of Technology and Health
 +Master Program in Network Services and Systems
 +@author: Gonga, António Oliveira - gonga@kth.se
 +Date: STOCKHOLM, Tue, April 15, 2008  16:27:45'
 +file: SendBuffer.nc
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*NOTICE: As I am a supporter of open source Software, I do
 *autorize anyone interested to inprove this Application to
 *send me a notification. I do hope that this application
 *will solve many of your problems.
 +<A. Gonga
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#include "Sniffer.h"

interface SendBuffer{

   command uint8_t plength(message_t*);
   command error_t send(Timestamp_t*, uint8_t );
   command void    init();

   event message_t* queryReceive(message_t*, void*, uint8_t);
   command FilterMsg* getQueryMsg(message_t*);
      
   event void sendDone(error_t);
}
