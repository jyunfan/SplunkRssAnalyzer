#!/usr/bin/perl

package RssParser;

use 5.008;
use strict;
use warnings;
use XML::Parser;

sub new { 
	my $class = shift;

	my $parser = new XML::Parser;
	my $self = {
		parser	=> $parser,
		depth	=> 0,
		channel	=> {},
		items	=> [],
		latest	=> {},
	};

	$self->{parser}->setHandlers(
		Final	=> sub { shift; $self->final(@_) },
		Start	=> sub { shift; $self->start(@_) },
		End		=> sub { shift; $self->end(@_) },
		Char	=> sub { shift; $self->char(@_) },
	);

	bless($self, $class);
	return $self;
}

sub parse {
	my ($self, $xml) = @_;
	
	$self->{parser}->parse($xml);
}

sub final { 
	my $self = shift; 

	$self->{parser}->setHandlers(Final => undef, Start => undef, End => undef, Char => undef);
}

sub start ($$) {
	my ($self, $tag) = @_;

	$self->{depth}++;	
	$self->{tag} = $tag;
	# Create a new hash when we encounter a 'item' tag
	if (($self->{depth}==3) && ($tag eq 'item')) {
		$self->{latest} = {};
	} elsif (($self->{depth}==4) && (exists($self->{latest}->{$tag}))) {
		# Handle multiple tags with the same name in <item>
		$self->{latest}->{$tag} .= '#';
	}
}

sub char ($$) {
	my ($self, $text) = @_;
	return if (!defined($text)) or (!defined($self->{tag}));

	if ($self->{depth}==3) {
		$self->{channel}->{$self->{tag}} .= $text;
	} elsif ($self->{depth}==4) {
		$self->{latest}->{$self->{tag}} .= $text;
	}
}

sub end ($$) { 
	my ($self, $tag) = @_;
	if ($self->{depth}==3 && ($tag eq 'item')) {
		push (@{$self->{items}}, $self->{latest});
		undef $self->{latest};
	}
	undef $self->{tag};
	$self->{depth}--;
}

1;
__END__


# This module is based on Erik Bosrup's module, XML::RSS::Parser::Lite.
# Jyun-Fan Tsai<jyunfan@gmail.com>
