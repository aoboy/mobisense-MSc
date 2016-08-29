/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: February 01, 2009 03:10:45 AM                            +
 +------------------------------------------------------------------------*/


#include "ETXLinkLayer.h"

interface SendBeacon{

    command error_t send(uint16_t, uint16_t);

    event void sendDone(error_t err);

}
