/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 12, 2009 02:24:45 AM                             +
 +------------------------------------------------------------------------*/


#include "ETXLinkLayer.h"

interface Monitor{

    command void setInterval(uint16_t delta);

    command void update(uint8_t nbytes);

    command uint32_t getNBytes();

    command uint32_t getNPackets();

    command uint16_t getMonitorSeqno();

    command uint32_t getSenderTime();

    command bool isSending();
    
    command void set(bool val);
 
    command void enable();
 
    command void disable();

    command void sendMonitor();

    command void enableAuto();

    command void disableAuto();

    command bool isAuto();

    command void setPktType(uint8_t type);
}



