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
sub dropFromBasket($);
sub printShortBookDetails(%);
sub quitProgram();
sub showBasket();
sub checkout();
sub printOrderDetails($);
sub viewOrders();

#validator functions for input data
sub checkValidPassword($);
sub checkValidUsername($);
sub checkValidISBN($);
sub validateCreditCard($);
sub checkExpiry($);

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
		quitProgram();
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
		if (checkValidUsername($commands[1])) {
			makeAccount($commands[1]);
		}
	} elsif ($action =~ m/login/i) {
		if (checkValidUsername($commands[1])) {
			login($commands[1]);
		}
	} elsif ($action =~ m/add/i) {
		if (checkValidISBN($commands[1])) {
			addToBasket($commands[1]);
		}
	} elsif ($action =~ m/drop/i) {
		if (checkValidISBN($commands[1])) {
			dropFromBasket($commands[1]);
		}
	} elsif ($action =~ m/basket/i) {
		showBasket();
	} elsif ($action =~ m/checkout/i) {
		checkout();
	} elsif ($action =~ m/orders/i) {
		viewOrders();
	} else {
		printf "Incorrect command: $action.\nPossible commands are:\nlogin <login-name>\nnew_account <login-name>\nsearch <words>\ndetails <isbn>\nadd <isbn>\ndrop <isbn>\nbasket\ncheckout\norders\nquit\n"
	}
}

