#include "Timer.h"
#include "RadioCountToLeds.h"

module RadioCountToLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer0;
    interface Timer<TMilli> as MilliTimer1;
    // interface Timer<TMilli> as MilliTimer2;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint8_t connected[9] = {0,0,0,0,0,0,0,0,0};
  
  void sendCONNACK(uint16_t sender_ID);
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      uint8_t id = TOS_NODE_ID;
      printf("id: %d \n", id);
      printfflush();
      call MilliTimer0.startOneShot(1000);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  // Fired after first boot, start CONNECT procedure
  event void MilliTimer0.fired() {
    if (locked) {
      return;
    }
    else {
      // if worker node, send CONNECT message to PANC 
      if (TOS_NODE_ID != 0){
        radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
        if (rcm == NULL) return;

        rcm->sender_ID = TOS_NODE_ID;
        rcm->messageType = 0;
        rcm->destination = 0;

        if (call AMSend.send(0, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
          locked = TRUE;
        }
      }

      call MilliTimer1.startOneShot(10000); // connection timeout
    }
  }

  event void MilliTimer1.fired() {
    if (locked) {
      return;
    }
    else {
      if (TOS_NODE_ID != 1){
        if (connected[TOS_NODE_ID-1] != 2) call MilliTimer0.startOneShot(1000); // try reconnect
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm_r = (radio_count_msg_t*)payload;
      /** PANC **/
      if (TOS_NODE_ID == 1){
        if (rcm_r->messageType == 0) { // if receive CONNECT
          uint16_t sender = rcm_r->sender_ID;
          connected[sender-1] = 1;
          sendCONNACK(sender);
        }

      /** WORKER **/
      } else {
        if ((rcm_r->messageType == 1) && (connected[TOS_NODE_ID-1] = 1)) { // if receive CONNACK 
          connected[TOS_NODE_ID-1] = 2;
          call Leds.led0Toggle();
        }
        
      }
     
    }
    return bufPtr;
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  void sendCONNACK(uint16_t sender_ID){
          radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
          if (rcm == NULL) return;

          rcm->sender_ID = TOS_NODE_ID;
          rcm->messageType = 1;
          rcm->destination = sender_ID;

          if (call AMSend.send(sender_ID, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
            locked = TRUE;
          }
  }

}
