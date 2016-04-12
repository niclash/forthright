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

/** Forthright's bootstrapper to leverage the TCP/IP, Serial port and possibly other
* system resources that is provided by the ESP IoT SDK.
*
* This bootstrapper is kept to an absolute minimum for now.
*/

#include "forthright.h"
#include "stdio.h"

static system_t system;

static char data_stack[DATA_STACK_SIZE];
static char return_stack[RETURN_STACK_SIZE];
static char input_buffer[INPUT_BUFFER_SIZE];
static char data_segment[DATA_SEGMENT_SIZE];
static char word_buffer[MAX_WORD_SIZE];

void forthright()
{
    system.data_segment = data_segment;
    system.data_segment_size = DATA_SEGMENT_SIZE;

    system.data_stack = data_stack;
    system.data_stack_size = DATA_STACK_SIZE;

    system.return_stack = return_stack;
    system.return_stack_size = RETURN_STACK_SIZE;

    system.input_buffer = input_buffer;
    system.input_buffer_size = INPUT_BUFFER_SIZE;

    system.word_buffer = word_buffer;
    system.word_buffer_size = MAX_WORD_SIZE;

    forthright_start( &system );
}
