# Lightweight Publish-Subscribe Application Protocol
The project aims to design a lightweight publish-subscribe application and deploy it, with a simulator, in a star-shaped network topology. \
TinyOS is the platform used to implement the sensor’s logic, basic components and interfaces were used to implement a fully functional application, where Timers played a fundamental role in making the system work properly. \
In order to test and evaluate the application, Cooja has been used to simulate a sensor system, exploiting motes’ output prints to verify the correctness of the developed project. \
In order to make the system communicate with the external world, we connected the PAN (Personal Area Network) Coordinator with Node-Red through a TCP socket, and successively transmitted data to the ThingSpeak visualization service using the MQTT communication protocol. 
\
\
In the ``docs`` folder, a detailed report is available.
\
\
[Thingspeak Channel](https://thingspeak.com/channels/2250515)
