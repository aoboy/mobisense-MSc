/*
 *
 *@author: gonga , gonga@kth.se
 *Date: Tue April 15, 2008 - 13:56:17
 *-----------------------------------------------*/
 #ifndef _SNIFFER_H_
 #define _SNIFFER_H_
 #include "CC2420.h"
 
#if TOSH_DATA_LENGTH > 28
  #define MAXPAYLOAD_LEN  28
#else
  #define MAXPAYLOAD_LEN TOSH_DATA_LENGTH
#endif

 enum{
   AM_TIMESTAMPMSG  = 20,
   AM_FILTERMSG     = AM_TIMESTAMPMSG,
 };

 #ifdef CC2420_IFRAME_TYPE 
   #ifndef TINYOS_IP
	#define  MAC_HDR_LEN    sizeof(cc2420_header_t)
   #else
	#define   MAC_HDR_LEN    11
   #endif
 #else 
	 #define  MAC_HDR_LEN    11
 #endif

 typedef nx_struct TimestampMsg{
    nx_uint8_t  mac_hdr[MAC_HDR_LEN];
    nx_uint32_t time;       //root time Stamp
    nx_uint8_t  len;        //message length(whole packet?? or just payload?? = just payload)
    nx_uint8_t  data[MAXPAYLOAD_LEN];     //MAXPAYLOAD_LEN
 }Timestamp_t;


 typedef nx_struct FilterMsg{
    nx_uint16_t src_addr;
    nx_uint16_t dst_addr;
    nx_uint8_t  val;         //00 (nothing), 01(filter by src_addr), 10(filter by dst_addr), 11(filter by src and dst_adds)
 }FilterMsg;

 #endif
