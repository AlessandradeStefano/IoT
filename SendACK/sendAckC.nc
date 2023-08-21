/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"
module sendAckC {

  uses {
	interface Boot;
    	interface AMPacket;
	interface Packet;
	interface PacketAcknowledgements;
    	interface AMSend;
	interface AMSend as AMSerialSend;
	interface Packet as SerialPacket;
    	interface SplitControl;
	interface SplitControl as SerialSplitControl;
    	interface Receive;
    	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as MissingTimer;
	interface Timer<TMilli> as SendTimer;
	interface Random;
	interface Read<uint16_t>;
  }

} implementation {


  uint8_t idKey[20];
  uint16_t lastX;
  uint16_t lastY;
  message_t packet;
  
  task void sendReq();
  void sendREQResp();
  void sendSerialPacket(uint8_t v);
  task  void sendDataResp();
  
  //***************** Task send request ********************//
  task void sendReq() {
	
	int i = 0;
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	/*if (locked) {
	dbg("radio_send", "lock deleted");
     	 return;
  	  }*/

	mess->msg_type = REQ;
	mess->address_id = TOS_NODE_ID;
	for(i = 0; i < 20 ;i++) mess->key[i] = idKey[i];
	dbg("radio_send", "i'm %d , Try to send a request in broadcast at time %s \n",TOS_NODE_ID, sim_time_string());
    
	//call PacketAcknowledgements.requestAck( &packet );

	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      
      }

 }        

  //****************** Task send response *****************//
  task void sendDataResp() {
// send data periodically
	call SendTimer.startPeriodic(3000);
  }

  void sendREQResp() {
// send a simply resp to say that they are matched
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = REQACK;
	mess->address_id = TOS_NODE_ID;
	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(rec_id[TOS_NODE_ID-1],&packet,sizeof(my_msg_t)) == SUCCESS){
		
	dbg("radio_send", "i'm %d , Try to send a response to %d request at time %s \n",TOS_NODE_ID,rec_id[TOS_NODE_ID-1], sim_time_string());
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
        }
    }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	int i = 0;
	dbg("boot","Application booted.\n");

//Only at first run create 2 global keys. Then when a mote is created set the right key as its own. 
	if(counter == 0){
	 
		for(; i < 20 ; i = i+2){
			int ran = call Random.rand16();
			idKey1[i] = ran & 0xff;
			idKey1[i+1] = (ran >> 8);
			ran = call Random.rand16();
			idKey2[i] = ran & 0xff;
			idKey2[i+1] = (ran >> 8);
		}
	}
	if(TOS_NODE_ID == 1 || TOS_NODE_ID == 2){ for(i = 0; i < 20 ;i++) idKey[i] = idKey1[i];}
	else{ for(i = 0; i < 20 ;i++) idKey[i] = idKey2[i];}
	counter = counter+1 ;

	call SerialSplitControl.start();
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
event void SerialSplitControl.startDone(error_t err){}
  event void SplitControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");
	  dbg("role","I'm node %d :  start sending periodical request\n", TOS_NODE_ID);
	  call MilliTimer.startPeriodic( 1500 );

    }
    else{
	call SplitControl.start();
    }

  }
  event void SerialSplitControl.stopDone(error_t err){}
  event void SplitControl.stopDone(error_t err){}

 void sendSerialPacket(uint8_t v){

	serial_msg_t* cm = (serial_msg_t*)call SerialPacket.getPayload(&packet, sizeof(serial_msg_t));
      if (cm == NULL) {return;}
      if (call SerialPacket.maxPayloadLength() < sizeof(serial_msg_t)) {
	return;
      }

      cm->sample_value = v;
      if (call AMSerialSend.send(AM_BROADCAST_ADDR, &packet, sizeof(serial_msg_t)) == SUCCESS) {
	dbg("role","Serial Packet sent...\n");
      }
}

  //***************** MilliTimer, MissingTimer interface ********************//
  event void MilliTimer.fired() {
	post sendReq();
  }
  
  event void MissingTimer.fired() {

	sendSerialPacket(1);
	dbg("role","Your child is missed! no info for a minute. Last position %hhu , %hhu \n" , lastX , lastY);
 
}

  event void SendTimer.fired() {
 	call Read.read();
  }
  //********************* AMSend interface ****************//
