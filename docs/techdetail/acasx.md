ACAS X Introduction
===================

ACAS X is the next generation collision avoidance system, slated to take over from TCAS II. Currently, it matches TCAS II performance levels, offering vertical collision avoidance primarily using Mode S. Longer term, it is intended to also provide '3D' collision avoidance, i.e. by adding horizontal and more complex maneuvres. It is also intended to cope with more complex maneuverings in traffic-heavy areas, and eventually integration of UAS.

## Collision Avoidance Concepts

This is only meant to be a high level view - you should read up on ACAS before diving into this project.

Say we have two aircraft flying on a collision course - ACAS intends to avoid these aircraft becoming too close to each other by automatically intervening.

1. First, each aircraft will listen to nearby Mode S transmissions to figure out which aircraft are nearby, and estimate their range. It may also use ADS-B information as additional context.
2. As the aircraft approach and the range falls below the active surveillance threshold (around 10 NM), each aircraft will start to issue its own Mode S interrogations to the other aircraft. This will be used to update the range.
3. If the aircraft continue to get close, a Traffic Advisory (TA) will be issued. This tells the pilots of each aircraft that traffic is nearby and they may soon receive further alerts.
4. Should the aircraft continue to get closer, they may eventually be considered a collision risk. At this point, the ACAS systems on each aircraft will communicate using UF16UDS30 messages over Mode S, to coordinate how each will respond. This ensures that the aircraft actually move away from each other. 
5. When responses are decided (this takes a fraction of a second typically), the flight crew on each aircraft will be issued with a Resolution Advisory (RA), including instructions about whether to climb, descend, stay level or hold their existing vertical speed. This *must* be followed immediately, and is expected to be followed within five seconds.
6. In the meantime, the ACAS boxes continue to communicate and may need to issue further RAs if one or both of the aircraft are not separating quickly enough.

You can find some more detail on this in the TCAS manual below.

## Some Differences to TCAS II

* Avoiding actions are selected using a cost-table lookup rather than the rules-based TCAS. These cost tables are produced through an optimisation process and supplied with the DO-385 standard.
* ACAS provides a reference implementation in Julia, compared to the pseudocode provided for TCAS
* The system is heavily modularised and intended to be plug-and-play - each surveillance input is meant to be swappable.

## Useful Links
* [TCAS II Handbook](https://www.faa.gov/documentlibrary/media/advisory_circular/tcas%20ii%20v7.1%20intro%20booklet.pdf)
* [ACAS X CONOPS](https://skybrary.aero/bookshelf/books/2551.pdf)
* [ACAS Eurocontrol Guide](https://www.skybrary.aero/bookshelf/books/106.pdf)
* [ACAS X Skybrary](https://www.skybrary.aero/index.php/ACAS_X)

## Useful Standards
* DO-185 - TCAS
* DO-385 - ACAS X
* [ACAS Manual (ICAO)](https://www.icao.int/Meetings/anconf12/Document%20Archive/9863_cons_en.pdf)


