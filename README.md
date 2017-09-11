shnake (bash-snake)
===================

A simple bash-based implementation of the popular _Snake_ game I made while trying to learn bash.

Let the snake (the green line) eat as many apples (the red "X"s) it can without crashing into its own tail or into a wall (if present).

Launch with the `-h` option (with no argument) to get a quick help and exit.

Controls
--------

| Key | Function |
| --- | --- |
| Arrow keys / WASD | Move (i.e. change snake direction) |
| P | Pause |
| Q | Quit |

Customizing the game
--------------------

By default, the game area is sized after the terminal you are using. Use the `-w` and `-h` options to manually set the size.

    # play in a 20x10 area
    ./shnake.sh -w 20 -h 10

The default speed is 10 steps per second. Use the `-s` option to set the steps per second or the `-d` options to set the seconds per step.

    # play at 20 steps per seconds
    ./shnake.sh -s 20     # or
    ./shnake.sh -d 0.05

By default, the game area border is a wall. Use the `-o` option to let the snake jump instead to the other side.

Use `-t N` to make _N_ the initial length of the snake tail or `-i` to let it grow infinitely.
