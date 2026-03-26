#!/usr/bin/perl -w
#
# check_mem.pl - Nagios plugin to check memory usage on Linux
#
# Usage: check_mem.pl -w <warn%> -c <crit%> [-f] [-C]
#   -f : check free memory instead of used
#   -C : count cache as free
#

use strict;
use Getopt::Long;

my $warn = 90;
my $crit = 95;
my $free = 0;
my $cache_as_free = 0;
my $help = 0;

GetOptions(
    'w=i' => \$warn,
    'c=i' => \$crit,
    'f'   => \$free,
    'C'   => \$cache_as_free,
    'h'   => \$help,
);

if ($help) {
    print "Usage: check_mem.pl -w <warn%> -c <crit%> [-f] [-C]\n";
    print "  -w  Warning threshold (default 90)\n";
    print "  -c  Critical threshold (default 95)\n";
    print "  -f  Check free memory instead of used\n";
    print "  -C  Count cache as free\n";
    exit 3;
}

open(my $fh, '<', '/proc/meminfo') or die "Cannot open /proc/meminfo: $!";
my %mem;
while (<$fh>) {
    if (/^(\S+):\s+(\d+)/) {
        $mem{$1} = $2;
    }
}
close($fh);

my $total   = $mem{MemTotal}   || 0;
my $memfree = $mem{MemFree}    || 0;
my $buffers = $mem{Buffers}    || 0;
my $cached  = $mem{Cached}     || 0;

if ($total == 0) {
    print "UNKNOWN - Cannot read memory info\n";
    exit 3;
}

my $used;
if ($cache_as_free) {
    $used = $total - $memfree - $buffers - $cached;
} else {
    $used = $total - $memfree;
}

my $pct_used = int(($used / $total) * 100);
my $pct_free = 100 - $pct_used;

my $check_value = $free ? $pct_free : $pct_used;
my $check_label = $free ? 'free' : 'used';

my $total_mb = int($total / 1024);
my $used_mb  = int($used / 1024);
my $free_mb  = int(($total - $used) / 1024);

my $perfdata = "mem_used=${used_mb}MB;" . int($total_mb * $warn / 100) . ";" . int($total_mb * $crit / 100) . ";0;${total_mb}";

my $output = "Memory $check_label: ${check_value}% (Used: ${used_mb}MB / Total: ${total_mb}MB / Free: ${free_mb}MB) | $perfdata";

if ($free) {
    if ($check_value <= $crit) {
        print "CRITICAL - $output\n";
        exit 2;
    } elsif ($check_value <= $warn) {
        print "WARNING - $output\n";
        exit 1;
    } else {
        print "OK - $output\n";
        exit 0;
    }
} else {
    if ($check_value >= $crit) {
        print "CRITICAL - $output\n";
        exit 2;
    } elsif ($check_value >= $warn) {
        print "WARNING - $output\n";
        exit 1;
    } else {
        print "OK - $output\n";
        exit 0;
    }
}
