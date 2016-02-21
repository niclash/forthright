
#include "esp_common.h"
#include "esp_softap.h"

void wifi_init(void) {

    struct softap_config config;

    wifi_set_opmode(STATIONAP_MODE);
    wifi_softap_get_config(&config); // Get config first.

    memset(config.ssid, 0, 32);
    memset(config.password, 0, 64);
    memcpy(config.ssid, "Indoorio Beta", 13);
    memcpy(config.password, "12345678", 8);
    config.authmode = AUTH_WPA_WPA2_PSK;
    config.ssid_len = 0;// or its actual length
    config.max_connection = 4; // how many stations can connect to ESP8266 softAP at most.

    wifi_softap_set_config(&config);// Set ESP8266 softap config .
}
