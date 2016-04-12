
\  Copyright 2016 Niclas Hedhman, All rights reserved.
\
\  Licensed under the Apache License, Version 2.0 (the "License");
\  you may not use this file except in compliance with the License.
\  You may obtain a copy of the License at
\
\      http://www.apache.org/licenses/LICENSE-2.0
\
\  Unless required by applicable law or agreed to in writing, software
\  distributed under the License is distributed on an "AS IS" BASIS,
\  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
\  See the License for the specific language governing permissions and
\  limitations under the License.
\

hex

60000600	constant PERIPHS_TIMER_BASEDDR

60000600	constant FRC1_LOAD_ADDRESS
007FFFFF	constant TIMER_FRC1_LOAD_VALUE
0		constant TIMER_FRC1_LOAD_VALUE_S
22		constant FRC1_LOAD_DATA_MSB
0		constant FRC1_LOAD_DATA_LSB
007fffff	constant FRC1_LOAD_DATA_MASK

60000604	constant FRC1_COUNT_ADDRESS
007fffff	constant TIMER_FRC1_COUNT
0		constant TIMER_FRC1_COUNT_S
22		constant FRC1_COUNT_DATA_MSB
0		constant FRC1_COUNT_DATA_LSB
007fffff	constant FRC1_COUNT_DATA_MASK

60000608	constant FRC1_CTRL_ADDRESS
100		constant TIMER_FRC1_INT
FF		constant TIMER_FRC1_CTRL
0		constant TIMER_FRC1_CTRL_S
7		constant FRC1_CTRL_DATA_MSB
0		constant FRC1_CTRL_DATA_LSB
FF		constant FRC1_CTRL_DATA_MASK

6000060C	constant FRC1_INT_ADDRESS
1		constant TIMER_FRC1_INT_CLR_MASK
0		constant FRC1_INT_CLR_MSB
0		constant FRC1_INT_CLR_LSB
1		constant FRC1_INT_CLR_MASK

60000620	constant FRC2_LOAD_ADDRESS
FFFFFFFF	constant TIMER_FRC2_LOAD_VALUE
0		constant TIMER_FRC2_LOAD_VALUE_S
31		constant FRC2_LOAD_DATA_MSB
0		constant FRC2_LOAD_DATA_LSB
ffffffff	constant FRC2_LOAD_DATA_MASK

60000624	constant FRC2_COUNT_ADDRESS
FFFFFFFF	constant TIMER_FRC2_COUNT
0		constant TIMER_FRC2_COUNT_S
31		constant FRC2_COUNT_DATA_MSB
0		constant FRC2_COUNT_DATA_LSB
ffffffff	constant FRC2_COUNT_DATA_MASK

60000628	constant FRC2_CTRL_ADDRESS
100		constant TIMER_FRC2_INT
000000FF	constant TIMER_FRC2_CTRL
0		constant TIMER_FRC2_CTRL_S
7		constant FRC2_CTRL_DATA_MSB
0		constant FRC2_CTRL_DATA_LSB
000000ff	constant FRC2_CTRL_DATA_MASK

6000062C	constant FRC2_INT_ADDRESS
1		constant TIMER_FRC2_INT_CLR_MASK
0		constant FRC2_INT_CLR_MSB
0		constant FRC2_INT_CLR_LSB
00000001	constant FRC2_INT_CLR_MASK

60000630	constant FRC2_ALARM_ADDRESS
FFFFFFFF	constant TIMER_FRC2_ALARM
0		constant TIMER_FRC2_ALARM_S
31		constant FRC2_ALARM_DATA_MSB
0		constant FRC2_ALARM_DATA_LSB
ffffffff	constant FRC2_ALARM_DATA_MASK

decimal
