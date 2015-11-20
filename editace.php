<?php
	session_start();

	
	/*Funkce pro pripojeni k databazi*/
	function getConnectDb()
	{
			$link=mysql_connect("127.0.0.1", "root", "decathlon");

 			if(!$link)
 			{
 				echo "Chyba nepodarilo se spojit s databazi";
 				exit();
 			}

 			$select=mysql_select_db("rezervace_letenek", $link);
			if(!$select)
			{
				echo "Nepodarilo se vybrat databazi";
				exit();
			}
			return $link;
	}

	if(!empty($_POST))
	{
		/*Pokud admin bude chtit upravovat*/
		 if (isset($_POST['submit']))
		 {
   				$submit_id = array_keys($_POST['submit']);
   				$submit_id = $submit_id[0];
		
 		$i=0; 		
 		foreach ($_POST['jmeno'] as $key)
 			{		
 					$jmeno[$i]=$key;
 					$i++;
 			}	

 			$i=0;
 		foreach ($_POST['prijmeni'] as $key)
 			{		
 					$prijmeni[$i]=$key;
 					$i++;
 			}	

 			$i=0;
 		foreach ($_POST['adresa'] as $key)
 			{		
 					$adresa[$i]=$key;
 					$i++;
 			}	

 			$i=0;
 		foreach ($_POST['email'] as $key)
 			{		
 					$email[$i]=$key;
 					$i++;
 			}	

 			$i=0;
 		foreach ($_POST['telefon'] as $key)
 			{		
 					$telefon[$i]=$key;
 					$i++;
 			}

 		/*Zacatek Admin checkbox*/
 			$admin = $_POST['admin'];
 		 	
 		 	for($j=0; $j<$i; $j++)
 		 	{
 		 		if(isset($admin[$j]))
 		 		{
 		 			$admin[$j]=1;
 		 		}

 		 		else{
 		 			$admin[$j]=0;
 		 		}
 		 	}
 		 	
 		 	echo $admin[$submit_id];
 		 /*Konec Admin checkbox*/

 				$i=0;
 		foreach ($_POST['login'] as $key)
 			{		
 					$login[$i]=$key;
 					$i++;
 			}

 			$link=getConnectDb();

			mysql_query("UPDATE uzivatele SET jmeno='$jmeno[$submit_id]' WHERE login='$login[$submit_id]'", $link);
			mysql_query("UPDATE uzivatele SET prijmeni='$prijmeni[$submit_id]' WHERE login='$login[$submit_id]'", $link);
			mysql_query("UPDATE uzivatele SET adresa='$adresa[$submit_id]' WHERE login='$login[$submit_id]'", $link);
			mysql_query("UPDATE uzivatele SET email='$email[$submit_id]' WHERE login='$login[$submit_id]'", $link);
			mysql_query("UPDATE uzivatele SET telefon='$telefon[$submit_id]' WHERE login='$login[$submit_id]'", $link);			
			mysql_query("UPDATE uzivatele SET is_admin='$admin[$submit_id]' WHERE login='$login[$submit_id]'", $link);						
		
			header('location: admin.php?stav=Upraveno!');
		}
		/*Konec upravovani*/

		/*Pokud admin bude chtit mazat*/
		if(isset($_POST['delete']))
		{
				$delete_id = array_keys($_POST['delete']);
   				$delete_id = $delete_id[0];

   			$i=0;
 			foreach ($_POST['login'] as $key)
 			{		
 					$login[$i]=$key;
 					$i++;
 			}

 			$link=getConnectDb();

			mysql_query("DELETE FROM uzivatele WHERE login='$login[$delete_id]'", $link);

			header('location: admin.php?stav=Smazáno!');
 		}
		/*Konec mazani*/
		
	}	

?>