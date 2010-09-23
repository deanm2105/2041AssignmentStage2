#!/usr/bin/perl -w

# Orinoc Stage 2 - Interactive Version
# By Dean McGregor

sub loadValuesToHashTable($);
sub showDetailsISBN(%$);

#initalisation stuff, making and loading files
#and writing into hash tables
$bookFile = "books.json";
%books = loadValuesToHashTable($bookFile);

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
	print "$book{ProductDescription}\n";
}

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



