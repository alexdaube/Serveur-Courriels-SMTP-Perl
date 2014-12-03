#!/usr/bin/env perl
use IO::Socket;
use Digest::MD5 qw(md5_hex);

$| = 1;

my $connection = IO::Socket::INET->new(Proto => tcp,
						PeerAddr => localhost,
						PeerPort => 25)
or die "Impossible de se connecter sur le port 25 a l'adresse localhost";

while(1){
	print "Veuillez vous connecter\n";
	print "Nom d'usager: ";
	my $username = <STDIN>;
	$connection->send($username);

	print "Mot de passe: ";
	my $password = <STDIN>;
	my $hash = md5_hex($password);
	$connection->send($hash);

	$connection->recv($response, 1024);
	if($response eq "Accepted"){
		print "Connection acceptée\n";
		last;
	}
	else{
		print "Connection refusée\n\n";
		next;
	}
}

while (1) {
	showMenu();
}

sub showMenu { 
	print "\nMenu\n";
	print "1. Envoi de courriels\n";
	print "2. Consultation de courriels\n";
	print "3. Statistiques\n";
	print "4. Modifier le message d'absence\n";
	print "5. Quitter\n";
	print "Votre choix: ";
	my $choice = <STDIN>;

	if ($choice eq "1\n"){
		sendMail();
	}
	if ($choice eq "2\n"){
		displayMail();
	}
	if ($choice eq "3\n"){
		displayStatistics();
	}
	if ($choice eq "4\n"){
		modifyAbsentMessage();
	}
	if ($choice eq "5\n"){
		$connection->send("Quit");
		exit;
	}
}

sub sendMail {
	$connection->send("SendMail");
	
	print "\nAdresse de destination: ";
	my $destination = <STDIN>;
	chomp $destination;
	$connection->send($destination);
	
	print "Adresse en CC: ";
	my $CC= <STDIN>;
	chomp $CC;
	if(length($CC) eq 0) {
		$CC = " ";
	}
	$connection->send($CC);
	
	print "Sujet: ";
	my $subject = <STDIN>;
	chomp $subject;
	$connection->send($subject);
	
	print "Corps: ";
	my $body = <STDIN>;
	chomp $body;
	$connection->send($body);

	$connection->recv($response, 1024);
	print $response;
	
}
sub displayMail {
	$connection->send("DisplayMail");

	$connection->recv($response, 2048);
	print "\n".$response;

	if ($response eq "Aucun messages dans la boîte\n") {
		next;
	} else {
		print "Choisissez un message à voir: \n";
		my $subject = <STDIN>;
		$connection->send($subject);

		$connection->recv($response, 2048);
		print $response;
	}
}
sub displayStatistics {
	$connection->send("DisplayStatistics");
	$connection->recv($response, 2048);
	print "\n".$response;

	print "Tapez une touche pour retourner au menu";
	my $type  = <STDIN>; 
}
sub modifyAbsentMessage {
	$connection->send("AbsMes");
	print "Veuillez entrer votre nouveau message:\n";
	my $newMessage = <STDIN>;
	$connection->send($newMessage);
	$connection->recv($response, 1024);
	print $response;
}
