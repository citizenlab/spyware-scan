# This file is licensed under CC-BY-SA-3.0.
# Modified from original post by Alex Reynolds on StackOverflow
# https://stackoverflow.com/questions/11490036/fast-alternative-to-grep-f

#!/usr/bin/env perl
use strict;
use warnings;
use IO::Handle;

STDOUT->autoflush(1);

# build hash table of keys
my $keyring;
open KEYS, "< sonar-ssl-hashes.txt";
while (<KEYS>) {
    chomp $_;
    $keyring->{$_} = 1;
}
close KEYS;

# look up key from each line of standard input
while (<STDIN>) {
    chomp $_;
    my ($ip, $hsh) = split(",", $_);
    if (defined $keyring->{$hsh}) { print "$_\n"; }
}
