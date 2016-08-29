/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 31, 2009 17:40:45 AM                             +
 +------------------------------------------------------------------------*/

#include "ETXLinkLayer.h"

module ETXLinkLayerP{
  provides{
	interface SendBeacon;
	interface ReceiveBeacon;
	interface LinkLayer;
  }uses{
	interface Leds;
	interface AMPacket;
	interface Packet;
	interface Timer<TMilli> as updtTimer;
	interface AMSend as SendBcn;
	interface Receive as BeaconRcv;
  }
}
implementation{

 enum{
    INVALID_ADDR  = 0xffff,
    INVALID_IDX   = 0xf,
    ETX_THRESHOLD = 50
  };
   
  message_t msg;                 //messages 
  
  neighbor_tbl_t neighbors[NEIGHBOR_TBL_LEN];

  bool root_flag ;               //the root does not send messages
  bool radioBusy ;               //two instances cannot send messages at the same time

  bool initFlag;                //I'm initializing... will be suppressed
 
  uint8_t  beaconSeqno;         //beacon sequence number

  uint8_t nodeRole = ROUTER_ROLE;
  uint8_t nodeTTLValue;
  
  //Function Prototypes  
  void initialize(); 

  beacon_t* getBeacon(message_t* p);

  void setEXTdr(uint8_t idx, beacon_t *b);

  inline uint8_t getIdx(uint16_t addr);

  void updateDataETX(neighbor_tbl_t *etr);

  uint8_t findAvailableEntry();

  uint16_t computeLinkETX(uint8_t dr, uint8_t df);

  void updateEntryETX(uint16_t);

  void setEntry(neighbor_tbl_t *entry, beacon_t *b, uint16_t *src_addr);

  void updateEntry(beacon_t* b, uint16_t *src_addr, uint8_t idx);

  void NeighborAddEntry(beacon_t* b, uint16_t *src_addr);


  task void updateNeighborsTask();

 /*-------------------------------------------------------------------------------*/
  beacon_t* getBeacon(message_t* p){
     return (beacon_t*)(call Packet.getPayload(p, BEACON_MSG_LEN));   
  }

 /*-------------------------------------------------------------------------------------------*/
 void initialize(){
    int k;
       for(k = 0; k < NEIGHBOR_TBL_LEN; k++){
	    neighbors[k].parent     = INVALID_ADDR;
	    neighbors[k].active     = 0;
	    neighbors[k].lastseqno  = 0;
	    neighbors[k].ttl        = 0;
	    neighbors[k].nrecvdbcn  = 0;
	    neighbors[k].nfaildbcn  = 0;
	    neighbors[k].from       = INVALID_ADDR;
	    neighbors[k].parent     = INVALID_ADDR;
	    neighbors[k].e_etx      = INVALID_ETX;
	    neighbors[k].etx_df     = 0;
            neighbors[k].etx_dr     = 0;
            neighbors[k].total      = 0;
	    neighbors[k].data_ctr   = 0;
       }
	
       atomic{
	  beaconSeqno     = 0;
	  nodeTTLValue    = ROUTER_ENTRY_TTL;	  
       }
  }

 /*-------------------------------------------------------------------------------------------*/
  void setEXTdr(uint8_t idx, beacon_t *b){
   uint8_t n;
	for(n = 0; n < NEIGHBOR_TBL_LEN; n++){
	   if(b->neighbor[n]== neighbors[idx].from){
	      neighbors[idx].etx_dr = b->etxs[n];
	      neighbors[idx].ttl    = 0;	     
	   }
	}	
  }   

/*-------------------------------------------------------------------------------------------*/
 inline uint8_t getIdx(uint16_t addr){
    uint8_t k;
	for(k = 0; k < NEIGHBOR_TBL_LEN; k++){
	    if((neighbors[k].active == 1) && (neighbors[k].from == addr)){
		return k;
	    }
	}

     return INVALID_IDX;
 } 

/*-------------------------------------------------------------------------------------------*/
  void updateDataETX(neighbor_tbl_t *etr){
     uint8_t etx;
	
       if(etr->data_ctr == 0){
	  etx = INVALID_ETX;
       }else{
	  etx = (etr->total*10)/etr->data_ctr;
       }
       etr->e_etx = etx;
  }

/*____________________________________________________+
 +      | EXPECTED TRANSMISSIONS (ETX) TABLE)         +
 +------+---------------------------------------------+
 +            ETX10 = 10*ETX = 10*ETXr.ETXf           |
 +------+------+------+------+------+------+----------+
 + dr/df|  10  |  12  |  16  |  25  |  50  | INFINITY |
 +------+------+------+------+------+------+----------+
 +  10  |  10  |  12  |  16  |  25  |  50  | INFINITY |
 +------+------+------+------+------+------+----------+
 +  12  |  12  |  14  |  19  |  30  |  60  | INFINITY |
 +------+------+------+------+------+------+----------+
 +  16  |  16  |  19  |  25  |  40  |  80  | INFINITY | 
 +------+------+------+------+------+------+----------+     
 +  25  |  25  |  30  |  50  |  62  |  125 | INFINITY |
 +------+------+------+------+------+------+----------+
 +  50  |  50  |  60  |  80  |  125 |  250 | INFINITY | 
 +----------------------------------------------------+
 + Beacon Window Size  5 (just an Example)
 + Beacon Received(ndr || ndf)  0    1   2    3    4     5 
 + Expected Transm             IN    5   2.5  1.6  1.25  1
 + ETXr = 1/dr = 1/(ndr/Wr) = Wr/ndr
 + ETXf = 1/df = 1/(ndf/Wf) = Wf/ndf
 + ETX  = ETXr*ETXf
 **/
 /*---------------------------------------------------------------------------------------*/  
  uint16_t computeLinkETX(uint8_t dr, uint8_t df){
    uint16_t etxVal;

	if((dr >0) && (df > 0)){
	   etxVal = (df*dr)/10;	 
	   if(etxVal < 50){		
		return (uint16_t)etxVal;
	   }else{ 
	      return (uint16_t)INVALID_ETX;
	   }
	}else{
	   return INVALID_ETX;
	}	
  }

 /*-------------------------------------------------------------------------------------------*/  
   void updateEntryETX(uint16_t addr){
     uint8_t etx, n;  
     uint8_t ttlPkts;
     neighbor_tbl_t *entry;


    for(n = 0; n < ROUTING_TBL_LEN; n++)
    {     
	entry = &neighbors[n];
	if(entry->from == addr && entry->active != 0){
		  
    	    ttlPkts = entry->nfaildbcn + entry->nrecvdbcn;
	    if(ttlPkts < EXPECTED_BEACONS){
		ttlPkts = EXPECTED_BEACONS;
	    }	
	    etx  =  (uint8_t)((10*ttlPkts)/entry->nrecvdbcn);
	    entry->etx_df    = etx;
	    entry->nfaildbcn = 0;
	    entry->nrecvdbcn = 0;
	    entry->e_etx       = computeLinkETX(entry->etx_dr, entry->etx_df);				  		    
	  }
      }
  }

 /*-------------------------------------------------------------------------------------------*/
  void setEntry(neighbor_tbl_t *entry, beacon_t *b, uint16_t *src_addr){
     atomic{
	  entry->active      = 1;
	  entry->ttl         = 0;
	  entry->from        = *src_addr;
	  entry->lastseqno   = b->seqno;
	  entry->nrecvdbcn   = 1;
	  entry->nfaildbcn   = 0;
	  entry->e_etx       = INVALID_ETX;
	  entry->etx_dr      = 0;
	  entry->etx_df      = 0;
          entry->total       = 0;
          entry->data_ctr    = 0;
     }
  }

 /*-------------------------------------------------------------------------------------------*/ 
 void updateEntry(beacon_t* b, uint16_t *src_addr, uint8_t idx){
	uint8_t n;
	uint8_t ttlPkts;
	uint8_t diffSeqno;
        uint16_t my_addr;
        uint8_t etx, etxWindow;

	atomic{ 		
	     if((b->seqno - neighbors[idx].lastseqno) < 0){
	         diffSeqno = (uint8_t)(256 - neighbors[idx].lastseqno + b->seqno);
	     }else{
	         diffSeqno = (uint8_t)(b->seqno - neighbors[idx].lastseqno);
	     }

     	     etxWindow = EXPECTED_BEACONS;

	     neighbors[idx].active      = 1;
	     neighbors[idx].ttl         = 0;
	     neighbors[idx].from        = *src_addr;
	     neighbors[idx].parent      = b->parent;
	     neighbors[idx].lastseqno   = b->seqno;
	     neighbors[idx].nrecvdbcn   = 1 + neighbors[idx].nrecvdbcn;
	     neighbors[idx].nfaildbcn   = neighbors[idx].nfaildbcn + diffSeqno - 1;

	     my_addr = call AMPacket.address();
	     for(n = 0; n < NEIGHBOR_TBL_LEN; n++){
	       if(my_addr == b->neighbor[n]){
	           neighbors[idx].etx_dr = b->etxs[n];
	       }
	     }	
   
	     if(diffSeqno >= RESTART_ENTRY){
	        neighbors[idx].nrecvdbcn  = 1;
	        neighbors[idx].nfaildbcn  = 0;
	        neighbors[idx].e_etx      = INVALID_ETX;
                neighbors[idx].etx_df     = 0;
		neighbors[idx].etx_dr     = 0;
	     }
	     if(neighbors[idx].nrecvdbcn >= etxWindow){		
		ttlPkts = neighbors[idx].nfaildbcn + neighbors[idx].nrecvdbcn;
		if(ttlPkts < EXPECTED_BEACONS){
		    ttlPkts = EXPECTED_BEACONS;
		}	
		etx  =  (uint8_t)((10*ttlPkts)/neighbors[idx].nrecvdbcn);
		neighbors[idx].etx_df    = etx;
		neighbors[idx].nfaildbcn = 0;
		neighbors[idx].nrecvdbcn = 0;
 	        neighbors[idx].e_etx = computeLinkETX(neighbors[idx].etx_dr, neighbors[idx].etx_df);				  		  
	     } //end of if >= etxWindow
      } //end of atomic
  } 

 /*-------------------------------------------------------------------------------------------*/ 
  void NeighborAddEntry(beacon_t* b, uint16_t *src_addr){
    uint8_t idx=0xff;
        
	idx = getIdx(*src_addr);

	if(idx < NEIGHBOR_TBL_LEN){	  	  	    	 
	   updateEntry(b, src_addr, idx);	   	      	
        }else{	                     
               //This is an insertion
	       idx = findAvailableEntry();	       				 
	       setEntry(&neighbors[idx], b, src_addr);	      		   
	}        
  }
 
/*-------------------------------------------------------------------------------------------*/
 command void LinkLayer.initLinkLayer(){
	initialize();
	nodeRole = ROUTER_ROLE;
	call updtTimer.startPeriodic(1024);
 }

/*-------------------------------------------------------------------------------------------*/
 command void LinkLayer.setRoot(){
   root_flag    = TRUE;  
   nodeRole = ROUTER_ROLE; 
   nodeTTLValue = ROUTER_TTL;   
 }

/*-------------------------------------------------------------------------------------------*/
 command void LinkLayer.unsetRoot(){
    root_flag  = FALSE;
 }
/*-------------------------------------------------------------------------------------------*/
command void LinkLayer.setNodeRole(uint8_t role){
  nodeRole = role;
    if(role == ROUTER_ROLE){
	 nodeTTLValue = ROUTER_TTL;         
    }
}
/*-------------------------------------------------------------------------------------------*/
  command bool LinkLayer.exists(am_addr_t addr){
	return ((uint8_t)call LinkLayer.getIdxByAddr(addr) < INVALID_IDX ) ? TRUE: FALSE;
  }

 /*-------------------------------------------------------------------------------------------*/
  command uint8_t LinkLayer.getIdxByAddr(am_addr_t addr){
     uint8_t k;
     neighbor_tbl_t *ptr;

	for(k = 0; k < NEIGHBOR_TBL_LEN; k++){
	    ptr = &neighbors[k];
	    if(ptr->active != 0 && ptr->from == addr){
		return k;
	    }
	}

     return INVALID_IDX;
  }

 /*-------------------------------------------------------------------------------------------*/
  command uint16_t LinkLayer.getEtxByAddr(uint16_t addr){
     uint8_t idx;
	for(idx = 0; idx < NEIGHBOR_TBL_LEN; idx++){
	    if(neighbors[idx].from == addr){     
	       return neighbors[idx].e_etx;
	    }
	}      
	
     return INVALID_ETX;
  }

 /*-------------------------------------------------------------------------------------------*/
  uint8_t findAvailableEntry(){
     uint8_t idx,k;
     uint8_t min = 0;

       for(k = 0; k < NEIGHBOR_TBL_LEN; k++){
	   if(neighbors[k].active == 0){
		return k;		
	   }
       }
      
      //we are not succeded, lets find the one not sending anything for long time
      for(k = 0, idx = 0; k < NEIGHBOR_TBL_LEN; k++){
	    if(neighbors[k].e_etx > min){
		idx = k;
		min = neighbors[k].e_etx;
	    }
      }
      
    return idx;        
  }

 /*-------------------------------------------------------------------------------------------*/
  command void LinkLayer.dataFailed(uint16_t addr){
    uint8_t idx;
         
      if(nodeRole == MOBILE_ROLE){
	return;
      }
      idx = getIdx(addr);
      if(idx < INVALID_IDX){
	neighbors[idx].total++;
	if(neighbors[idx].total >= EXPECTED_DATA_PKTS){
	    updateDataETX(&neighbors[idx]);
	}
      }	  
  }
/*-------------------------------------------------------------------------------------------*/
  command void LinkLayer.dataSuccess(uint16_t addr){
    uint8_t idx;
         
      if(nodeRole == MOBILE_ROLE){
	return;
      }
      idx = getIdx(addr);
      if(idx < INVALID_IDX){
	neighbors[idx].data_ctr++;
	neighbors[idx].total++;
	if(neighbors[idx].total >= EXPECTED_DATA_PKTS){
	    updateDataETX(&neighbors[idx]);
	}
      }	  
  }
/*-------------------------------------------------------------------------------------------*/
 /*-------------------------------------------------------------------------------------------*/
  command error_t SendBeacon.send(uint16_t etx, uint16_t parent)
  {
      uint8_t k;
      neighbor_tbl_t *ptr;
      beacon_t *beacon = getBeacon(&msg);    

      if(radioBusy || nodeRole == MOBILE_ROLE){
	return FAIL;
      }

      if(root_flag){		
           beacon->seqno   = beaconSeqno++;
	   beacon->metric  = (uint8_t)0;
	   beacon->parent  = (uint16_t)parent;	
      }else{			  
            beacon->seqno   = beaconSeqno++;
	    beacon->metric  = (uint8_t)(etx  +  (uint8_t)call LinkLayer.getEtxByAddr(parent)) ;	
 	    beacon->parent  = parent;	    
      }
  
       for(k = 0 ; k < NEIGHBOR_TBL_LEN; k++){	 
	     ptr = &neighbors[k];
	     beacon->etxs[k]     = ptr->etx_df;
	     beacon->neighbor[k] = ptr->from;	 
       }
          radioBusy = TRUE;
      return call SendBcn.send(TOS_BCAST_ADDR, &msg, sizeof(beacon_t));
	  
  }

 /*-------------------------------------------------------------------------------------------*/
  event void SendBcn.sendDone(message_t *p, error_t success){    
        radioBusy = FALSE; 
	signal SendBeacon.sendDone(success);    
  }

  /*-------------------------------------------------------------------------------------------*/
  event message_t* BeaconRcv.receive(message_t* p, void* payload, uint8_t len){
     uint16_t src_addr;
     beacon_t *bcn = (beacon_t*)call Packet.getPayload(p, sizeof(beacon_t));
    
     src_addr = call AMPacket.source(p);
     if((call AMPacket.type(p) == AM_BEACON_MSG)){
	if(nodeRole == ROUTER_ROLE){	
		NeighborAddEntry(bcn, &src_addr);
	}else{
	   //call Leds.led2Toggle();
	}        
	signal ReceiveBeacon.receive(p, payload, len);
	
     }else{
	call Leds.led1Toggle();
     }
    return p;
  } 
 

 task void updateNeighborsTask(){
   uint8_t idx;
   neighbor_tbl_t *entry;

    for(idx = 0; idx < NEIGHBOR_TBL_LEN; idx++){
	entry = &neighbors[idx];
	if(entry->active == 1){
	   entry->ttl++;
	   if(entry->ttl >= nodeTTLValue){
		entry->active = 0;
		entry->etx_df = 0;
		entry->from   = INVALID_ADDR;
	   }
	}
    }

 }

 event void updtTimer.fired(){
      post updateNeighborsTask();
 }
 
 default event message_t* ReceiveBeacon.receive(message_t* p, void* payload, uint8_t len){
    return p;
 }
 
 default event void SendBeacon.sendDone(error_t err){

 }

}


