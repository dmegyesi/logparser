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

my $dirname = $ARGV[0] || die "Usage: $0 <location of Maildir/new> [--dump]\n";

opendir(my $dh, $dirname) || die "Can't open directory: $dirname\n";
my @files = grep { /^\d.*/ } sort {$a cmp $b} readdir $dh;

my $dumpToFile = $ARGV[1] ? 1 : 0;
my $dumpName;

my $t_last = new Benchmark;

foreach (@files) {

  if ($dumpToFile && !(-e "$_.dat")) { $dumpName = $_; } # in case we asked to create a dump, check if it's already done
  elsif ($dumpToFile && (-e "$_.dat")) { next; } # dump already exists, skip this file
  elsif (!$dumpToFile) { $dumpName = undef; }

  open (my $fh, "<", "$dirname/$_") || die "I/O error: $!";
  print "> $_ opened\n";
  parse($fh, $dumpName);

  close $fh;

  my $t_now = new Benchmark;
  print "Processing took: ", timestr(timediff($t_now, $t_last)), "\n\n";
  $t_last = $t_now;

}

closedir $dh;

my $t1 = new Benchmark;

print "Script execution took: ", timestr(timediff($t1, $t0)), "\n";


#############################
# SUBROUTINES
#############################

sub parse {
  my ($fh, $dumpToFile) = @_;
  my $data;
  my $sentTime, my $wanIP;

  my $year = strftime "%Y", localtime;
  my %monthNames; @monthNames{qw /Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/} = (1..12);

  my $timePattern = '%Y %m %d %H:%M:%S';

  while (<$fh>) {

    chomp;

    # Line: # Time = 2014-02-19 21:12:32 3380638s
    if (/^#\sTime\s=\s(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}:\d{2})\s.*$/) {
      $sentTime = Time::Piece->strptime($1, "%Y-%m-%d %T");
    }

    # Line: # W1 = DHCP : W = 80.98.239.121 : M = 255.255.255.0 : G = 80.98.239.254
    if (/^#\sW1\s=\sDHCP\s:\sW\s=\s(.*)\s:\sM.*$/) {
      $wanIP = $1;
    }

    # Line: Feb 18 15:23:58  DHCP           NOTICE  DHCPS:Recv REQUEST from 18:67:B0:8A:02:F1
    if (/^.*(([A-Z][a-z]{2})\s(\d{1,2}))\s(\d{2}:\d{2}:\d{2})\s+DHCP\s+NOTICE\s+DHCPS.*from\s(([0-9A-F]{2}:){5}[0-9A-F]{2})\s*$/) { 
      my ($month, $day, $time, $macAddr) = ($2, $3, $4, $5);

      my $t = Time::Piece->strptime("$year $monthNames{$month} $day $time", $timePattern); 
      
      #print "Parsed: $macAddr -> ", $t->strftime("%F %T"), "\n";

      push @{$data->{$macAddr}}, $t;
    }
  }

  
  if ($data) {

    if ($dumpToFile) {

      my $filename = "$dumpName.dat";
      store {$sentTime, $wanIP, %$data}, $filename;
      print "Dump -> $filename\n";

    } else {

      print "Received: $sentTime from $wanIP\n";
      print "Found: ", scalar (keys $data), " MACs\n";

      foreach my $mac (sort keys $data) {
        print "\t$mac: ", scalar keys $data->{$mac}, " records\n";
        my @timestamps = sort values $data->{$mac};
        print "\t\tLast seen: $timestamps[-1]\n\n";
      }

    }

  }

  else {
    print "It was an inappropriate source file. :(\n";
  }
}


1;
