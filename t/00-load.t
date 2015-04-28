#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('JIP::LockFile') || print "Bail out!\n";
}

diag("Testing JIP::LockFile $JIP::LockFile::VERSION, Perl $], $^X");

