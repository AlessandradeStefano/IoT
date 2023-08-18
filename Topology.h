#ifndef TOPOLOGY_H
#define TOPOLOGY_H

#define NUM_TOPICS 3
#define MAX_SUBS 8
typedef nx_struct Message{
    nx_uint8_t messageType;
    nx_uint16_t sender_ID;
    nx_uint16_t destination;
    nx_uint8_t status; //???????
    nx_uit8_t payload;
} Message;

//topics
#define TEMPERATURE 1
#define HUMIDITY 2
#define LUMINOSITY 3

// Subscription information
typedef nx_struct Subscription {
        nx_uint8_t topic;
        nx_uint8_t subscriberID;
        nx_uint8_t receiver //serve?
}Subscription;

Subscription subscriptions[NUM_TOPICS][MAX_SUBS];
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