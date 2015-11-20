<?php
	session_start();

	require_once('editace.php');

	$empty=false; //Overovani vyplneni formulare
	$uspech=true; //Pozadavky pro registraci

 if(!empty($_POST))
 {
	foreach ($_POST as $argument) 
	{
		if(empty($argument))
		{
			$empty=true;
			break;
		}	
	}

	if($empty)
	{	
		header("location: registrace.php?info=Vyplňte prosím všechny údaje !!!");
		$uspech=false;
	}

	else{
		/*pripojeni do databaze*/
		$link=getConnectDb();

		$jmena=mysql_query("SELECT login FROM uzivatele", $link);

		/*Kontrola, zda zadany login existuje*/
	  while ($Kontrola_loginu=mysql_fetch_row($jmena))
	  {
	  	foreach ($Kontrola_loginu as $login)
		{
			
			if($login==$_POST["mail"] && $uspech)
			{
				header("location: registrace.php?info=tento login nebo E-mail již existuje !!!");
				$uspech=false;
			}
		}
	  }
		
		/*Kontrola hesla*/
		if($_POST["pass_reg"]!=$_POST["pass_reg2"] && $uspech)
		{
			header("location: registrace.php?info=hesla se neshodují !!!");
			$uspech=false;
		}

		/*delka hesla, alespon 8 znaku*/
		else if((strlen($_POST["pass_reg"])<=8) && $uspech)
		{
			header("location: registrace.php?info=Heslo je příliš krátké, musí obsahovat alespoň 8 znaků !!!");
			$uspech=false;
		}

		/*Pokud vsechny udaje byly spravne, uloz do databaze*/
		if($uspech)
		{	
			$vlozeni=mysql_query("INSERT INTO uzivatele(login, heslo, jmeno, prijmeni, adresa, email, telefon, is_admin) 
			VALUES ('$_POST[mail]','$_POST[pass_reg]','$_POST[jmeno]','$_POST[prijmeni]','$_POST[add]','$_POST[mail]','$_POST[tel]', false)", $link);	
			if($vlozeni)
			{
				echo "Uspesna registrace ".$Kontrola_loginu[0];	
				header("location: registrace.php?info=Registrace proběhla úspěšně & correct=true");
				exit();
			}

			else{
				echo "nepodarilo se vas vlozit do databaze, zkuste to prosim znovu";
			}
		}
	}
}	
?>

<!DOCTYPE html>
<html>
<link href='https://fonts.googleapis.com/css?family=Lobster' rel='stylesheet' type='text/css'>
<link href='https://fonts.googleapis.com/css?family=Orbitron' rel='stylesheet' type='text/css'>
<link href='https://fonts.googleapis.com/css?family=Titillium+Web' rel='stylesheet' type='text/css'>
<head>
	<title>Rezervace letenek</title>
	<meta charset="utf-8" />
	<link rel="stylesheet" href="//code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css">
  <script src="//code.jquery.com/jquery-1.10.2.js"></script>
  <script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
<script>
  $(function() {
    $( "#datepicker2" ).datepicker();
  });
  </script>
  <script>
  $(function() {
    $( "#datepicker" ).datepicker();
  });
  </script>

	<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
	
		<div id="header">
		<h1>Rezervace letenek</h1>
		</div>
		<div id="menu">
		 <nav>
            <ul class="fancyNav">
                <li id="home"><a href="index.php">Letenky</a></li>
                <li id="news"><a href="#news">Akce</a></li>
              	<?php 
              			if($_SESSION['admin'])
              				echo "<li id=\"admin\"><a href=\"admin.php\">administrace</a></li>";
              	?>
                <li id="services"><a href="registrace.php">Registrace</a></li>
            </ul>
        </nav>
        </div>
         <div id="infopanel"><br>
         <?php
         	if(!empty($_SESSION['username']))
         	{
         		echo "Jste přihlášen jako ". htmlspecialchars($_SESSION['username']);
       				
        			if($_SESSION['admin'])
        				echo ' admin';         
         		echo "<br>";
        		echo "<a href=\"login.php?odhlasit\">Odhlásit</a>";
        	}
         	else
         		echo "Nejste přihlášen";
         ?>
         </div>
        <div id="pageField">
            <div id="reg_form">
                <div id="login">
                    <h2>Registrace</h2>
                </div>
                <div id="jmeno_prij">
                
                <form method="post">
                <input id="jmeno" name="jmeno" placeholder="Jméno" type="text">
                <input id="prijmeni" name="prijmeni" placeholder="Příjmení" type="text">
                 <input id="add" name="add" placeholder="Adresa" type="text">
                 <input id="tel" name="tel" placeholder="Telefon" type="text">

                <input id="mail" name="mail" placeholder="E-mail" type="text">
                </div>
                <div id="jmeno_prij">
                <input id="pass_reg" name="pass_reg" placeholder="Heslo" type="password">
                <input id="pass_reg2" name="pass_reg2" placeholder="Kontrla hesla" type="password">


            <input name="submit_reg" type="submit" value=" Registrovat ">

            </form>
            	 <?php 
            	 	/*Vysledek registrace, popripade chyba*/
            	 	if($_GET['correct'])
            	 	{	
            	 		echo "<h3 style=\"color: green; font-weight: bold;\">".$_GET['info']."</h3>";
            	 		echo "<a href=\"index.php\" style=\"font-size: 20px; color: blue;\">Přejít na hlavní stránku</a>";
            	  	}

            	 	else		            	 			
            	 		echo "<h3 style=\"color: red; font-weight: bold;\">".$_GET['info']."</h3>";
                ?>
                </div>
                

            </div>
        </div>

</body>
</html>
