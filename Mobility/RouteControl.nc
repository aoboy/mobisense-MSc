/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 02:22:45 AM                             +
 +------------------------------------------------------------------------*/

#include "ETXLinkLayer.h"


interface RouteControl{

    command void setOrigAddr(message_t *p, uint16_t addr);

   
    command uint16_t getOrigAddr(message_t *p);

   
    command void setPayloadType(message_t *p, uint8_t type);

   
    command uint8_t getPayloadType(message_t *p);

   
    command void setSeqno(message_t *p, uint16_t seqno);

   
    command uint16_t getSeqno(message_t *p);

    //updates the hopcount number
    command void updateHopcount(message_t* m);
}

