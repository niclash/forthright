
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

12345 CONSTANT PORTA

12345 CONSTANT PORTB

12345 CONSTANT PORTC

12345 CONSTANT PORTD

12345 CONSTANT PORTE

12345 CONSTANT PORTF

: GPIO0 ( - -- bvalue ) 1 PORTA @ AND ;
: GPIO1 ( - -- bvalue ) 2 PORTA @ AND 1 R ;
