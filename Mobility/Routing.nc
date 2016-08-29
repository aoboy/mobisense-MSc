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

interface Routing{

  command void init();

  command routing_hdr_t *getHeader(message_t *m);

  command void setHeader(message_t *m);
  
  command void setHeaderType(message_t *m, uint8_t);

  command error_t getNextHop(message_t *p, uint8_t opt);

  //sets the routing node
  command void setRootNode();

  //unset the routing node  
  command void unsetRootNode();

  command bool getRootNode();

  command uint16_t getParent();

  command uint8_t getEtxByIndex(uint8_t idx);

  command uint8_t getEtxByAddr(uint16_t addr);

  //command uint8_t exists(uint16_t addr);

}




