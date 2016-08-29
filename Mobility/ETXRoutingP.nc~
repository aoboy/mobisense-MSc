/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 11, 2009 00:22:45 PM                             +
 +------------------------------------------------------------------------*/


#include "ETXLinkLayer.h"

module ETXRoutingP{
   provides{        
	interface Routing;
        interface Monitor;
	interface NodeRole;
	interface StdControl;
        interface RouteControl;	
   }
   uses{
	interface Leds;
	interface AMPacket;
	interface Packet;
	interface CC2420Packet;
	interface Timer<TMilli> as Timer0;
	interface Timer<TMilli> as updateTimer;        
	interface SendBeacon;
	interface ReceiveBeacon;
		
        interface DataSend as Send;

        interface LinkLayer;
   }
}
implementation{

  enum{
    INVALID_ADDR  = 0xffff,
    INVALID_IDX   = 0xf,
    INVALID_RSSI  = -INVALID_ADDR,
    RSSI_OFFSET   = -45,     //Pr = RSSi_VAL + RSSI_OFFSET [dbm]
    RSSI_SWITCH   = 10,
    ETX_THRESHOLD = 50
  };


   
  message_t msg;                 //messages 

  route_t my_info;
  
  uint8_t nodeRole;              // a node can be a ROUTER or a MOBILE...

  bool root_flag ;               //the root does not send messages
  bool radioBusy ;               //two instances cannot send messages at the same time

  bool initFlag;                //I'm initializing... will be suppressed
  bool monitor;                 //activated when a monitor packet is to be sent
  bool send_automatic;
  bool disableMonitor;          // when  user does not want to send monitor packets
  uint8_t monitor_type;         //monitor packet type

  uint16_t currentParent;       //the address of my parent/gateway
  uint16_t currentETX;
  uint16_t currentRSSI;
  uint8_t  currentIdx=0;

  uint16_t currentSeqno;        //If messages are departing from the node, this gives the sequence number

  uint8_t  nodeTTLValue;        //TimeToLive value, it differs for Routers and MobileNodes

  uint32_t totalBytes;          //Total number of bytes sent over the radio, not including beacon messages
  uint32_t totalPackets;        //Total number of packets sent over the radio not including beacon messages/pkts
  uint16_t monitorSeqno;        //The current monitor packet sequence number...
  uint16_t monitorInterval;     //Interval between monitor packets
  
  uint8_t  cyclicIdx;           //avoid circular messages..Idx current position fo look for
  uint8_t  duplicatedIdx;        //IDx for diplicated 
  

  uint16_t duplicatedSenders[ROUTING_TBL_LEN];  //avoid duplicacted packets..senders are registered..
  uint16_t duplicatedSeqno[ROUTING_TBL_LEN];    //correspondent seqno array

  uint16_t cyclicSenders[ROUTING_TBL_LEN];     //avoid messages to make a loop...
  uint16_t cyclicSeqno[ROUTING_TBL_LEN]; 

  routing_tbl_t routingTable[ROUTING_TBL_LEN];  //routingTable table or routing table..
  
  //Function Prototypes  
  void initialize(); 

  inline bool evaluateETX(uint8_t etx);

  beacon_t* getBeacon(message_t* p);

  inline uint8_t findAvailableEntry();
  
  inline uint8_t getIdx(uint16_t );

  uint16_t getRssiInDbm(message_t *);    //this function is based on RSSIDemo with an extension

  routing_hdr_t* getRoutingHeader(message_t *m);

  void addEntry(beacon_t* b, uint16_t src_addr, uint16_t rssi);

  void updateEntry(beacon_t* b, uint16_t src_addr, uint8_t idx, uint16_t rssi);

  //Task Prototypes
  task void SendBeaconTask();  
  
  task void updateRouteETX();
  
  task void updateRouteRSSI();

  task void SendMonitorTask();

  /*-------------------------------------------------------------------------------*/
  beacon_t* getBeacon(message_t* p){
     return (beacon_t*)(call Packet.getPayload(p, BEACON_MSG_LEN));   
  }

  /*-------------------------------------------------------------------------------------------*/
  routing_hdr_t* getRoutingHeader(message_t *m){
     return (routing_hdr_t*)(call Packet.getPayload(m, ROUTING_HDR_LEN));
  }

 /*-------------------------------------------------------------------------------------------*/
 void initialize(){
    int k;
       for(k = 0; k < ROUTING_TBL_LEN; k++){
	    routingTable[k].parent     = INVALID_ADDR;
            routingTable[k].src        = INVALID_ADDR;
	    routingTable[k].active     = 0;
	    routingTable[k].ttl        = 0;
	    routingTable[k].metric     = INVALID_ETX;
	    routingTable[k].rssi       = 0;
       }
	
       atomic{

	  cyclicIdx       = 0;
	  duplicatedIdx   = 0;

	  nodeRole        = ROUTER_ROLE;
	  nodeTTLValue    = ROUTER_ENTRY_TTL;
          
	  initFlag        = FALSE;
	  monitor         = FALSE;
	  root_flag       = FALSE;
          disableMonitor  = FALSE;
	  send_automatic  = FALSE;
          monitor_type    = 0;
	  
	  currentSeqno    = 0;

          totalBytes      = 0;
          totalPackets    = 0;
	  monitorSeqno    = 0;
          monitorInterval = MONITOR_PKT_DT;

	  currentParent   = INVALID_ADDR;
          currentETX      = INVALID_ETX;
	  currentRSSI     = INVALID_RSSI;
       }
  }

 /*-------------------------------------------------------------------------------------------*/
 //RssiDemo Modified - 	//CC2420DataSheet/Page 47 Pr = RSSI_VAL + RSSI_OFFSET [dBm];
#ifdef __CC2420_H__
  uint16_t getRssiInDbm(message_t *p){    
    return (uint16_t)((uint16_t)call CC2420Packet.getRssi(p) + RSSI_OFFSET);  
  }
#endif
     
 inline bool evaluateETX(uint8_t etx){
	return ((etx < ETX_THRESHOLD)? TRUE : FALSE );
 }
 /*-------------------------------------------------------------------------------------------*/
  command error_t StdControl.start(){
    call Timer0.startPeriodic(1024);
    call updateTimer.startPeriodic(512);
    return SUCCESS;
  }

  /*-------------------------------------------------------------------------------------------*/
  command error_t StdControl.stop(){
    call Timer0.stop();
    call updateTimer.stop();
    return SUCCESS;
  }

  /*-------------------------------------------------------------------------------------------*/
  command void Routing.init(){
	initialize(); 
        call LinkLayer.initLinkLayer();
        call StdControl.start();
  }

  /*-------------------------------------------------------------------------------------------*/
  command routing_hdr_t* Routing.getHeader(message_t *m){
	return getRoutingHeader(m);
  }

 /*-------------------------------------------------------------------------------------------*/
  command void Routing.setHeader(message_t* m){
	routing_hdr_t* hdr = getRoutingHeader(m);
	
	//hdr->type      = TYPE_DATA;
	hdr->hopcount  = 1;
	hdr->seqno     = currentSeqno++;
	hdr->orig_addr = TOS_NODE_ID;
  }

  /*-------------------------------------------------------------------------------------------*/
  command void Routing.setHeaderType(message_t* m, uint8_t type){
	routing_hdr_t* hdr = getRoutingHeader(m);
	
	//hdr->type      = type;
	hdr->hopcount  = 1;
	hdr->seqno     = currentSeqno++;
	hdr->orig_addr = TOS_NODE_ID;
  }
 
 /*-------------------------------------------------------------------------------------------*/
  command error_t Routing.getNextHop(message_t *p, uint8_t opt){
     uint8_t k;
     uint16_t  pkt_src  = call AMPacket.source(p);
     routing_hdr_t* hdr = getRoutingHeader(p);
            
     if(root_flag){
	return FAIL;
     }

     if(nodeRole == ROUTER_ROLE){
     	if(hdr->orig_addr != TOS_NODE_ID && opt == 0){
	   for(k = 0; k < ROUTING_TBL_LEN; k++){
	     if(duplicatedSenders[k] == pkt_src  && duplicatedSeqno[k] == hdr->seqno){
		    return FAIL;  //duplicated packet
	     } 	
	   }
          
           duplicatedSenders[duplicatedIdx] = pkt_src;
	   duplicatedSeqno[duplicatedIdx]  = hdr->seqno;
	   duplicatedIdx = (duplicatedIdx + 1)%ROUTING_TBL_LEN;

	   for(k = 0; k < ROUTING_TBL_LEN; k++){
	     if(cyclicSenders[k] == hdr->orig_addr && cyclicSeqno[k] == hdr->seqno){
	  	currentETX     = INVALID_ETX;
	  	currentRSSI    = INVALID_RSSI;
	  	currentParent  = INVALID_ADDR;
		
		return FAIL;
	     }
	   }
	  
           cyclicSenders[cyclicIdx]  = hdr->orig_addr;
	   cyclicSeqno[cyclicIdx]    = hdr->seqno;
	   cyclicIdx = (cyclicIdx + 1)%ROUTING_TBL_LEN;
	  
           //at this poit the header hopcount can be incremented...
	   hdr->hopcount++;
        }
      } //end of nodeRole                                  

      call AMPacket.setDestination(p, call Routing.getParent());
      //call AMPacket.setDestination(p, 11);            

     return  SUCCESS;
  }

  /*-------------------------------------------------------------------------------------------*/ 
  //sets the routing node
  command void Routing.setRootNode(){
	root_flag = TRUE;
	call LinkLayer.setRoot();	
  }

  /*-------------------------------------------------------------------------------------------*/ 
  //unset the routing node  
  command void Routing.unsetRootNode(){
	root_flag = FALSE;
	call LinkLayer.unsetRoot();
  }

  /*-------------------------------------------------------------------------------------------*/
  command bool Routing.getRootNode(){
	return root_flag;
  }

 /*-------------------------------------------------------------------------------------------*/
  command uint16_t Routing.getParent(){
	return currentParent;
  }

 /*-------------------------------------------------------------------------------------------*/
  command uint8_t Routing.getEtxByIndex(uint8_t idx){
	uint8_t k;
	routing_tbl_t *ptr;	

	for(k = 0; k < ROUTING_TBL_LEN; k++){
		ptr = &routingTable[k];
		if(k == idx && (ptr->active != 0)){
		   return (ptr->metric);
		}
	}
	return INVALID_ETX;
  }

 /*-------------------------------------------------------------------------------------------*/
  command uint8_t Routing.getEtxByAddr(uint16_t addr){
     uint8_t k;
     routing_tbl_t *ptr;

	for(k = 0; k < ROUTING_TBL_LEN; k++){
	    ptr = &routingTable[k];
	    if(ptr->active != 0 && ptr->src == addr){
		return (ptr->metric);
	    }
	}

     return INVALID_ETX;
  }

 /*-------------------------------------------------------------------------------------------*/
  inline uint8_t getIdx(uint16_t addr){
     uint8_t k;
     routing_tbl_t *ptr;

	for(k = 0; k < ROUTING_TBL_LEN; k++){
	    ptr = &routingTable[k];
	    if((ptr->active == 1) && ptr->src == addr){
		return k;
	    }
	}

     return INVALID_IDX;
  }

 /*-------------------------------------------------------------------------------------------*/
  inline uint8_t findAvailableEntry(){
     uint8_t k, n=15;
     uint8_t min = 0, maxTTL = 0;

       for(k = 0; k < ROUTING_TBL_LEN; k++){
	   if(routingTable[k].active == 0){
		return k;		
	   }
       }
      
      //we are not succeded, lets find the one not sending anything for long time
      for(k = 0, n = 0; k < ROUTING_TBL_LEN; k++){
	    if(nodeRole == ROUTER_ROLE){
	        if(routingTable[k].metric > min){
		    n = k;
		    min = routingTable[k].metric;
	        }
	    }else{
		if(routingTable[k].ttl > maxTTL){
		    n      = k;
		    maxTTL = routingTable[k].metric;
	        }
	    }
      }
      
    return n;        
  }


 /*-------------------------------------------------------------------------------------------*/ 
 void updateEntry(beacon_t* b, uint16_t src_addr, uint8_t idx, uint16_t rssi){

   /*if(nodeRole == ROUTER_ROLE && !evaluateETX(b->metric)){
	return ;
   }*/
   atomic{
 	     routingTable[idx].active      = 1;
	     routingTable[idx].ttl         = 0;
	     routingTable[idx].src         = (uint16_t)src_addr;
	     routingTable[idx].metric      = b->metric;
  	     routingTable[idx].parent      = (uint16_t)b->parent;	
	     routingTable[idx].rssi        = rssi;  	         
       }
  } 

 /*-------------------------------------------------------------------------------------------*/ 
  void addEntry(beacon_t* b, uint16_t src_addr, uint16_t rssi){
    uint8_t idx=0xff;
        
	idx = getIdx(src_addr);

	if(idx < ROUTING_TBL_LEN){	  	  	    	 
           
	   updateEntry(b, src_addr, idx, rssi);
	      	
        }else{	                     
               //This is an insertion
	       idx = findAvailableEntry();	       				 
	       updateEntry(b, src_addr, idx, rssi);
	}        
  }

 /*-------------------------------------------------------------------------------------------*/
  task void SendBeaconTask(){
      
      uint16_t linkEtx;

      if(radioBusy){
	return;
      }

      if(root_flag){
        linkEtx =  0;
	currentParent = (uint16_t)TOS_NODE_ID;		
      }else if(currentParent == INVALID_ADDR){
	linkEtx =  INVALID_ETX;
      }else{	
	  linkEtx = currentETX;	
      }
          
      if(call SendBeacon.send(linkEtx, currentParent) == SUCCESS){
	  if(nodeRole == ROUTER_ROLE){	  
              call Leds.led1Toggle();
          }
	  radioBusy = TRUE;
      }	
  }

 /*-------------------------------------------------------------------------------------------*/
  event void SendBeacon.sendDone(error_t success){    
        radioBusy = FALSE;     
  }


 /*-------------------------------------------------------------------------------------------*/  
  task void updateRouteETX(){
     uint8_t k, n = INVALID_IDX;

     uint16_t minETX, maxETX, pathETX, addr=0;

        maxETX = INVALID_ETX;
	minETX = (uint16_t)INVALID_ETX;

        for(k = 0; k < ROUTING_TBL_LEN; k++)
        {	   
	   routingTable[k].ttl++;
	   if(routingTable[k].ttl >= nodeTTLValue){
		routingTable[k].active = 0;
		continue;
	   }
	   if(routingTable[k].active != 0){
	       
	   	if(routingTable[k].src == currentParent){  //check if our parent is updated
		  atomic{
		     currentParent = routingTable[k].src;
		     currentETX    = routingTable[k].metric;
		  }
		}
		
		pathETX = routingTable[k].metric + call LinkLayer.getEtxByAddr(routingTable[k].src);	

	   	if(pathETX < minETX){
		     n      = k;
		     addr   = (uint16_t)routingTable[k].src;
		     minETX = pathETX;		    
	   	}		           
	   } //end else
	   
	} //end for
	
        if(n < ROUTING_TBL_LEN){
	      if(routingTable[n].src == currentParent){  //check if our parent is updated
		  atomic{		     
		     currentParent = routingTable[n].src;
		     currentETX    = routingTable[n].metric;
		     currentIdx    = n;		    
		  }
	      }else{		
		  if(minETX < currentETX){		    
 		    atomic{		     
		        currentParent = routingTable[n].src;    //ptr->src;
		        currentETX    = (uint8_t)minETX;  //ptr->metric;
			currentIdx    = n;		    
		    }
		   }	
	      }
	}else{
 	    atomic{
		//call Leds.led2Toggle();
		currentParent = INVALID_ADDR;
		currentETX    = INVALID_ETX;
		currentIdx    = INVALID_IDX;		    
	     }	
        }
  }

 /*-------------------------------------------------------------------------------------------*/
  task void updateRouteRSSI(){
    uint8_t k;
    uint8_t n=INVALID_IDX;
    int16_t maxRssi = INVALID_RSSI;
    
    uint16_t addr;
    routing_tbl_t* entry;
  
      for(k = 0; k < ROUTING_TBL_LEN; k++){
	 atomic{
	   entry = &routingTable[k];
	 }
	 entry->ttl++;
	 if(entry->ttl >= nodeTTLValue){
	   entry->active = 0;
	   continue;
	 }
	if(entry->active == 0){
           continue;
	}else{
	    if((entry->active == 1) && (entry->rssi > maxRssi) && (entry->src != INVALID_ADDR)){
		n       = k;
		addr    = entry->src;	        
		maxRssi = entry->rssi;
            }
         }
      } //end of For Loop
   
      if(n < ROUTING_TBL_LEN){
	if(currentParent == addr){
	    atomic{
	       currentParent = addr;
	       currentRSSI   = (uint16_t)maxRssi;
	    }
	}else{
	   if(currentParent == INVALID_ADDR || (currentRSSI /*+RSSI_SWITCH*/) < maxRssi){
	       atomic{
		   currentParent = addr;
	           currentRSSI   = (uint16_t)maxRssi;	     
	       }
	   }
	}
      }else{
	//no candidates have been found... we don't have route
	atomic{
	    //call Leds.led2Toggle();
	    currentParent = INVALID_ADDR;
	    currentRSSI   = INVALID_RSSI;
	}
      }
  }

 /*-------------------------------------------------------------------------------------------*/
  event void updateTimer.fired(){     
    if(nodeRole == ROUTER_ROLE){
	post updateRouteETX();
    }else{
        //call Leds.led2Toggle();
	post updateRouteRSSI();
    }	  
  }
/*-------------------------------------------------------------------------------------------*/
 event void Timer0.fired(){     
    //Just the root and other routers can send beacons...          	
    if(nodeRole == ROUTER_ROLE){    
        post SendBeaconTask();
    }          
 }
 
  /*-------------------------------------------------------------------------------------------*/
  event message_t* ReceiveBeacon.receive(message_t* p, void* payload, uint8_t len){

     uint16_t addr;
     beacon_t *bcn = (beacon_t*)call Packet.getPayload(p, sizeof(beacon_t));

     if(call Routing.getRootNode()){
	return p;
     }

     
     addr = call AMPacket.source(p);
     if((call AMPacket.type(p) == AM_BEACON_MSG) && (bcn->parent != (uint16_t)TOS_NODE_ID)){	
	addEntry(bcn, addr, getRssiInDbm(p));
        if(nodeRole == MOBILE_ROLE){
	    //call Leds.led2Toggle();
	}
     }
    return p;
  } 
 
 
   /*-------------------------------------------------------------------------------------------*/ 
   //RouteControl
   command void RouteControl.setOrigAddr(message_t *p, uint16_t addr){
	routing_hdr_t *hdr = getRoutingHeader(p);
	hdr->orig_addr = addr;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint16_t RouteControl.getOrigAddr(message_t *p){
	routing_hdr_t *hdr = getRoutingHeader(p);
	return hdr->orig_addr;
    }

   /*-------------------------------------------------------------------------------------------*/
    command void RouteControl.setPayloadType(message_t *p, uint8_t type){
	routing_hdr_t *hdr = getRoutingHeader(p);
	hdr->type= type;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint8_t RouteControl.getPayloadType(message_t *p){
	routing_hdr_t *hdr = getRoutingHeader(p);
	return hdr->type;
    }

   /*-------------------------------------------------------------------------------------------*/
    command void RouteControl.setSeqno(message_t *p, uint16_t seqno){
	routing_hdr_t *hdr = getRoutingHeader(p);
	hdr->seqno = seqno;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint16_t RouteControl.getSeqno(message_t *p){
	routing_hdr_t *hdr = getRoutingHeader(p);
	return hdr->seqno;
    }

   /*-------------------------------------------------------------------------------------------*/
    //updates the hopcount number
    command void RouteControl.updateHopcount(message_t* m){
	routing_hdr_t* hdr = getRoutingHeader(m);
	hdr->hopcount = hdr->hopcount+1;	
    }

    //Monitor         
   /*-------------------------------------------------------------------------------------------*/
    command void Monitor.setInterval(uint16_t delta){
	monitorInterval  = delta;
    }

   /*-------------------------------------------------------------------------------------------*/
    command void Monitor.update(uint8_t nbytes){
	atomic{
	   totalPackets++;
           totalBytes += nbytes;
        }
	if(monitorInterval != 0 && (currentSeqno % monitorInterval == 0)){ 
	  if(disableMonitor){
              monitor = TRUE;            	   	   	                    
	  }
        }
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint32_t Monitor.getNBytes(){
	return totalBytes;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint32_t Monitor.getNPackets(){
	return totalPackets;
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint16_t Monitor.getMonitorSeqno(){
	return monitorSeqno;
    }

   /*-------------------------------------------------------------------------------------------*/     
    command uint32_t Monitor.getSenderTime(){
	return (uint32_t)call Timer0.getNow();
    }
 
   /*-------------------------------------------------------------------------------------------*/     
    command bool Monitor.isSending(){
       return monitor;
    }

    command void Monitor.sendMonitor(){
	post SendMonitorTask();
	monitor = FALSE;
    }

    command void Monitor.set(bool val){
       monitor = val;
    }

    command void Monitor.enable(){
	disableMonitor = TRUE;
    }
    command void Monitor.disable(){
	disableMonitor = FALSE;
    }
    command void Monitor.enableAuto(){
	disableMonitor = TRUE;
	send_automatic = TRUE;
    }
    command void Monitor.disableAuto(){
        send_automatic = FALSE;
    }
    command bool Monitor.isAuto(){
	return send_automatic;
    }
    command void Monitor.setPktType(uint8_t type){
	monitor_type = type;
    }

    //
   /*-------------------------------------------------------------------------------------------*/
    command void NodeRole.setNodeRole(uint8_t role){
	nodeRole = role;
	if(role == ROUTER_ROLE){
	   nodeTTLValue = ROUTER_ENTRY_TTL;
	}else{
           nodeTTLValue = ROUTER_ENTRY_TTL;
        }
        call LinkLayer.setNodeRole(nodeRole);
    }

   /*-------------------------------------------------------------------------------------------*/
    command void NodeRole.setNodeAsRouter(){
	nodeRole     = ROUTER_ROLE;
	nodeTTLValue = ROUTER_ENTRY_TTL;
        call LinkLayer.setNodeRole(nodeRole);
    }

   /*-------------------------------------------------------------------------------------------*/
    command void NodeRole.setNodeAsMobile(){
	nodeRole     = MOBILE_ROLE;
	nodeTTLValue = ROUTER_ENTRY_TTL;
	call LinkLayer.setNodeRole(nodeRole);
    }

   /*-------------------------------------------------------------------------------------------*/
    command uint8_t NodeRole.getRole(){
	return nodeRole;
    }

/*-------------------------------------------------------------------------------------------*/
    task void SendMonitorTask(){
	error_t returnVal;
        uint8_t len = sizeof(monitor_t);
	monitor_t *p = call Send.getPayload(&msg, sizeof(monitor_t));       
	p->df0       = 0x7E;
        p->seqno     = monitorSeqno;
        p->stime     = call Monitor.getSenderTime();
	p->type      = monitor_type;
        p->npackets  = call Monitor.getNPackets();
	p->nbytes    = call Monitor.getNBytes();
        p->df1       = 0x7E;
	
        call Send.setPacketType(&msg, 1);
        returnVal = call Send.send(&msg, len);
	if(returnVal == SUCCESS){
	     monitorSeqno++;	     
             call Leds.led1Toggle();
        }else if(returnVal == EBUSY){
	  post SendMonitorTask();
	}          
  }
/*-------------------------------------------------------------------------------------------*/
  event void Send.sendDone(message_t *p, error_t err){
	
  }
  
}

