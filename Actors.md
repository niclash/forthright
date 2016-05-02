# Actors in Forthright

Actors is a borrowed concept from Erlang, to provide a multitasking model
that is not susceptible to the problems related with multi-threaded re-entrant
code.

For Forth language itself, I would like to introduce namespace separation as
well. From the main program, first load all shared words, then the different
actor subsystems. Each of those actor subsystems link their dictionary to
the main dictionary, but no other actor, nor the main shell itself will
see the dictionary of each other actor. This will greatly help in namespace
separation, without relying on word redefinitions, that are sometimes
practiced to reduce word lengths.

Actors are independent lightweight processes that shares no memory with other
processes. They must be lightweight enough to be very cheap to both create
and keep running.


## Proposed Words for Actor library

s" myownactor.f" ACTORLIB   -  creates a new dictionary segment and loads all
                               the definitions from the named file.

SPAWN                       -  spawns a new actor process (i.e. stacks and data
                               segment) Places the actor reference
                               on the stack, which can be stored to a VARIABLE.

A<                          -  Start of message to send to an actor. All messages
                               are character streams, which are fed to the actor's
                               KEY word.

>                           -  End of message to send to an actor. Since ">" is a
                               valid word (e.g greater than), any use of ">" needs
                               escaping (how?).

A!                          -  Sends message created to actor.

RSPAWN                      -  Remote SPAWN. Spawns an actor over the network (how?)

SELF                        -  Actor reference to current actor.

## Discussion
### Why send text?
Sending messages in clear text and feeding the message to the KEY word, means that very little
(perhaps none) new parsing is required to be defined and added. The flexibility is enormous,
and the "only" drawback is performance. However, performance can be greatly improved by
keeping messages very small, running pre-defined words on the actor.

It also makes interactivity with the actor a bit easier, IF we connect the EMIT output of
actors back to the EMIT output of its supervisor (i.e. the actor (or the shell) starting
the actor)

### Should definitions be allowed in actor messages?
By allowing definitions (:) maximum flexibility is maintained. But the memory space becomes
more complex. Each actor library has its own dictionary, but each actor has its own data segment,
so if definitions are sent to an actor, they will consume the data segment of the actor, the
actor lib will not get additional definitions added. This means that when the actor stops/crashes
those definitions are lost. This is perhaps a good feature, and the supervisor of the
actor will be responsible to redefine it.


## Example 1 - Ping Pong

include actors.f
." ping.f" ACTORLIB
." pong.f" ACTORLIB



