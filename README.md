# Advent of Code Solutions
[GreatGameGal](https://www.twitch.tv/greatgamegal)'s solutions to [Advent of Code 2023](https://adventofcode.com/2023).

## Build
Build with [Zig](https://ziglang.org/) using the following command.

To build the solutions for every day simply run the following.
```
$ zig build
```

To build a specific day you can run the following.
```
$ zig build -Dn=1
```

And the following is probably the best for building and running a specific day (setting the optimization level is optional but may be useful for something slow like Day 5 pt 2's Bruteforce Solution).
```
$ zig build -Dn=1 -Doptimize=ReleaseFast run -- inputs/01-input.txt
```