event void AMSerialSend.sendDone(message_t* buf,error_t err) {}
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	dbg("radio_send", "Packet sent...");
    
	
		if ( call PacketAcknowledgements.wasAcked( buf ) ) {
		  dbg_clear("radio_ack", "and ack received");}
	

	dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }

  }

  //***************************** Receive interface *****************//

 event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	
	my_msg_t* mess=(my_msg_t*)payload;
		
	if ( mess->msg_type == REQ) {
		bool match = TRUE;
		int i = 0;
		
		dbg("role", "I'm %d : request received a match REQ from %d \n" , TOS_NODE_ID , mess->address_id );
		while(i<20) {		
			if(mess-> key[i] != idKey[i]) match=FALSE;
		i = i+1;
		}
	
		if(match){
		dbg("role", "matched with %d \n" ,mess->address_id);
		//if match stop sending requests
		call MilliTimer.stop();
		dbg("role", "matched, stop sending REQ \n");
		rec_id[TOS_NODE_ID-1] = mess->address_id;
		
		//say to sender that they matched
		sendREQResp();
			//if child start sending data
			if(TOS_NODE_ID == 2 || TOS_NODE_ID == 4){ post  sendDataResp();	}
		}
		else{ dbg("role", "match FAILED with %d \n", mess->address_id);}
	}
	// parents send a simply resp to say that they are matched
	else if (mess->msg_type == RESP){	
	dbg("role", "I'm %d : request received RESP from %d \n" , TOS_NODE_ID ,mess->address_id);

		//if i'm a parent
		if(TOS_NODE_ID == 1 || TOS_NODE_ID == 3){
			//update last child position
			lastX = mess->xValue;
			lastY = mess->yValue;
			if(mess->statusValue == 3){
			sendSerialPacket(2);
			 dbg("role","Your child is fallen! last position was: %hhu , %hhu  \n", mess->xValue,  mess->yValue );
			}
			//reset missing timer to 60 seconds (6 seconds for debug)
			call MissingTimer.stop();
			call MissingTimer.startOneShot(1000*6);
		}
	}
		//if I'm a child, parent's brachelet has matched with me and send a RESP to me. save its address and start sending.
	else if (mess->msg_type == REQACK){ 

	//if a REQACK arrives, then someone has matched me so stop send requests.
		call MilliTimer.stop();
		dbg("role", "matched, stop sending REQ \n");
		rec_id[TOS_NODE_ID-1] = mess->address_id;
		//if child start sending data
		if(TOS_NODE_ID == 2 || TOS_NODE_ID == 4){ post sendDataResp();	}	
	}
    return buf;
  }	
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_type = RESP;
	mess->address_id = TOS_NODE_ID;

	mess->xValue = call Random.rand16();
	mess->yValue = call Random.rand16();
	mess->statusValue = data;

	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(rec_id[TOS_NODE_ID-1],&packet,sizeof(my_msg_t)) == SUCCESS){
			
	dbg("radio_send", "i'm %d , Try to send a data response to %d at time %s \n",TOS_NODE_ID,rec_id[TOS_NODE_ID-1], sim_time_string());
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t Latitude: %hhu \n ", mess->xValue);
	  dbg_clear("radio_pack", "\t\t Longitude: %hhu \n ", mess->yValue);
	if(mess->statusValue == 0) dbg_clear("radio_pack", "\t\t status_value: STANDING \n");
	else if(mess->statusValue == 1) dbg_clear("radio_pack", "\t\t status_value: WALKING \n"); 
	else if(mess->statusValue == 2) dbg_clear("radio_pack", "\t\t status_value: RUNNING \n"); 
	else if(mess->statusValue == 3) dbg_clear("radio_pack", "\t\t status_value: FALLING \n"); 
	  
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");

       }
     }

}

