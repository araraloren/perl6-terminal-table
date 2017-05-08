
use v6;
use Text::Tabs;
use Terminal::Table::String;

unit module LightWrap;

grammar Sentence {
	token TOP {
		[ <splited> | <splited-by-block> | <other> ]+
	}

	token other {
		<!splited> <!splited-by-block> .
	}

	token splited {
		<:Block("Afaka")>
		| <:Block("Armenian")>
		| <:Block("Blissymbols")>
		| <:Block("Han")>
		| <:Block("Hangul Syllables")>
		| <:Block("Hiragana")>
		| <:Block("Katakana")>
	}

	token splited-by-block {
		<:Block("Arabic")>
		| <:Block("Balinese")>
		| <:Block("Bengali")>
		| <:Block("Latin")>
	}
}

class Sentence::Actions {
	has $.max;
	has $.line;
	has $.current;
	has $.force;
	has @!lines;

	method new(:$max!, :$force = False) {
		self.bless(:$max, :current(0), :line(""), :$force);
	}

	method other($/) {
		self.__concat_line($/.Str => noexpand-width($/.Str));
	}

	method splited($/) {
		self.__concat_line($/.Str => noexpand-width($/.Str));
	}

	method splited-by-block($/) {
		dd $/;
		my ($key, $value) = ($/.Str, noexpand-width($/.Str));

		if $!force && ($value > $!max || ($value + $!current > $!max)) {
			self.__concat_line($key.comb());
		} else {
			self.__concat_line($key => $value);
		}
	}

	method __reset() {
		($!line, $!current) = ("", 0);
	}

	multi method __concat_line(@ens) {
		for @ens -> $ch {
			my $len = noexpand-width($ch);
			if $!current + $len + 1 == $!max && $!current != 0 {
				self.__push($!line ~ $ch ~ '-');
				self.__reset();
			}
			($!line, $!current) = ($!line ~ $ch, $!current + $len);
		}
	}

	multi method __concat_line(Pair $str) {
		if $!current + $str.value > $!max && $!current != 0 {
			self.__push($!line);
			self.__reset();
		}
		($!line, $!current) = ($!line ~ $str.key, $!current + $str.value);
	}

	method __push(Str $str) {
		@!lines.push(String.new(value => $str, width => noexpand-width($str)));
	}

	method lines() {
		if $!line ne "" {
			self.__push($!line);
			self.__reset();
		}
		@!lines;
	}
}

sub split-w($str, Int $length, :$force = False) {
	Sentence.parse($str, :actions(my $a = Sentence::Actions.new(max => $length, :$force)));
	$a.lines();
}

multi sub wrap(String $str, Int :$max-width, Int :$tabstop, Bool :$force = False) is export {
	my @ret = [];
	@ret.append(split-w($_, $max-width, :$force)) for @(expand(split(/\n/, $str), $tabstop));
	return @ret>>.unexpand;
}

multi sub wrap(@strs, Int :$max-width, Int :$tabstop, Bool :$force = False) is export {
	my @ret = [];
	for @strs -> $str {
		@ret.append(split-w($_, $max-width, :$force)) for @(expand(split(/\n/, $str), $tabstop));
	}
	return @ret>>.unexpand;
}
