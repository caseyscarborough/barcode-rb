-- phpMyAdmin SQL Dump
-- version 3.3.10.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Apr 07, 2013 at 10:29 AM
-- Server version: 5.1.56
-- PHP Version: 5.3.13

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `caseys1_rb_inventory`
--

-- --------------------------------------------------------

--
-- Table structure for table `inventory`
--

DROP TABLE IF EXISTS `inventory`;
CREATE TABLE IF NOT EXISTS `inventory` (
  `Barcode` varchar(20) NOT NULL,
  `ItemName` varchar(40) NOT NULL,
  `ItemCategory` varchar(20) NOT NULL,
  `Quantity` int(11) NOT NULL,
  `Price` float NOT NULL,
  `Description` varchar(40) NOT NULL,
  UNIQUE KEY `Barcode` (`Barcode`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Dumping data for table `inventory`
--

INSERT INTO `inventory` (`Barcode`, `ItemName`, `ItemCategory`, `Quantity`, `Price`, `Description`) VALUES
('9780321545893', 'Artificial Intelligence', 'Books', 2, 129, 'Addison Wesley Publ.'),
('045888224100', 'Papermate Pen', 'School Supplies', 20, 3.25, 'Ballpoint pen'),
('11369937', 'Teardrop Keytag', 'Accessories', 10, 6.95, 'Metal Keyring'),
('013803107821', 'Canon Powershot', 'Camera', 0, 289.99, 'Powershot SX200IS'),
('9780596516178', 'The Ruby Programming Language', 'Books', 23, 25, 'O''Reilly Publ.'),
('4796005650710', 'Lipton Clear Green Tea', 'Drink', 12, 2.5, 'Green tea'),
('312547171366', 'Benadryl Allergy', 'Medicine', 41, 7.39, '48-ct Allergy tablets'),
('152215900085', 'Old Navy Flip Flops', 'Shoes', 21, 9.99, 'Black designer flip flops'),
('718037784410', 'WDTV Live', 'Electronics', 32, 89.99, 'Streaming media player');