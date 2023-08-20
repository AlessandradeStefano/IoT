#ifndef ROUTING_H
#define ROUTING_H

#define NUM_TOPICS 3
#define MAX_SUBS 8
typedef nx_struct action_message{
    nx_uint8_t messageType;
    nx_uint16_t sender_ID;
    nx_uint16_t destination;
    nx_uint8_t topic;
    nx_uit8_t payload;
} action_message;

//topics
#define TEMPERATURE 1
#define HUMIDITY 2
#define LUMINOSITY 3


// Message types
enum {
    CONNECT,
    CONNACK,
    SUBSCRIBE,
    SUBACK,
    PUBLISH,
    ACK
};

#endif