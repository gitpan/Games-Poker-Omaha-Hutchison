package Games::Poker::Omaha::Hutchison;

our $VERSION = '1.01';

use strict;
use warnings;

use List::Util 'sum';

use Class::Struct 'Games::Poker::Omaha::Hutchison::Card' =>
	[ suit => '$', pips => '$' ];

sub Games::Poker::Omaha::Hutchison::Card::rank {
	return (qw/ 0 0 l l l l x h h h c c c c a /)[ shift->pips ];
}

sub new {
	my $class  = shift;
	my @cardes = @_ > 1 ? @_ : split / /, +shift || die "Need a hand";
	my @cards  = map [ split // ], @cardes;
	my %remap  = (A => 14, K => 13, Q => 12, J => 11, T => 10);
	$_->[0] = $remap{ $_->[0] } || $_->[0] foreach @cards;
	bless {
		cards => [
			map Games::Poker::Omaha::Hutchison::Card->new(
				pips => $_->[0],
				suit => lc $_->[1]
			),
			@cards
		]
	} => $class;
}

sub cards { @{ shift->{cards} } }

sub by_suit {
	my $self = shift;
	my %suited;
	push @{ $suited{ $_->suit } }, $_->pips
		foreach sort { $b->pips <=> $a->pips } $self->cards;
	return %suited;
}

sub by_pips {
	my $self = shift;
	my %pips;
	push @{ $pips{ $_->pips } }, $_->suit foreach $self->cards;
	return %pips;
}

sub unique_pips {
	my $self = shift;
	my %seen;
	my %part = map { $_ => [] } qw/l x h c a/;
	my @uniq = grep !$seen{ $_->pips }++, $self->cards;
	push @{ $part{ $_->rank } }, $_->pips foreach @uniq;
	return %part;
}

sub hand_score {
	my $self = shift;
	sum($self->flush_score, $self->pair_score, $self->straight_score);
}

sub flush_score {
	my $self   = shift;
	my %suited = $self->by_suit;
	my $score  = 0;
	foreach my $suit (keys %suited) {
		my @cards = @{ $suited{$suit} };
		next unless @cards > 1;
		$score += $self->flush_pts($cards[0]);
		$score -= 2 if @cards == 4;
	}
	$score;
}

sub pair_pts  { (0, 0, 4, 4, 4, 4, 4, 4, 4, 5,   6,   6, 7,   8, 9)[ $_[1] ] }
sub flush_pts { (0, 0, 1, 1, 1, 1, 1, 1, 1, 1.5, 1.5, 2, 2.5, 3, 4)[ $_[1] ] }

sub pair_score {
	my $self = shift;
	my %pips = $self->by_pips;
	(sum map $self->pair_pts($_), grep @{ $pips{$_} } == 2, keys %pips) || 0;
}

sub straight_score {
	my $self = shift;
	my %part      = $self->unique_pips;

	my $typecount = sub { sum map scalar @{ $part{$_} }, @_ };
	my $straight_pts = sub {
		my $wantcount  = shift;
		my $givepoints = pop;
		my @wanttype   = @_;
		my @gap_loss   = (0, 1, 1, 2);
		if ($typecount->(@wanttype) == $wantcount) {
			my $gap = gap(@part{@wanttype});
			return $givepoints - $gap_loss[$gap] if $gap <= 3;
		}
	};

	my $score = 0;
	$score += 2 if ($typecount->('a') == 1 && $typecount->('c') == 1);
	$score++ if ($typecount->('a') == 1 && $typecount->('l') == 1);
	$score += $straight_pts->(2 => qw/l x/,     2);
	$score += $straight_pts->(2 => qw/x h c/,   4);
	$score += $straight_pts->(3 => qw/a x h c/, 7);
	$score += $straight_pts->(4 => qw/a x h c/, 12);
	return $score;
}

sub gap {
	my @pips = sort { $a <=> $b } map @$_, @_;
	return ($pips[-1] - $pips[0]) - (@pips - 1);
}

return 1;

__END__

=head1 NAME

Games::Poker::Omaha::Hutchison - Hutchison method for scoring Omaha hands

=head1 SYNOPSIS

	my $evaluator = Games::Poker::Omaha::Hutchison->new("Ah Qd 3s 1d");

	my $score = $evaluator->hand_score;

=head1 DESCRIPTION

This module implements the Hutchison Omaha Point System for evaluating
starting hands in Omaha poker, as described at
http://www.thepokerforum.com/omahasystem.htm

=head1 CONSTRUCTOR

	my $evaluator = Games::Poker::Omaha::Hutchison->new("Ah Qd Ts 3d");

This takes 4 cards, expresed as a single string. The 'pip value' of the
card should be 2-9,T,J,Q,K or A, and the suit, of course, s, h, c or d.

=head1 METHODS

=head2 hand_score

	my $score = $evaluator->hand_score;

This returns the number of points assigned to the hand by this System.
This figure is roughly equivalent to the percentage chance of this
turning into a winning hand in a 10 player game, where each player plays
until the end. See the URL above for more information.

=head1 AUTHOR

Tony Bowden <tony@tmtm.com>, based on the rules created by Edward
Hutchison.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

