#!/usr/bin/perl -w

# Orinoc Stage 2 - Interactive Version
# By Dean McGregor

sub loadValuesToHashTable($);
sub showDetailsISBN(%$);
sub findData(%@);
sub printResults(%);
sub getSearchTerms(@);
sub matches(%$@);
sub makeAccount($);
sub initProgram();
sub login($);
sub verifyPassword($$);
sub addToBasket($);
sub dropFromBasekt($);

#initalisation stuff, making and loading files
#and writing into hash tables

initProgram();
$bookFile = "books.json";
%books = loadValuesToHashTable($bookFile);
$currentUser="";
@basket = ();

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
		makeAccount($commands[1]);
	} elsif ($action =~ m/login/i) {
		login($commands[1]);
	} elsif ($action =~ m/add/i) {
		addToBasket($commands[1]);
	} elsif ($action =~ m/drop/i) {
		dropFromBasket($commands[1]);
	} elsif ($action =~ m/basket/i) {
		
	} elsif ($action =~ m/checkout/i) {
		
	} elsif ($action =~ m/orders/i) {
		
	} else {
		printf "Incorrect command: $action.\nPossible commands are:\nlogin <login-name>\nnew_account <login-name>\nsearch <words>\ndetails <isbn>\nadd <isbn>\ndrop <isbn>\nbasket\ncheckout\norders\nquit\n"
	}
}

#initalises the current folder
sub initProgram() {
	if (!(-d "./orders")) {
		print "Creating ./orders\n";
		mkdir "./orders";
	} 
	if (!(-d "./baskets")) {
		print "Creating ./baskets\n";
		mkdir "./baskets";
	} 
	if (!(-d "./users")) {
		print "Creating ./users\n";
		mkdir "./users";
	} 
}

#add a book to the basket
sub addToBasket($) {
	my $isbn = shift;
	if ($currentUser eq "") {
		print "Not logged in.\n";
	} else {
		if (exists $books{$isbn}) {
			push @basket, $isbn;
		} else {
			print "No such book with ISBN $isbn\n";
		}
	}
}

#remove an isbn from the basket
sub dropFromBasekt($) {
	my $isbn = shift;
	if ($currentUser eq "") {
		print "Not logged in.\n";
	} else {
		my $numArray = scalar @basket;
		foreach $num (0..$numArray) {
			if ($basket[$num] eq $isbn) {
				$basket[$num] = "";
			}
		}
	}
}

#logs in a user
sub login($) {
	my $userName = shift;
	if (-e "./users/$userName") {
		print "Password: ";
		$line = <STDIN>;
		chomp $line;
		if (verifyPassword($userName, $line)) {
			$currentUser = $userName;
			print "Welcome to orinoco.com, $userName.\n";
		} else {
			print "The password doesn't match\n";
		}
	} else {
		print "User '$userName' does not exist.\n";
	}
}

#checks if a given string matches a password or not
sub verifyPassword($$) {
	my $userName = shift;
	my $password = shift;
	open (USER, "./users/$userName") or die "Cannot open user file $userName\n";
	chomp ($line = <USER>);
	$line =~ s/password=//;
	close(USER);
	if ($line eq $password) {
		return 1;
	} else {
		return 0;
	}
}

#sub to make a new account file in the /users folder
sub makeAccount($) {
	my $userName = shift;
	if (!(-e "./users/$userName")) {
		open (ACCOUNT, "+>./users/$userName") or die "Cannot create new file for user $userName\n";
		print "Password: ";
		$line = <STDIN>;
		print ACCOUNT "password=$line";
		print "Full Name: ";
		$line = <STDIN>;
		print ACCOUNT "name=$line";
		print "Street: ";
		$line = <STDIN>;
		print ACCOUNT "street=$line";
		print "City/Suburb: ";
		$line = <STDIN>;
		print ACCOUNT "city=$line";
		print "State: ";
		$line = <STDIN>;
		print ACCOUNT "state=$line";
		print "Postcode: ";
		$line = <STDIN>;
		print ACCOUNT "postcode=$line";
		print "Email: ";
		$line = <STDIN>;
		print ACCOUNT "email=$line";
		close(ACCOUNT);
		$currentUser = $userName;
		print "Welcome to Orinoco, $userName\n";
	} else {
		print "$userName is taken\n";
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



