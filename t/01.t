#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 26;
use Games::Poker::Omaha::Hutchison;

our %expect = (
  "As Ks Ah Kh" => [ 27, 8, 17, 2 ],
  "8s 9s 9d 8d" => [ 16, 3, 9,  4 ],
  "Qs Qd 8H 8C" => [ 13, 0, 11, 2 ],
  "As Ah 7C 2D" => [ 10, 0, 9,  1 ],
  "KS KD 3s 6D" => [ 15, 6, 8,  1 ],
  "AS KD QH TS" => [ 15, 4, 0,  11 ],
);

while (my ($hand_str, $pts) = each %expect) {
  my $hand = Games::Poker::Omaha::Hutchison->new($hand_str);
  my ($ttl, $flush, $pairs, $str8) = @$pts;
  is $hand->flush_score, $flush,, "Flush $hand_str";
  is $hand->pair_score,     $pairs, "Pairs $hand_str";
  is $hand->straight_score, $str8,  "Straight $hand_str";
  is $hand->hand_score, $ttl, "Total $hand_str";
}


{
	my $hand = eval { Games::Poker::Omaha::Hutchison->new };
	ok $@, "Need arguments for new";
}

{
	my $hand = Games::Poker::Omaha::Hutchison->new(qw/As Ks Ah KH/); 
	is $hand->hand_score, 27, "Can pass list to constructor, too";
}

