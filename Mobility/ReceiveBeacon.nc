/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 11, 2009 00:22:45 PM                             +
 +------------------------------------------------------------------------*/

#include "message.h"
#include "ETXLinkLayer.h"


interface ReceiveBeacon{

   event message_t* receive(message_t*, void*, uint8_t);
}
