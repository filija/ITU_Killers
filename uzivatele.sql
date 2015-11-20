-- phpMyAdmin SQL Dump
-- version 4.0.10deb1
-- http://www.phpmyadmin.net
--
-- Počítač: localhost
-- Vygenerováno: Ned 11. říj 2015, 15:09
-- Verze serveru: 5.5.44-0ubuntu0.14.04.1
-- Verze PHP: 5.5.9-1ubuntu4.13

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Databáze: `flaskadb`
--

-- --------------------------------------------------------

--
-- Struktura tabulky `uzivatele`
--

CREATE TABLE IF NOT EXISTS `uzivatele` (
  `id_cestujici` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(25) COLLATE utf8_czech_ci NOT NULL,
  `heslo` varchar(25) COLLATE utf8_czech_ci NOT NULL,
  `jmeno` varchar(25) COLLATE utf8_czech_ci NOT NULL,
  `prijmeni` varchar(25) COLLATE utf8_czech_ci NOT NULL,
  `adresa` varchar(50) COLLATE utf8_czech_ci NOT NULL,
  `email` varchar(50) COLLATE utf8_czech_ci NOT NULL,
  `telefon` varchar(20) COLLATE utf8_czech_ci NOT NULL,
  `is_admin` tinyint(1) NOT NULL,
  PRIMARY KEY (`id_cestujici`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_czech_ci AUTO_INCREMENT=17 ;

--
-- Vypisuji data pro tabulku `uzivatele`
--

INSERT INTO `uzivatele` (`id_cestujici`, `login`, `heslo`, `jmeno`, `prijmeni`, `adresa`, `email`, `telefon`, `is_admin`) VALUES
(1, 'filija', 'admin', 'Jakub', 'Filipek', 'Stary Poddvorov 318', 'filija.jakub@gmail.com', '775214063', 1),
(16, 'deka', 'tajneheslo', 'Jaroslav', 'Dekar', 'nekde 512', 'deka', '721 854 369', 0);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
