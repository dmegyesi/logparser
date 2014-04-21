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

my $dirname = $ARGV[0] || die "Usage: $0 <location of datadir/> [store.dat]\n";

opendir(my $dh, $dirname) || die "Can't open directory: $dirname\n";
my @files = grep { /^\d.*/ } sort {$a cmp $b} readdir $dh;

my $storeFile = $ARGV[1] ? $ARGV[1] : "store.dat";
my $bigStorage;


if (!-e $storeFile) { push @{$bigStorage->{""}}, [""]; }
else {
  $bigStorage = retrieve $storeFile;
}

delete $bigStorage->{""}; # only needed to create the hashref

my $t_last = new Benchmark;

foreach (@files) {

  print ">$_\n";
  readDump("$dirname/$_", $bigStorage);

  my $t_now = new Benchmark;
  print "Processing took: ", timestr(timediff($t_now, $t_last)), "\n\n";
  $t_last = $t_now;

}

closedir $dh;


store {%$bigStorage}, $storeFile;
print "Store written: $storeFile\n";

my $t1 = new Benchmark;

print "Script execution took: ", timestr(timediff($t1, $t0)), "\n";



#############################
# SUBROUTINES
#############################

sub readDump {
  my ($filename, $bigStorage) = @_;
  my $data;
  $data = retrieve $filename;

  for my $x (keys($data)) {
    for my $y (keys($data->{$x})) {
      push @{$bigStorage->{$x}}, @{$data->{$x}};
    }
  }

  for my $key (keys $bigStorage) {
    print "$key -> ", scalar keys $bigStorage->{$key}, " records\n";
  }
}

