// Copyright © 2020 Mark Summerfield. All rights reserved.
// License: GPLv3

const string APPNAME = "wordladder";
const string VERSION = "0.1.0";
const string WORDFILE = "/usr/share/hunspell/en_US.dic";
const int SIZE = 4; // Must be even
const int STEPS = SIZE;

class WordSet : Gee.HashSet<string> {}
class WordList : Gee.ArrayList<string> {}


void main(string[] args) {
    var words = read_words(WORDFILE, SIZE);
    var tick = get_monotonic_time();
    stdout.printf("Try ");
    for (int count = 1; ; count++) {
	stdout.printf(".");
	var ladder = generate_ladder(words, STEPS);
	if (ladder != null && ladder.size > 0) {
	    stdout.printf("%d\n", count);
	    foreach (var word in ladder)
		stdout.printf("%s\n", word);
	    break;
	}
    }
    stdout.printf("%.3f sec\n", (get_monotonic_time() - tick) / 1000000);
}


WordSet read_words(string wordfile, int size) {
    var words = new WordSet();
    var word_rx = /^[a-z]+/;
    var file = File.new_for_path(wordfile);
    try {
	var dis = new DataInputStream(file.read());
	MatchInfo mi;
	string line;
	while ((line = dis.read_line_utf8(null)) != null) {
	    if (word_rx.match(line, 0, out mi)) {
		var word = mi.fetch(0);
		if (word.char_count() == size)
		    words.add(word.up());
	    }
	}
    } catch (Error err) {
	error("%s", err.message);
    }
    return words;
}


WordList? generate_ladder(WordSet original_words, int steps) {
    var words = new WordSet();
    words.add_all(original_words);
    var ladder = new WordList();
    var prev = update_words_and_ladder(ref ladder, ref words, words);
    for (int i = 0; i <= steps; i++) {
	var compatibles = compatible_words(prev, words);
	if (compatibles.size == 0)
	    return null;
	prev = update_words_and_ladder(ref ladder, ref words, compatibles);
    }
    var first = ladder[0];
    var last = ladder[ladder.size - 1];
    for (int i = 0; i < first.char_count(); i++) {
	int j = first.index_of_nth_char(i);
	int k = last.index_of_nth_char(i);
	if (first.get_char(j) == last.get_char(k))
	    return null; // Reject if any common vertical letters
    }
    return ladder;
}


string update_words_and_ladder(ref WordList ladder, ref WordSet words,
			       WordSet compatibles) {
    var array = (string[]) compatibles.to_array();
    int i = array.length == 1 ? 0 : Random.int_range(0, array.length - 1);
    var prev = array[i];
    ladder.add(prev);
    words.remove(prev);
    return prev;
}


WordSet compatible_words(string prev, WordSet words) {
    var compatibles = new WordSet();
    int size = prev.char_count();
    int limit = size - 1;
    foreach (var word in words) {
	int count = 0;
	for (int i = 0; i < size; i++) {
	    int j = prev.index_of_nth_char(i);
	    int k = word.index_of_nth_char(i);
	    if (prev.get_char(j) == word.get_char(k))
		count++;
	}
	if (count == limit)
	    compatibles.add(word);
    }
    return compatibles;
}
