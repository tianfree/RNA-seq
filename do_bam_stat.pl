#!/usr/bin/perl
use warnings;
use strict;
use 5.010;

if (@ARGV==0) {
print "./$0 hisat_report\n";
exit;
}

my ($all_PE, $uniquePE_C, $uniquePE_N, $multiPE, $all_SE, $uniqueSE, $multiSE, $mp_ratio) = (0) x 8;
my ($total_al, $total_mp, $total_ui) = (0) x 3;

my $name = $ARGV[0];
$name =~ s#.*_(.*)\.e\.txt#$1#;
$name =~ s#.*_(.*)\.err#$1#;

my $strand = "null";
my $mode = "normal";

open my $FILE , $ARGV[0] or die "Can't open mapping_report file.";
while(<$FILE>) {
if(/# reads processed/) { goto BOWTIE; last }
if(/(\w+) \(.*%\) were paired/) { $all_PE=$1*2 }
if(/(\w+) \(.*%\) aligned concordantly exactly 1 time/) { $uniquePE_C=$1*2 }
if(/(\w+) \(.*%\) aligned concordantly >1 times/) { $multiPE=$1*2 }
if(/(\w+) \(.*%\) aligned discordantly 1 time/) { $uniquePE_N=$1*2 }
if(/(\w+) \(.*%\) were unpaired/) { $all_SE=$1 }
if(/(\w+) \(.*%\) aligned exactly 1 time/) { $uniqueSE=$1 }
if(/(\w+) \(.*%\) aligned >1 times/) { $multiSE=$1 }
if(/(.*%) overall alignment rate/) { $mp_ratio=$1 }
}

$strand = "paired" if $all_PE !=0 && $all_SE ==0;
$strand = "single" if $all_PE ==0 && $all_SE !=0;
$strand = "mix" if $all_PE !=0 && $all_SE !=0;

$total_al = $all_PE+$all_SE;
$total_mp = ($uniquePE_C+$multiPE+$uniquePE_N+$uniqueSE+$multiSE);
$total_ui = ($uniquePE_C+$uniquePE_N+$uniqueSE);

if($mode ne "normal") {
BOWTIE:
	#close $FILE;
	print STDERR "bowtie mode\n";
	open $FILE , $ARGV[0] or die "Can't open mapping_report file.";
	while(<$FILE>) {
	if(/# reads processed: (\w+)/) { $total_al=$1 }
	if(/at least one reported alignment: (\w+) \((.*%)\)/) { $total_mp=$1; $mp_ratio=$2 }
	$total_ui = 0;
	$strand = "single";
	}
}

if($total_al==0) {
print "$name\t$total_al\t0\t0\t0\tNA\tNA\t$strand\n";
exit;
}

my $mp_ratio_recal = $total_mp / $total_al * 100;
my $ui_ratio_recal = $total_ui / $total_al * 100;
print "$name\t$total_al\t$total_mp\t$total_ui\t$mp_ratio\t";

printf "%.2f%%\t%.2f%%\t%s\n",$mp_ratio_recal,$ui_ratio_recal,$strand;

