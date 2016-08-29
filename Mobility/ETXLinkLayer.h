
/*------------------------------------------------------------------------+
 *School of Electrical Engineering/School of Technology and Health        +
 +  Master Program In Network Services and Systems                        +
 +	Master Thesis..Project                                            +
 +------------------------------------------------------------------------*	
 + author: Gonga, Antonio - gonga@kth.se				  +
 + Date created:  January 03, 2009 02:40:45 AM                             +
 + Date modified: January 31, 2009 17:40:45 PM                             +
 +------------------------------------------------------------------------*/

#ifndef __ETXLINKLAYER_H_
#define __ETXLINKLAYER_H_


#define EXPECTED_BEACONS    3
#define EXPECTED_DATA_PKTS  10
#define ROUTER_ENTRY_TTL    6

//#define INVALID_ETX         254

#define NEIGHBOR_TBL_LEN    8
#define RESTART_ENTRY       10
#define ROUTER_TTL          6


#define ROUTING_TBL_LEN     NEIGHBOR_TBL_LEN
#define MONITOR_PKT_DT      75


	enum{
	   AM_BEACON_MSG   = 200,   //advertisement messages... beacons AM group
	   AM_ETXDATA_MSG  = 201    //data AM type
	};


	enum{
	   TYPE_DATA       = 0,
	   TYPE_MONITOR    = 1,
	   BUFR_QUEUE_LEN  = 4,
	   INVALID_ETX     = 0x5a
	};
	
	enum{
	  ROUTER_ROLE  = 0,
	  MOBILE_ROLE  = 1,
	  MOBILE_ROLE1 = 2
	};

	typedef nx_struct beacon{
	    nx_uint8_t  seqno;         //beacon sequence number
	    nx_uint8_t  metric;         //advertised Expected Transmission from the node ETX
	    nx_uint16_t parent;	   
	    nx_uint8_t  etxs[NEIGHBOR_TBL_LEN];
	    nx_uint16_t neighbor[NEIGHBOR_TBL_LEN];
	}beacon_t;


	typedef struct neighbor_tbl{
           uint8_t   active;            //
	   uint8_t   ttl;		//time to live
	   uint16_t  from;		//which neighbor sent the packet
           uint16_t  parent;
           uint16_t  e_etx;		//entry etx->calculated on the node
	   uint8_t   lastseqno;		//last parent/neighbor beacon sequence number
	   uint8_t   nrecvdbcn;		//number of received beacons
	   uint8_t   nfaildbcn;		//number of failed beacons
	   uint8_t   etx_df;            //forward quality estimator
	   uint8_t   etx_dr;            //reverse quality estimator
	   uint8_t   total;
	   uint8_t   data_ctr;
	}neighbor_tbl_t;

	typedef struct{
	    uint16_t metric;         //advertised Expected Transmission from the node ETX
	    uint16_t parent;	       //which parent is currently serving the node
	    uint16_t rssi; 
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
	   uint16_t  metric;		//advertised etx->received from the parent..
           uint16_t  parent;
	   uint16_t  rssi;
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
        
        #ifndef BEACON_MSG_LEN
	#define BEACON_MSG_LEN  sizeof(beacon_t)
	#endif
#endif

