/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 11, 2009 02:22:45 AM                             +
 +------------------------------------------------------------------------*/


#include "ETXLinkLayer.h"

interface NodeRole{

    command void setNodeRole(uint8_t role);

    command void setNodeAsRouter();

    command void setNodeAsMobile();

    command uint8_t getRole();
}