#initalises the current folder
sub initProgram() {
	if (!(-d "./orders")) {
		print "Creating ./orders\n";
		mkdir "./orders";
		#create the file to store the next order number
		open (NEXTNUM, ">./orders/NEXT_ORDER_NUMBER");
		print NEXTNUM "0";
		close (NEXTNUM);
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

#write the necessary files and quit the program
sub quitProgram() {
	#check if basket is empty
	$emptyBasket = 0;
	if (scalar @basket == 0) {
		$emptyBasket = 1;
	} else {
		foreach $isbn (@basket) {
			if ($isbn eq "") {
				$emptyBasket = 1;
			}
		}
	}
	#remove file if there's an empty basket
	if (($emptyBasket) && (-e "./baskets/$currentUser")) {
		unlink "./baskets/$currentUser";
	} elsif (scalar @basket > 0) {
		open (BASKET, ">./baskets/$currentUser");
		seek BASKET,0,0;
		foreach $isbn (@basket) {
			print BASKET "$isbn\n";
		}
		close(BASKET);
	}
}

sub viewOrders() {
	if ($currentUser ne "") {
		if (!(-e "./orders/$currentUser")) {
			print "No orders for user $currentUser\n";
		} else {
			open (ORDERS, "./orders/$currentUser") or die ("Cannot open orders file for $currentUser");
			foreach $number (<ORDERS>) {
				chomp $number;
				printOrderDetails($number);
			}
			close (ORDERS);
			print "\n";
		}
	} else {
		print "Not logged in.\n";
	}
}

sub printOrderDetails($) {
	my $number = shift;
	open (CURRENT_ORDER, "./orders/$number") or die "Cannot open order number $number";
	$line = <CURRENT_ORDER>;
	$line =~ /.*=(.*)/;
	$time = $1;
	chomp $time;
	$timeStr = localtime ($time);
	print "\nOrder #$number - $timeStr\n";
	$line = <CURRENT_ORDER>;
	$line =~ /.*=(.*)/;
	$cardNo = $1;
	$line = <CURRENT_ORDER>;
	$line =~ /.*=(.*)/;
	$expiry = $1;
	chomp $cardNo;
	chomp $expiry;
	print "Credit Card Number: $cardNo (Expiry $expiry)\n";
	while ($line = <CURRENT_ORDER>) {
		chomp $line;
		printShortBookDetails($books{$line});
	}
	close (CURRENT_ORDER);
}

#takes basket and turns it into an order
sub checkout() {
	print "Credit Card Number: ";
	while (!validateCreditCard($cardNo = <STDIN>)) {
		print "\nCredit Card Number: ";	
	}
	chomp $cardNo;
	print "Expiry date (mm/yy): ";
	while (!checkExpiry($expiry = <STDIN>)) {
		print "\nExpiry date (mm/yy): ";
	}
	chomp $expiry;
	#get the next order number
	if (-e "./orders/NEXT_ORDER_NUMBER") {
		open (NUM, "./orders/NEXT_ORDER_NUMBER") or die "Cannot open the next order number";
		$orderNum = <NUM>;
		chomp $orderNum;
		close(NUM);
	} else {
		$orderNum = 0;
	}
	#create a new file for the order
	open (ORDER_FILE, ">./orders/$orderNum") or die "Cannot create new file $orderNum";
	print ORDER_FILE "order_time=" . time() . "\n";
	print ORDER_FILE "credit_card_number=$cardNo\n";
	print ORDER_FILE "expiry_date=$expiry\n";
	foreach $isbn (@basket) {
		if ($isbn ne "") {
			print ORDER_FILE "$isbn\n";
		}
	}
	close(ORDER_FILE);
	#add the order to the user's record
	open (USER, ">>./orders/$currentUser") or die "Cannot open $currentUser order records";
	print USER "$orderNum\n";
	close (USER);
	$orderNum++;
	#update the next order number
	open (NUM, ">./orders/NEXT_ORDER_NUMBER") or die "Cannot open the next order number";
	print NUM "$orderNum\n";
	close(NUM);
	@basket = ();
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
sub dropFromBasket($) {
	my $isbn = shift;
	chomp $isbn;
	if ($currentUser eq "") {
		print "Not logged in.\n";
	} else {
		my $numArray = scalar @basket;
		for ($num=0; $num < $numArray; $num++) {
			if ($basket[$num] eq $isbn) {
				$basket[$num] = "";
			}
		}
	}
}

sub showBasket() {
	$totalCost = 0;
	foreach $isbn (@basket) {
		printShortBookDetails($books{$isbn});
		$books{$isbn}{price} =~ /\$(.*)/;
		$tempNum = $1;
		$totalCost += $tempNum;
	}
	print "Total: $totalCost\n";
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
			if (-e "./baskets/$userName") {
				@basket = ();
				open (BASKET, "./baskets/$userName");
				foreach $line (<BASKET>) {
					chomp $line;
					push @basket, $line;
				}
				close(BASKET);
			}
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
		while (!checkValidPassword($line = <STDIN>)) {
			print "Password: ";
		}
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
	my @dontShow = qw(SmallImageHeight MediumImageHeight LargeImageHeight MediumImageWidth ProductDescription MediumImageUrl ImageUrlMedium ImageUrlSmall authors ImageUrlLarge SmallImageUrl SalesRank LargeImageWidth SmallImageWidth price title LargeImageUrl);
	printShortBookDetails(\%book);
	foreach $key (sort keys %book) {
		if (!(grep {$_ eq $key} @dontShow)) {
			print "$key: $book{$key}\n";
		}	
	}
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
			printShortBookDetails($data{$isbn});
			#printf ("%s %7s %s - %s\n", $isbn, $data{$isbn}{price}, $data{$isbn}{title}, $data{$isbn}{authors});	
		}
	}
}

sub printShortBookDetails(%) {
	my $bookRef = shift;
	my %book = %$bookRef;
	printf ("%s %7s %s - %s\n", $book{isbn}, $book{price}, $book{title}, $book{authors});
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

#check the length of the password
sub checkValidPassword($) {
	my $password = shift;
	if (length($password) <= 5) {
		print "Invalid password: passwords must contain at least 5 characters.\n";
		return 0;
	} else {
		return 1;
	}
}

#check if username is between 3 - 5 characters
#also check it contains only letters and numbers
sub checkValidUsername($) {
	my $username = shift;
	chomp $username;
	if ($username =~ m/[^A-Za-z0-9]/) {
		print "Invalid login '$username': logins must start with a letter and contain only letters and digits.\n";
		return 0;
	} elsif (length($username) < 3 || length($username) > 8) {
		print "Invalid login: logins must be 3-8 characters long.\n";
		return 0;
	} else {
		return 1;
	}
}

#checks that an ISBN is a 10 digit string with numbers and X's only
sub checkValidISBN($) {
	my $isbn = shift;
	chomp $isbn;
	if (length($isbn) == 10) {
		if ($isbn !~ m/^[0-9X]{10}$/) {
			print "Invalid isbn '$isbn' : an isbn must be exactly 10 digits.\n";
			return 0;	
		}
	} else {
		print "Invalid isbn '$isbn' : an isbn must be exactly 10 digits.\n";
		return 0;
	}
	return 1;
}

#checks a valid credit card number is a string of 16 digits
sub validateCreditCard($) {
	my $cardNo = shift;
	chomp $cardNo;
	if (length($cardNo) == 16) {
		if ($cardNo !~ m/[0-9]{16}/) {
			print "Invalid credit card number - must be 16 digits.\n";
			return 0;
		}
	} else {
		print "Invalid credit card number - must be 16 digits.\n";
		return 0;
	}
	return 1;
}

#checks the formatting of the expiry is mm/yy
sub checkExpiry($) {
	my $expiry = shift;
	chomp $expiry;
	if ($expiry !~ m/[0-9]{2}\/[0-9]{2}/) {
		print "Invalid expiry date - must be mm/yy, e.g. 11/04.\n";
		return 0;
	}
	return 1;
}


