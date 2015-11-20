<?php
  session_start();
 

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
			<h1> Rezervace letenek</h1>

		</div>    
		<div id="menu">
		 <nav>
            <ul class="fancyNav">
                <li id="home"><a href="index.php">Letenky</a></li>
                <li id="news"><a href="#news">Akce</a></li>
              	<?php 
              			if($_SESSION['admin'])
              				echo "<li id=\"admin\"><a href=\"administrace.php\">administrace</a></li>";
              	?>
                <li id="services"><a href="registrace.php">Registrace</a></li>
            </ul>
        </nav>
        </div>

        <div id="infopanel"><br>Jste přihlášen jako <?= htmlspecialchars($_SESSION['username']) ?>
        		<?php
        			if($_SESSION['admin'])
        				echo 'admin';

        		?>
        <br>
        <a href="login.php?odhlasit">Odhlásit</a>
         </div>
          <center>
            <p style="font-size: 70px;">Tady bude administrace</p>
            </center>
</body>
</html>