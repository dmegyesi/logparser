#!/usr/bin/perl
package RouterLogParser;

use strict;
use warnings;

use POSIX qw(strftime);
use Time::Piece;
use Data::Dumper;
use Storable;
use Benchmark qw(:hireswallclock);

my $t0 = new Benchmark;

my $storeFile = $ARGV[0] || die "Usage: $0 <store.dat>\n";

my $data;

if (!-e $storeFile) { die "Store file doesn't exist: $storeFile\n"} 
else {
  $data = retrieve $storeFile;
}

#my $t_last = new Benchmark;

foreach my $mac (sort keys $data) {

  print "\t$mac: ", scalar keys $data->{$mac}, " records\n";
  my @timestamps = sort {$a <=> $b} @{$data->{$mac}};
  print "\t\tLast seen: $timestamps[-1]\n\n";

  #my $t_now = new Benchmark;
  #print "Processing took: ", timestr(timediff($t_now, $t_last)), "\n\n";
  #$t_last = $t_now;
}

my $t1 = new Benchmark;

print "Script execution took: ", timestr(timediff($t1, $t0)), "\n";
