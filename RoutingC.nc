#include "RoutingAppC.h"

module RoutingC {

        uses {
                /* INTERFACES */
                interface Boot;

                interface SplitControl as AMControl;
                interface Packet;
                interface AMSend;
                interface Receive;

                interface Timer<TMilli> as Timer0;

        }
} implementation {

    //CONNECT
    void connect(uint8_t id);
    //SUBSCRIBE
    void subscribe(uint8_t id, uint8_t topic);
    //PUBLISH
    void publish(uint8_t id, uint8_t topic);

    nx_uint16_t subscriptions[NUM_TOPICS][MAX_SUBS];

    // Implementation for sending the command
    event void Boot.booted() {
        dbg("boot","Application booted.\n");
        call AMControl.start();
    }

    // Event handler for command reception
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {

        action_message* pkt = (action_message*)payload;

        if(pkt->messageType == CONNECT){
            connect(pkt->sender_ID);
        } else if (pkt->messageType == SUBSCRIBE){
            subscribe(pkt->sender_ID, pkt->topic);
        } else {
            publish(pkt->sender_ID, pkt->topic);

    }

    void connect(uint8_t id) {

        //try and connect
        action_message reply;
        reply.nodeId = id;
        printf("Coordinator sending association response...\n");
        call AMSend.send(id, &reply, sizeof(action_message));
        //if it does not work, retry
    }

    void subscribe(uint8_t id, uint8_t topic) {

        //if it is not connected ignore

        //subscribe, id and topic
        //insert in the subscription list
        subscriptions[topic][id] = 1;

        //if it is not successful retry
    }

    void publish(uint8_t id, uint8_t topic) {

        //if it is not connected ignore

        //publish

        //una send dal nodo al coordinator e poi per ogni
        //nodo iscritto al topic il coordinator fa una send

        //send a message to all those that have subscribed to the topic
    }



}








};