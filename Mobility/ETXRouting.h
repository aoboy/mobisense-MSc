/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created: January 09, 2009 02:10:45 AM                             +
 +------------------------------------------------------------------------*/

#ifndef __ETXROUTING_H_
#define __ETXROUTING_H_


#define ROUTING_TBL_LEN     8
#define ROUTER_TTL          5
#define MOBILE_TTL          5	
#define MONITOR_PKT_DT      100

	enum{
	   AM_ETXDATA_MSG  = 201    //data AM group
	};

	enum{
	   TYPE_DATA       = 0,
	   TYPE_MONITOR    = 1,
	   BUFR_QUEUE_LEN  = 15
	};
	
	enum{
	  ROUTER_ROLE  = 0,
	  MOBILE_ROLE  = 1,
	  MOBILE_ROLE1 = 2
	};

	typedef struct{
	    uint8_t  metric;         //advertised Expected Transmission from the node ETX
	    uint16_t parent;	       //which parent is currently serving the node
	    int16_t  rssi; 
	}route_t;


	typedef nx_struct routing_hdr{
	   nx_uint8_t  type;		//WHICH type of data the payload is carrying in
	   nx_uint8_t  hopcount;	//how many hops has the data traserved 
	   nx_uint16_t seqno;		//which the packet sequence number... not be confused with DSN field in the header
	   nx_uint16_t orig_addr;	//packet originator address
	}routing_hdr_t;

	typedef struct routing_tbl{
           uint8_t   active;            //
	   uint8_t   ttl;		//time to live
           uint16_t  src;               //source address..
	   uint8_t   metric;		//advertised etx->received from the parent..
           uint16_t  parent;
	   int16_t   rssi;
	}routing_tbl_t;


	typedef nx_struct monitor{
	  nx_uint8_t    df0;	  
	  nx_uint32_t   stime;
	  nx_uint8_t    type;
	  nx_uint16_t   seqno;	  
	  nx_uint32_t   npackets;
	  nx_uint32_t   nbytes;
	  nx_uint8_t    df1;
	}monitor_t;

	#ifndef ROUTING_HDR_LEN
	#define ROUTING_HDR_LEN  sizeof(routing_hdr_t)
	#endif

#endif

