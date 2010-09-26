#!/usr/bin/perl -w

# Orinoc Stage 2 - Interactive Version
# By Dean McGregor

sub loadValuesToHashTable($);
sub showDetailsISBN(%$);
sub findData(%@);
sub printResults(%);
sub getSearchTerms(@);
sub matches(%$@);

#initalisation stuff, making and loading files
#and writing into hash tables
$bookFile = "books.json";
%books = loadValuesToHashTable($bookFile);

#flag for exiting
$exit = 0;
#main loop to get commands
print "orinoco.com - ASCII interface\n";
while (!$exit) {
	print "> ";
	$line = <STDIN>;
	$line =~ s/\n//g;
	@commands = split(/\s/, $line);
	$action = $commands[0];
	if ($action =~ m/quit/i) {
		$exit = 1;
		print "Thanks for shopping at orinoco.com.\n";
	} elsif ($action =~ m/details/i) {
		if (exists $books{$commands[1]}) {
			showDetailsISBN($books{$commands[1]}, $commands[1]);
		} else {
			print "$commands[1] does not exist\n";
		}
	} elsif ($action =~ m/search/i) {
		@searchTerms = ();
		#make an array of search terms
		foreach $term (@commands) {
			if ($term ne $action) {
				push @searchTerms, $term;
			}
		}
		printResults(findData(\%books, \@searchTerms));
	} elsif ($action =~ m/new_account/i) {
		
	} elsif ($action =~ m/login/i) {
		
	} elsif ($action =~ m/add/i) {
		
	} elsif ($action =~ m/drop/i) {
		
	} elsif ($action =~ m/checkout/i) {
		
	} elsif ($action =~ m/orders/i) {
		
	} else {
		printf "Incorrect command: $action.\nPossible commands are:\nlogin <login-name>\nnew_account <login-name>\nsearch <words>\ndetails <isbn>\nadd <isbn>\ndrop <isbn>\nbasket\ncheckout\norders\nquit\n"
	}
}

#function preforms a search based on keywords given
sub findData(%@) {
	$dataRef = shift;
	%data = %$dataRef;
	$searchTermRef = shift;
	@searchTerm = @$searchTermRef;
	
	%termsByCat = getSearchTerms(@searchTerm);
	%result = ();
	#go through all books and fields for search
	#if they match, add them to the results table
	foreach $isbn (keys %data) {
		$match = 1;
		foreach $key (keys %termsByCat) {
			if (!exists $data{$isbn}{$key} && $key ne "") {
				print "Unknown keyword\n";
				exit (1);	
			} else {
				if (!matches($data{$isbn}, $key, $termsByCat{$key})) {
					$match = 0;
				}	
			}
		}
		if ($match) {
			$result{$isbn} = $data{$isbn};
		}
	}
	return %result;
}

#read json file into a hash table
sub loadValuesToHashTable($) {
	my ($fileName) = @_;
	my %hash = ();
	open(BOOKDB,"<$fileName") or die "Cannot open given database";
	$readingAuthors = 0;
	while ($line = <BOOKDB>) {
		#if reading authors line by line
		if ($readingAuthors) {
			if ($line =~ m/^\s*\],\s*$/) {
				$readingAuthors = 0;
				$authorsString =~ s/\s*,\s*$//;
				
				if ($authorCount > 2) {
					$authorsString =~ s/,(.*),\s(.*)$/,$1 & $2/;
				} else {
					$authorsString =~ s/,/ &/;
				}
				$hash{$currentISBN}{authors} = $authorsString;
			} elsif ($line =~ m/^\s*"(.*)"\s*/) {
				$authorCount++;
				$authorsString = "$authorsString$1, ";
				$authorsString =~ s/\\(.*)\\/$1/;
			}
		} else {
			#grab the ISBN
			if ($line =~ m/^\s*"(\d+X?)"\s*:\s*{\s*$/) {
				$currentISBN = $1;
			} elsif ($line =~ m/^\s*"authors"\s*:\s*\[\s*$/) {
				$readingAuthors = 1;
				$authorsString = "";
				$authorCount = 0;
			} elsif ($line =~ m/^\s*"(.*)"\s*:\s*"(.*)",\s*$/) {
				#pattern match and pull out all data into a hash table
				$temp = $2;
				$cat = $1;
				$temp =~ s/\\//;
				$hash{$currentISBN}{$cat} = $temp;
			}
		}
	}	
	close(BOOKDB);	
	return %hash;
}

sub showDetailsISBN(%$) {
	my $bookRef = shift;
	my %book = %$bookRef;
	my $isbn = shift;
	printf ("%s %7s %40s\n", $isbn, $book{price}, $book{title});
	#need to add details here as per sample program
	print "$book{ProductDescription}\n";
}

#checks that the given book matches all the keywords given for a field
sub matches(%$@) {
	$bookRef = shift;
	%book = %$bookRef;
	$field = shift;
	$keywordsRef = shift;
	@keywords = @$keywordsRef;
	$matches = 1;
	foreach $word (@keywords) {
		if ($word !~ m/^<.*>$/) {		
			$word =~ s/[\.\*\+\\\{\}\[\]\$\^]+//;
			if ($field eq "") {
				if ($word eq "") {
					$matches=0;
				} elsif (($book{title} !~ m/\b$word\b/i) and ($book{authors} !~ m/\b$word\b/i)) {
					$matches=0;
				}
			} else {
				if ($book{$field} !~ m/\b$word\b/i) {
					$matches=0;
				}
			}
		}
	}
	return $matches;
	
}

#breaks down search terms into fields
#returns an associative array of fields->search terms
sub getSearchTerms(@) {
	%termByCat = ();
	$cat = "";
	@tempArray = ();
	$termByCat{$cat} = \@tempArray;
	foreach $term (@searchTerms) {
		if ($term =~ m/^(.*):(.*)$/i) {
			if (exists $termByCat{$1}) {
				$arrayRef = $termByCat{$1};
				push @$arrayRef, $2;
			} else {
				my @catTerms = ();
				push @catTerms, $2;
				#funky pointer magic to make multiple arrays
				$termByCat{$1} = \@catTerms;
			}
		} else {
			$arrayRef = $termByCat{$cat};
			push @$arrayRef, $term;
		}	
	}
	return %termByCat;
}

#display the result of the search
sub printResults(%) {
	my (%data) = @_;
	$numKeys = keys %data;
	if ($numKeys == 0) {
		print "No books matched.\n";
	} else {
		foreach $isbn (sort myHashSort keys %data) {
			printf ("%s %7s %s - %s\n", $isbn, $data{$isbn}{price}, $data{$isbn}{title}, $data{$isbn}{authors});	
		}
	}
}

#definition of sort for results
#sort on SalesRank first, then ISBN
sub myHashSort {
	#weight non-salesrank items so they end up at the bottom of the list
	if (!(exists $data{$a}{SalesRank})) {
		$data{$a}{SalesRank} = 9999999999999999;
	}
	if (!(exists $data{$b}{SalesRank})) {
		$data{$b}{SalesRank} = 9999999999999999;
	}
	if ($data{$a}{SalesRank} == $data{$b}{SalesRank}) {
		return ($data{$a}{isbn} cmp $data{$b}{isbn});
	} else {
		return ($data{$a}{SalesRank} <=> $data{$b}{SalesRank});
	}
}



