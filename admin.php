<?php
	session_start();
	require_once('editace.php');

  if(!$_SESSION['admin'])
  { 
    echo "<meta charset=\"utf-8\">";
    echo "<p style=\"font-size: 50px;\">nejste přihlášen jako admin !!!</p>";
    echo "<a href=\"index.php\" style=\"font-size: 25px;\">zpět na hlavní stránku</a>";
     exit();
  } 

  if(!isset($_SESSION['username']))
  {
  	header('location: login.php');
    exit();
  }

  if($_GET['admin'])
  {
  		$_SESSION['admin']=true;
  }

  if(isset($_GET['odhlasit']))
  {
    session_destroy();
    header('location: index.php');
    exit();
  }

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
		header("location: admin.php?info=Vyplňte prosím všechny údaje !!!");
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
				header("location: admin.php?info=tento login nebo E-mail již existuje !!!");
				$uspech=false;
			}
		}
	  }
		
		/*Kontrola hesla*/
		if($_POST["pass_reg"]!=$_POST["pass_reg2"] && $uspech)
		{
			header("location: admin.php?info=hesla se neshodují !!!");
			$uspech=false;
		}

		/*delka hesla, alespon 8 znaku*/
		else if((strlen($_POST["pass_reg"])<=8) && $uspech)
		{
			header("location: admin.php?info=Heslo je příliš krátké, musí obsahovat alespoň 8 znaků !!!");
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
				header("location: admin.php?info=Registrace proběhla úspěšně & correct=true");
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
		<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
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
		<script type="text/javascript">
			function showDiv(){
				document.querySelector('#main').classList.add('blur');
				document.querySelector('#show_div').classList.remove('hidden');
			}
			
		</script>

		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
	<body>
		<div id="show_div" class="hidden">
        	<div id="window">
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
            	
                </div>
                </form>
                	
                	<a class="material-icons" href="admin.php">cancel</a>
                </div>	
        </div>

 		<div id="main">
			<div id="header">
				<h1> Rezervace letenek</h1>
			</div>
			<div id="menu">
				<nav>
            		<ul class="fancyNav">
                		<li id="home"><a href="index.php">Letenky</a></li>
                		<li id="news"><a href="admin.php">Akce</a></li>
                		<?php 
              			if($_SESSION['admin'])
              				echo "<li id=\"admin\"><a href=\"admin.php\">administrace</a></li>";
              			?>
                		<li id="services"><a href="registrace.php">Registrace</a></li>
            		</ul>
        		</nav>
        	</div>
        	<div id="infopanel"><br><br>Jste přihlášen jako <?= htmlspecialchars($_SESSION['username']) ?>
        		<?php
        			if($_SESSION['admin'])
        				echo 'admin';

        		?>
        		<br>
        		<a href="login.php?odhlasit">Odhlásit</a>
        
        	</div>
        	<div id="pageField">
        		<div id="textField_users">
        			<div id="administrace">
       					<h2>Users</h2>
       				</div>
       				<table>
       				<form method="post" action="editace.php">
       					<?php 
       						mysql_connect("127.0.0.1","root","decathlon");
       						mysql_select_db("rezervace_letenek");
       						$result=mysql_query("SELECT jmeno, prijmeni, adresa, email, telefon, login, is_admin FROM uzivatele");
							$x=0;
							$y=0;
							while($row = mysql_fetch_row($result))
								{
									echo "<tr>";
									echo "<td><input name=\"jmeno[$y]\" type=\"text\" value=\"$row[0]\"></td>";
    								echo "<td><input name=\"prijmeni[$y]\"type=\"text\" value=\"$row[1]\"></td>";
    								echo "<td><input name=\"adresa[$y]\" type=\"text\" value=\"$row[2]\"> </td>";
    								echo "<td><input name=\"email[$y]\" type=\"text\" value=\"$row[3]\"></td>";
    								echo "<td><input name=\"telefon[$y]\" type=\"text\" value=\"$row[4]\"> </td>";
									/*checkbox zaskrtavani*/
									if($row[6])
									{
    									echo "<td><input name=\"admin[$y]\" type=\"checkbox\" value=\"$row[6]\" checked>admin</td>";
    								}
    								else
    								{
    									echo "<td><input name=\"admin[$y]\" type=\"checkbox\" value=\"$row[6]\">admin</td>";	
    								}

    								echo "<td><input name=\"login[$y]\" type=\"hidden\" value=\"$row[5]\"> </td>";
    								echo "<td><input type=\"submit\" value=\"Upravit\" name=\"submit[$x]\"></td>";
    								echo "<td><input type=\"submit\" value=\"Odstranit\" name=\"delete[$x]\"></td><br>";
    								echo "</tr>\n";
    								$x++;
    								$y++;	

    							}
    					?>
       				</table>       				
        				<?php
        						echo "<h3 style=\"color: green; font-size: 20px; font-weight: bold;\">".$_GET['stav']."</h3>";
        				
		            	 	/*Vysledek registrace, popripade chyba*/
        		    	 	if($_GET['correct'])
            		 		{	
            	 				echo "<h3 style=\"color: green; font-weight: bold; font-size: 20px;\">".$_GET['info']."</h3>";
            	 				
            	  			}

            	 			else		            	 			
            	 				echo "<h3 style=\"color: red; font-weight: bold; font-size: 20px;\">".$_GET['info']."</h3>";
                
        				?>
       				</form>	
       			</div>
        		<div id="tlacitko">
        			<form method="post">
        				<input type="button" name="reg_window" value="Registrace uživatele" onclick="showDiv()">
        				<input type="button" name="reg_windows" value="Vytvořit rezervaci" onclick="hello()">

        			</form>
        			
        		</div>		
        	</div>
        </div> 
	</body>
	</html>
