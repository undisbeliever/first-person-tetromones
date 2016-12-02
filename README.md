First Person Tetromones
=======================

Feburary's entry into the 1 Game Per Month Challange.

This represents a Super Nintendo port of [First Person Tetris](http://firstpersontetris.com), using Mode 7 rotations to represent the game field.

<img src="screenshot.png?raw=true" alt="Person Tetromones Screenshot" width="512" height="448">

Controls
========
 * *D-Pad* - Move
 * *B* *R* - Rotate clockwise
 * *Y* *L* - Rotate counter-clockwise
 * *A* - Insant drop
 * *X* - Hold Piece


Debug Testing Mode
==================
If you hold *Select* when starting the game you enter debug testing mode.

This mode will test the random number generator by randomly selecting the next piece once per frame, stopping when one piece has been chosen 999 times.

Other tests include:

 * Level Colours: Pressing *Select* will increase the level counter by one and update the palette.
 * Rotation: Pressing the rotation buttons will increase the .


Build Requirements
===================
 * ca65
 * pcx2snes
 * gnu Make
 * python3
 * ucon64

