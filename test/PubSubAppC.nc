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
    interface Timer<TMilli> as MilliTimer3;
    interface Timer<TMilli> as MilliTimer4;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;
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

  uint8_t SUB_TOPIC; // TOS_NODE_ID % 3
  uint8_t PUB_TOPIC; // TOS_NODE_ID-1 % 3
  uint8_t NUM_NODES = 8;

  uint8_t random;
  
  void sendACK(uint16_t sender_ID, uint8_t type);
  void sendCON();
  void sendSUB(uint8_t topic);
  void sendPUB(uint8_t topic, uint8_t payload, uint16_t destination);
  
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
      SUB_TOPIC = TOS_NODE_ID % 3;
      if (second_sub && (SUB_TOPIC == 0)) SUB_TOPIC = 1; // if subscribed to TEMPERATURE, subscribe also to HUMIDITY
      sendSUB(SUB_TOPIC);

      call MilliTimer3.startOneShot(10000); // subscribe timeout
    }
  }

  // start PUBLISH procedure
  event void MilliTimer4.fired() {
    if (locked) {
      return;
    }
    else {
      PUB_TOPIC = (TOS_NODE_ID-1) % 3;
      random = (call Random.rand16() % 100);
      sendPUB(PUB_TOPIC, random, 1);
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
        SUB_TOPIC = TOS_NODE_ID % 3;
        if (sub == FALSE) call MilliTimer2.startOneShot(1000); // try reconnection
        else if ((SUB_TOPIC == 0) && second_sub == FALSE) {
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
          sendACK(sender, 3);
        } else if (rcm_r->messageType == 4 && connected[sender-1]) { // receive PUBLISH
          int i;
          for (i = 0; i < NUM_NODES; i++){
            if ((rcm_r->topic == 0) && temperature[i] == 1) sendPUB(rcm_r->topic, rcm_r->payload, i+2);
            if ((rcm_r->topic == 1) && humidity[i] == 1) sendPUB(rcm_r->topic, rcm_r->payload, i+2);
            if ((rcm_r->topic == 2) && luminosity[i] == 1) sendPUB(rcm_r->topic, rcm_r->payload, i+2);
          }
        }

      }


      /** WORKER **/
      else {
        if (rcm_r->messageType == 1) { // receive CONNACK 
          connected[TOS_NODE_ID-1] = 1;
          
          printf("node connected\n");
       	  printfflush();
       	  
          call Leds.led1On();

          // subscribe to a topic
          call MilliTimer2.startOneShot(10000);

        } else if (rcm_r->messageType == 3) { // receive SUBACK 
          sub = TRUE;

          printf("node subscribed\n");
       	  printfflush();

          call Leds.led2On();

          // periodically publish to a topic
          call MilliTimer4.startPeriodic(20000);
        } else if (rcm_r->messageType == 4) { // receive PUBLISH

          printf("received PUB (topic: %d)", rcm_r->topic);
       	  printfflush();
          
          call Leds.led0On();
          call Leds.led0Off();
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

  void sendACK(uint16_t destination, uint8_t type){
          radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
          if (rcm == NULL) return;

          rcm->sender_ID = TOS_NODE_ID;
          rcm->messageType = type;
          rcm->destination = destination;
          
          printf("sending ACK (%d)\n", type);
       	  printfflush();

          if (call AMSend.send(destination, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
            locked = TRUE;
          }
  }

  void sendPUB(uint8_t topic, uint8_t payload, uint16_t destination){
          radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
          if (rcm == NULL) return;

          rcm->messageType = 4;
          rcm->sender_ID = TOS_NODE_ID;
          rcm->destination = destination;
          rcm->topic = topic;
          rcm->payload = payload;
          
          printf("sending PUB (topic: %d)\n", topic);
       	  printfflush();

          if (call AMSend.send(destination, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
            locked = TRUE;
          }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}