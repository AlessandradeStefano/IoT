#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

typedef nx_struct radio_count_msg {
  nx_uint8_t messageType;
    nx_uint16_t sender_ID;
    nx_uint16_t destination;
    nx_uint8_t topic;
    nx_uit8_t payload;
} radio_count_msg_t;

    /*
    CONNECT = 0
    CONNACK = 1
    SUBSCRIBE = 2
    SUBACK = 3
    PUBLISH = 4
    ACK = 5
    */

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
