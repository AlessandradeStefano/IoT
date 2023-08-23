#include "Timer.h"
#include "PubSubApp.h"
#include <string.h>

module PubSubAppC {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer0;
    interface Timer<TMilli> as MilliTimer1;
    interface Timer<TMilli> as MilliTimer2;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;

  uint8_t connected[9] = {0,0,0,0,0,0,0,0,0};

  bool sub = FALSE;
  bool second_sub = FALSE;
  // topics: 1 if node i+2 is subscribed, 0 otherwise
  uint8_t temperature[8] = {0,0,0,0,0,0,0,0};
  uint8_t humidity[8] = {0,0,0,0,0,0,0,0};
  uint8_t luminosity[8] = {0,0,0,0,0,0,0,0};
  
  void sendACK(uint16_t sender_ID, uint8_t type);
  void sendCON();
  void sendSUB(uint8_t topic);
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {

      printf("radio on\n");
      printfflush();
      
      call MilliTimer0.startOneShot(1000);
    }
    else {
      call AMControl.start();

      printf("radio fail, id %d\n", TOS_NODE_ID);
      printfflush();

    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  


  /*** APPLICATION PROCEDURES ***/

  // start CONNECT procedure
  event void MilliTimer0.fired() {
    if (locked) {
      return;
    }
    else {
      // if worker node, send CONNECT message to PANC 
      if (TOS_NODE_ID != 1){
        sendCON();
      }

      call MilliTimer1.startOneShot(10000); // connection timeout
    }
  }

  // start SUBSCRIBE procedure
  event void MilliTimer2.fired() {
    if (locked) {
      return;
    }
    else {
      // each node subscribes to a topic based on his ID
      uint8_t topic = (TOS_NODE_ID % 3); 
      if (second_sub && (TOS_NODE_ID % 3 == 0)) topic = 1; // if subscribed to TEMPERATURE, subscribe also to HUMIDITY
      sendSUB(topic);

      call MilliTimer3.startOneShot(10000); // subscribe timeout
    }
  }



  /*** RETRANSMISSION PROCEDURES ***/  

  // handle retransmission of connect
  event void MilliTimer1.fired() {
    if (locked) {
      return;
    }
    else {
      if (TOS_NODE_ID != 1){
        if (connected[TOS_NODE_ID-1] != 1) call MilliTimer0.startOneShot(1000); // try reconnection
      }
    }
  }

  // hande retransmission of subscribe
  event void MilliTimer3.fired() {
    if (locked) {
      return;
    }
    else {
      if (TOS_NODE_ID != 1){
        if (sub == FALSE) call MilliTimer2.startOneShot(1000); // try reconnection
        else if ((TOS_NODE_ID % 3 == 0) && second_sub == FALSE) {
          sub = FALSE;
          second_sub = TRUE;
          call MilliTimer2.startOneShot(10000); 
        }
      }
    }
  }



  /*** HANDLING PACKET RECEIVING ***/

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {

    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm_r = (radio_count_msg_t*)payload;
      uint16_t sender = rcm_r->sender_ID;

      /** PANC **/
      if (TOS_NODE_ID == 1){

        if (rcm_r->messageType == 0) { // receive CONNECT
          connected[sender-1] = 1;
          sendACK(sender, 1);
        } else if (rcm_r->messageType == 2 && connected[sender-1]) { // receive SUBSCRIBE
          if (rcm_r->topic == 0) temperature[sender-2] = 1;
          else if (rcm_r->topic == 1) humidity[sender-2] = 1;
          else if (rcm_r->topic == 2) luminosity[sender-2] = 1;
          }
          sendACK(sender, 3);
        }



      /** WORKER **/
      } else {
        if (rcm_r->messageType == 1) { // receive CONNACK 
          connected[TOS_NODE_ID-1] = 1;
          
          printf("node connected\n");
       	  printfflush();
       	  
          call Leds.led1Toggle();

          // subscribe to a topic
          call MilliTimer2.startOneShot(10000);

        } else if (rcm_r->messageType == 3) { // receive SUBACK 
          sub = TRUE;

          printf("node subscribed\n");
       	  printfflush();

          call Leds.led2Toggle();

        }
        
      }
     
    }
    return bufPtr;
  }



  /*** SEND PACKET FUNCTIONS ***/

  void sendCON(){
        radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
        if (rcm == NULL) return;

        rcm->sender_ID = TOS_NODE_ID;
        rcm->messageType = 0;
        rcm->destination = 1;
        rcm->payload = 0;
        
        printf("sending CONNECT\n");
       	printfflush();

        if (call AMSend.send(1, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
          locked = TRUE;
        }
  }

  void sendSUB(uint8_t topic){
          radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
          if (rcm == NULL) return;

          rcm->messageType = 2;
          rcm->sender_ID = TOS_NODE_ID;
          rcm->destination = 1;
          rcm->topic = topic;
          
          printf("sending SUBSCRIBE (topic: %d)\n", topic);
       	  printfflush();

          if (call AMSend.send(1, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
            locked = TRUE;
          }
  }

  void sendACK(uint16_t sender_ID, uint8_t type){
          radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
          if (rcm == NULL) return;

          rcm->sender_ID = TOS_NODE_ID;
          rcm->messageType = type;
          rcm->destination = sender_ID;
          
          printf("sending ACK (%d)\n", type);
       	  printfflush();

          if (call AMSend.send(sender_ID, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
            locked = TRUE;
          }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}