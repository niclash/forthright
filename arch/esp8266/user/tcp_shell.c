/*
 *  Copyright 2016 Niclas Hedhman, All rights reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "esp_common.h"
#include "espconn.h"
#include "tcp_shell.h"

#include "ets_sys.h"
#include "os_type.h"
#include "osapi.h"
#include "mem.h"
#include "lwip/stats.h"


#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

LOCAL uint16_t shell_timeout = 3600; // 1 hour timeout

LOCAL struct espconn masterconn;
LOCAL struct espconn *pespconn;

LOCAL int is_connected = 0;
LOCAL xQueueHandle tcp_shell_stdin;
LOCAL char *stdout_buffer;
LOCAL int stdout_pointer;

LOCAL void ICACHE_FLASH_ATTR debugstr( const char* fmt, char* buffer, int bufsize ) {
    char tmp[bufsize+1];
    memcpy( tmp, buffer, bufsize);
    tmp[bufsize] = 0;
    printf(fmt, tmp);
}

int ICACHE_FLASH_ATTR tcp_shell_is_connected() {
    return is_connected;
}

int ICACHE_FLASH_ATTR tcp_shell_read_chars( char* buffer, int bufsize ) {

    char ch;
    int count = 0;
    while( xQueueReceive( tcp_shell_stdin, &ch, 10 ) == pdTRUE ) {
        buffer[count++] = ch;
    }
    if( count > 0 ){
        debugstr("[Shell] read %s\n", buffer, count);
    }
    if( pespconn->state == ESPCONN_CLOSE ) {
        is_connected = false;
    }
    return count;
}

void ICACHE_FLASH_ATTR tcp_shell_put_char(char ch) {
    printf("[Shell] send %c\n", ch);
    stdout_buffer[stdout_pointer++] = ch;
    if( stdout_pointer > MAX_PACKET_SIZE || ch == '\n' ) {
        espconn_send(pespconn, stdout_buffer, stdout_pointer);
        stdout_pointer = 0;
    }
}

void ICACHE_FLASH_ATTR tcp_shell_put_chars(char* buffer, int bufsize) {
    int i;
    debugstr("[Shell] send %s\n", buffer, bufsize);
    for( i=0; i < bufsize; i++ ) {
        tcp_shell_put_char(buffer[i]);
    }
}

LOCAL void ICACHE_FLASH_ATTR disconnected(void *arg) {
    pespconn = (struct espconn *) arg;
    is_connected = FALSE;
    printf("[Shell] disconnected\n");
}

LOCAL void send_to_stdin(char* data, int length){
    int i;
    debugstr("[Shell] to stdin: %s\n", data, length);
    for( i=0; i < length; i++ ) {
        if( xQueueSend( tcp_shell_stdin, (void *) &data[i], ( portTickType ) 10 ) != pdPASS ) {
            // Failed to post the message, even after timeout
            // what to do?
        }
    }
}

LOCAL void ICACHE_FLASH_ATTR received(void *arg, char *pusrdata, unsigned short length)
{
    pespconn = (struct espconn *) arg;
    send_to_stdin(pusrdata, length);
}

LOCAL void ICACHE_FLASH_ATTR sent( void* arg ){
    printf("[Shell] data sent\n");
}

LOCAL void ICACHE_FLASH_ATTR write_finished(void *arg) {
    printf("[Shell] write finished\n");
}

LOCAL void ICACHE_FLASH_ATTR connected(void *arg)
{
    pespconn = (struct espconn *)arg;

    printf("[Shell] connection established\n");
    espconn_regist_recvcb(pespconn, received);
    espconn_regist_disconcb(pespconn, disconnected);
    espconn_regist_sentcb( pespconn, sent );
    espconn_regist_write_finish( pespconn, write_finished );
    is_connected = TRUE;
    send_to_stdin("WELCOME\n", 8);
}

void ICACHE_FLASH_ATTR tcp_shell_init(void)
{
    tcp_shell_stdin = xQueueCreate( 128, sizeof( char) );
    stdout_buffer = (char *) os_zalloc(MAX_PACKET_SIZE);
    stdout_pointer = 0;

    masterconn.type = ESPCONN_TCP;
    masterconn.state = ESPCONN_NONE;
    masterconn.proto.tcp = (esp_tcp *)os_zalloc(sizeof(esp_tcp));
    masterconn.proto.tcp->local_port = FORTH_TCP_PORT;
    espconn_regist_connectcb(&masterconn, connected);
    espconn_regist_disconcb(&masterconn, disconnected);
    espconn_accept(&masterconn);
    espconn_regist_time(&masterconn, shell_timeout, 0);

    printf("[Shell] [%s] initialized!\n", __func__);
}

