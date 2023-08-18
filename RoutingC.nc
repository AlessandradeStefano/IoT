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
                interface Timer<TMilli> as Timer1;
        }
} implementation {

    //CONNECT
    void connect();
    //SUBSCRIBE
    void subscribe();
    //PUBLISH
    void publish();


    void connect() {

        //try and connect

        //if it does not work, retry
    }

    void subscribe() {

        //if it is not connected ignore

        //subscribe, id and topic
        //insert in the subscription list

        //if it is not successful retry
    }

    void publish() {

        //if it is not connected ignore

        //publish

        //send a message to all those that have subscribed to the topic
    }



}








};