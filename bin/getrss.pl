#!/usr/bin/perl -w

# jyunfan@gmail.com
# TODO
# 1. Error handling: write log when source is unavailable.

use warnings;
use strict;

use FindBin;
use lib $FindBin::Bin;

use LWP::Simple qw/get/;
use RssParser;

die "Usage: getrss feedlist\n" if $#ARGV < 0;

open SRC, $ARGV[0] or die $!;
my @srcs = <SRC>;

my %records = &ReadRecords($ARGV[0].".rec");

for my $src (@srcs) {
	chomp($src);
	$records{$src} = &Parse($src, get($src), $records{$src});
}

&WriteRecords($ARGV[0].".rec", %records);

sub Parse ($$$) {
	# latestitem := latest item output last time
	my ($src, $content, $latestitem) = @_;
	return "" if !defined($content);
	$latestitem = "" if !defined($latestitem);

	#open HANDLE, '>:utf8', '/tmp/RssAnalyzer.out';
	binmode STDOUT, ":utf8";

	my $rp = RssParser->new;
	$rp->parse($content);

	my $newest_item;
	for my $item (@{$rp->{items}}) {
		$item->{pubDate} = "" if (!exists($item->{pubDate}) || !defined($item->{pubDate}));
		#$rp->{channel}->{title} = "UNKNOWN" if (!exists($rp->{channel}->{title}));
		chomp(my $sig = $item->{pubDate} . " " . $item->{title});
		if (!defined($newest_item)) {
			$newest_item = $sig;
		}
		last if ($sig eq $latestitem);		# Skip seen items
		print "***SPLUNK*** source=$src\n" . $item->{'pubDate'} . "\n";
		for my $field (sort keys %{$item}) {
			# We skip the field 'pubDate' because Splunk will start a new event
			# when seeing data in date format. 
			next if $field eq 'pubDate';
			print $field . "=" . $item->{$field} . "\n" if (exists $item->{$field} && defined $item->{$field});
		}
	}
	#close HANDLE;
	return $newest_item;
}

sub ReadRecords($) {
	my ($filename) = @_;
	my %records = ();
	return %records if (! -e $filename);
	open RF, '<:utf8', $filename;
	while(<RF>) {
		my $rss_src = $_;
		chomp($rss_src);
		my $rss_latest = <RF>;
		chomp($rss_latest);
		$records{$rss_src} = $rss_latest;
	}
	return %records;
}

sub WriteRecords($%) {
	my ($filename, %records) = @_;
	return if !(open RF, '>:utf8', $filename);
	for my $key (keys %records) {
		print RF $key . "\n";
		print RF $records{$key} . "\n";
	}
}
