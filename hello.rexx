#!/usr/bin/rexx
say "Hello! What is your name?"
parse pull who
if who = "" then say "Hello stranger!"
else say "Hello" who
