#!/usr/bin/env perl
use IO::Socket;
use MIME::Lite;

$| = 1;

$serveur = IO::Socket::INET->new(Proto => tcp,
				LocalPort => 25,
				Listen => SOMAXCONN,
				Reuse => 1)
or die "Impossible de se connecter sur le port 25 en localhost";

while($connection = $serveur->accept()){
	my $username = undef;
	my $password = undef;
	my $loggedOn = 0;
	while(1){
		my $ligne = "";
		if ($username eq undef){
			$connection->recv($ligne, 1024); 
			$username = $ligne;
			chomp $username;
		}
		if ($password eq undef and $ligne ne ""){
			$connection->recv($ligne, 1024);
			$password = $ligne;
			chomp $password;
		}

		if($loggedOn eq 0){
			open(my $userFile, "<$username/config.txt"); 
			$firstLine = <$userFile>;
			chomp $firstLine;
			if($firstLine ne $password or $password eq ""){
				$connection->send("Denied");
				$username = undef;
				$password = undef;
				next;
			}
			else {
				$connection->send("Accepted");
				$loggedOn = 1;
			}
		}
		if($loggedOn){
			$connection->recv($ligne, 2048);
			
			if($ligne =~ /SendMail/){
				$connection->recv($destination, 1024);
				$connection->recv($CC, 1024);
				$connection->recv($subject, 1024);
				$connection->recv($body, 1024);
				$destination =~ /([^@]+)@(.+)/;
				$user = $1;
				$domain = $2;
				
				if ($domain =~ /glo.ca/){
					my $time = localtime;
					my $mail;
					open($mail, ">$user/$time - $subject.txt")
					or do {
					open($mail, ">DESTERR/$time - $subject.txt");
					};
						print $mail "De: $username\@glo.ca\nPour: $destination\nCC: $CC\nTitre: $subject\n$body";
						close($mail);
						
						open($userFile, "<$user/config.txt") or do{
							$connection->send("Le destinataire n'existe pas\n");
							next;
						};
						<$userFile>;
						$message = <$userFile>;
						$connection->send("Message envoyé\nLe destinataire a un message d'absence: $message\n");
				}
				else{
					$msg = MIME::Lite->new(
						From => "$username\@glo.ca",
						To => $destination,
						Cc => $CC,
						Subject => $subject,
						Data => $body);
					$mailSent = eval{$msg->send('smtp', "smtp.ulaval.ca", Timeout=>60)} ;
					if(!$mailSent){
						$connection->send("Erreur lors de l'envoie du couriel\n");
						next;
					}
					else{
						$connection->send("Message Envoyé\n");
						next;
					}
				}

			}

			if($ligne =~ /DisplayMail/){
				
				my $dir = "$username";
				opendir(DIR, $dir) or die $!;
				my $list = "";
				my $i = 1;
				while (my $file = readdir(DIR)) {
					next if($file =~ m/^\./);
					next if($file =~ /config.txt/);
					$list .= "$i : $file \n";
					$i++;
				}
				closedir(DIR);
				
				if($list ne ""){
					$connection->send($list);		
				} else {
					$connection->send("Aucun messages dans la boîte\n");
					next;
				}
			    $connection->recv($subject, 1024);
				opendir(DIR, $dir) or die $!;
				my $n = 1;
				my $message;
				while (my $file = readdir(DIR)) {
					next if($file =~ m/^\./);
					next if($file =~ /config.txt/);
					if($subject =~ /$n/) {
						open(MAIL, "<$username/$file") or die "Cannot open file $file";
						while(<MAIL>){
							$message .= $_;
						}
						close(MAIL);
						last;
					}
					$n++;
				}
				closedir(DIR);		
				if ($message ne undef) {
					$connection->send("\nMessage reçu:\n\n$message\n");
				} else {
					$connection->send("Pas le bon code d'accès\n");
				}
			}
			
			if($ligne =~ /DisplayStatistics/){
				my $dir = "$username";
				opendir(DIR, $dir) or die $!;
				my $i = 0;
				my $list = "";
				my $size;
				while (my $file = readdir(DIR)) {
					$size += (stat("$username/$filename"))[7];
					next if($file =~ m/^\./);
					next if($file =~ /config.txt/);
					$i++;
					$list .= "  $i : $file \n";
				}
				closedir(DIR);
				if ($list eq "") {
					$list = "  Aucun message";
				}
				$connection->send("Il y a $i messages dans votre boîte.\nVotre boîte a une taille de $size octets.\nVoici vos messages:\n$list\n\n"); 

			}
			if($ligne =~ /AbsMes/){
				$connection->recv($newMessage, 1024);
				open(my $userFile, "+<$username/config.txt");
				<$userFile>;
				truncate($userFile, $userFile->tell);
				print $userFile $newMessage;
				$connection->send("Message enregistré\n");
			}
			if($ligne =~ /Quit/){
				$username = undef;
				$password = undef;
				$loggedOn = 0;
				last;
			}
		}
	}
}
