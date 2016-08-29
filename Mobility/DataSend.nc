/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 02:34:45 AM                             +
 +------------------------------------------------------------------------*/

#include "message.h"
#include "ETXLinkLayer.h"

interface DataSend{
     
   event void sendDone(message_t *p, error_t );

   command void* getPayload(message_t *p, uint8_t len);
 
   command void* getVoidPayload(uint8_t len);

   command error_t send(message_t *p, uint8_t len); 
   
   command error_t sendVoid(void* data, uint8_t len);

   command void setPacketType(message_t *p, uint8_t type);

   //command uint8_t payloadLength(message_t *p);

   command uint8_t maxPayloadLength();

   command error_t cancel(message_t* m);

}

