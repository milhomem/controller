-- MySQL dump 10.11
--
-- Host: localhost    Database: is4web_sistema
-- ------------------------------------------------------
-- Server version	5.0.96-community

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `actionlog`
--

DROP TABLE IF EXISTS `actionlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `actionlog` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent` varchar(50) default NULL,
  `action` varchar(50) default NULL,
  `refer` varchar(50) default NULL,
  PRIMARY KEY  (`id`),
  KEY `action` (`action`),
  KEY `refer` (`refer`)
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `activitylog`
--

DROP TABLE IF EXISTS `activitylog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activitylog` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `cid` varchar(255) NOT NULL default '',
  `date` varchar(255) NOT NULL default '',
  `user` varchar(255) NOT NULL default '',
  `action` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=609 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `affiliates`
--

DROP TABLE IF EXISTS `affiliates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `affiliates` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `username` mediumint(5) unsigned NOT NULL,
  `lft` smallint(5) unsigned NOT NULL,
  `rgt` smallint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `lft` (`lft`),
  UNIQUE KEY `rgt` (`rgt`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `announce`
--

DROP TABLE IF EXISTS `announce`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `announce` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `author` varchar(255) default NULL,
  `subject` varchar(255) default NULL,
  `message` text,
  `staff` char(1) default NULL,
  `users` char(1) default NULL,
  `time` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bancos`
--

DROP TABLE IF EXISTS `bancos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bancos` (
  `codigo` smallint(3) unsigned zerofill NOT NULL,
  `nome` varchar(255) default NULL,
  `site` varchar(255) default NULL,
  PRIMARY KEY  (`codigo`),
  FULLTEXT KEY `nome` (`nome`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blocked_email`
--

DROP TABLE IF EXISTS `blocked_email`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_email` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `address` varchar(255) NOT NULL default '',
  `type` varchar(255) NOT NULL default '',
  `count` int(10) unsigned default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `address` (`address`,`type`)
) ENGINE=MyISAM AUTO_INCREMENT=466 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blocked_ips`
--

DROP TABLE IF EXISTS `blocked_ips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_ips` (
  `ip` int(10) unsigned NOT NULL,
  `time` datetime NOT NULL,
  PRIMARY KEY  (`ip`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `boletos_processados`
--

DROP TABLE IF EXISTS `boletos_processados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `boletos_processados` (
  `id` mediumint(8) unsigned NOT NULL,
  `fileid` char(32) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COMMENT='Identifica a duplicidade com par boleto-arquivo';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `calls`
--

DROP TABLE IF EXISTS `calls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `calls` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `status` enum('A','F','H') NOT NULL default 'A',
  `username` varchar(25) default NULL,
  `email` varchar(255) default NULL,
  `priority` char(3) default NULL,
  `service` varchar(100) NOT NULL default '-',
  `category` varchar(255) default NULL,
  `subject` varchar(255) default NULL,
  `description` text,
  `time` datetime default NULL,
  `ownership` varchar(255) default NULL,
  `closedby` varchar(255) default NULL,
  `method` char(2) default NULL,
  `track` varchar(50) NOT NULL default '',
  `active` varchar(50) NOT NULL default '',
  `aw` char(1) default NULL,
  `an` char(1) NOT NULL default '',
  `time_spent` varchar(255) NOT NULL default '',
  `is_locked` smallint(5) default '0',
  PRIMARY KEY  (`id`),
  KEY `calls_st` (`status`),
  KEY `username` (`username`),
  KEY `email` (`email`),
  KEY `priority` (`priority`),
  KEY `service` (`service`),
  KEY `category` (`category`),
  KEY `subject` (`subject`),
  KEY `ownership` (`ownership`),
  KEY `active` (`active`),
  KEY `aw` (`aw`),
  KEY `time` (`time`),
  KEY `method` (`method`),
  KEY `is_locked` (`is_locked`),
  KEY `closedby` (`closedby`),
  KEY `description` (`description`(100))
) ENGINE=MyISAM AUTO_INCREMENT=469 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cancelamentos`
--

DROP TABLE IF EXISTS `cancelamentos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cancelamentos` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `servid` mediumint(8) unsigned NOT NULL,
  `motivo` text,
  PRIMARY KEY  (`id`),
  KEY `service` (`servid`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cc`
--

DROP TABLE IF EXISTS `cc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cc` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `nome` varchar(50) default NULL,
  `banco` varchar(50) default '0',
  `dvbanco` varchar(50) default NULL,
  `agencia` varchar(50) default NULL,
  `conta` varchar(50) default NULL,
  `carteira` varchar(50) default NULL,
  `convenio` varchar(50) default NULL,
  `cedente` varchar(255) default NULL,
  `instrucoes` text,
  `nossonumero` mediumint(8) unsigned NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cc_info`
--

DROP TABLE IF EXISTS `cc_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cc_info` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `first` smallint(5) unsigned NOT NULL,
  `last` smallint(5) unsigned NOT NULL,
  `ccn` varchar(255) NOT NULL,
  `exp` varchar(4) NOT NULL,
  `cvv2` varchar(255) NOT NULL,
  `active` tinyint(3) default '0',
  `tarifa` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `username` (`username`,`ccn`),
  KEY `active` (`active`),
  KEY `tarifa` (`tarifa`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `countrycode`
--

DROP TABLE IF EXISTS `countrycode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `countrycode` (
  `id` varchar(2) NOT NULL,
  `nome` varchar(255) default NULL,
  `call` smallint(3) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `creditos`
--

DROP TABLE IF EXISTS `creditos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `creditos` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned NOT NULL,
  `valor` decimal(20,3) NOT NULL default '0.000',
  `descricao` varchar(255) NOT NULL,
  `balance` smallint(5) unsigned default NULL,
  PRIMARY KEY  (`id`),
  KEY `username` (`username`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cron`
--

DROP TABLE IF EXISTS `cron`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cron` (
  `rowid` int(10) unsigned NOT NULL auto_increment,
  `id` mediumint(9) NOT NULL default '0',
  `tipo` tinyint(1) NOT NULL default '0',
  `motivo` longtext,
  PRIMARY KEY  (`id`,`tipo`),
  UNIQUE KEY `rowid` (`rowid`)
) ENGINE=MyISAM AUTO_INCREMENT=856679 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cron_lock`
--

DROP TABLE IF EXISTS `cron_lock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cron_lock` (
  `id` int(11) NOT NULL default '0',
  `data` date NOT NULL default '0000-00-00',
  `hora` time default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `departments` (
  `id` smallint(11) unsigned NOT NULL,
  `nome` varchar(255) NOT NULL default '',
  `sender` varchar(255) NOT NULL,
  `signature` text,
  `level` tinyint(3) NOT NULL default '0',
  `visible` tinyint(3) unsigned NOT NULL default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `nome` (`nome`,`level`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `descontos`
--

DROP TABLE IF EXISTS `descontos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `descontos` (
  `id` mediumint(5) unsigned NOT NULL auto_increment,
  `plano` smallint(5) unsigned NOT NULL,
  `pg` smallint(5) unsigned NOT NULL,
  `valor` decimal(20,3) unsigned NOT NULL default '0.000',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `plano` (`plano`,`pg`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `despesas`
--

DROP TABLE IF EXISTS `despesas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `despesas` (
  `Id` int(11) NOT NULL auto_increment,
  `referencia` varchar(255) NOT NULL default '',
  `data` date NOT NULL default '0000-00-00',
  `valor` decimal(20,3) NOT NULL default '0.000',
  PRIMARY KEY  (`Id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discriminados`
--

DROP TABLE IF EXISTS `discriminados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discriminados` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `level` varchar(255) default NULL,
  `tabela` varchar(255) NOT NULL,
  `id_tabela` mediumint(8) unsigned NOT NULL,
  `campo` varchar(255) NOT NULL,
  `valor` varchar(255) NOT NULL,
  `incluir` enum('Y','N') default 'Y',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `documentacao`
--

DROP TABLE IF EXISTS `documentacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `documentacao` (
  `id` smallint(5) unsigned NOT NULL,
  `sid` smallint(5) unsigned NOT NULL,
  `nome` varchar(100) NOT NULL default '',
  `value` text,
  PRIMARY KEY  (`id`,`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `em_forwarders`
--

DROP TABLE IF EXISTS `em_forwarders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `em_forwarders` (
  `address` varchar(255) NOT NULL default '',
  `category` varchar(255) default NULL,
  PRIMARY KEY  (`address`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `message` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `feriados`
--

DROP TABLE IF EXISTS `feriados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `feriados` (
  `dia` tinyint(2) unsigned zerofill NOT NULL default '00',
  `mes` tinyint(2) unsigned zerofill NOT NULL default '00',
  `desc` varchar(255) default NULL,
  PRIMARY KEY  (`dia`,`mes`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `files` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `cid` varchar(255) default NULL,
  `nid` varchar(255) default NULL,
  `filename` varchar(255) NOT NULL default '',
  `file` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=76 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `follows`
--

DROP TABLE IF EXISTS `follows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `follows` (
  `call` mediumint(8) unsigned NOT NULL,
  `staff` varchar(20) NOT NULL,
  PRIMARY KEY  (`call`,`staff`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `formularios`
--

DROP TABLE IF EXISTS `formularios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `formularios` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `properties` varchar(255) default NULL,
  `desconto` decimal(20,3) unsigned NOT NULL default '0.000',
  `setup` enum('0','1') NOT NULL default '1',
  `auto` tinyint(3) unsigned NOT NULL,
  `nivel` tinyint(3) unsigned NOT NULL,
  `planos` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `indicates`
--

DROP TABLE IF EXISTS `indicates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `indicates` (
  `service` mediumint(8) unsigned NOT NULL,
  `username` mediumint(8) unsigned NOT NULL,
  `payed` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`service`),
  KEY `username` (`username`),
  KEY `payed` (`payed`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoices` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned default NULL,
  `status` enum('P','Q','C','D') NOT NULL default 'P',
  `nome` varchar(50) default NULL,
  `data_envio` date default '0000-00-00',
  `data_vencido` date NOT NULL,
  `data_vencimento` date NOT NULL,
  `data_quitado` date default '0000-00-00',
  `envios` tinyint(1) NOT NULL default '0',
  `referencia` text,
  `services` text,
  `valor` decimal(20,3) default '0.000',
  `valor_pago` decimal(20,3) default '0.000',
  `imp` tinyint(3) unsigned NOT NULL default '0',
  `conta` smallint(5) unsigned NOT NULL,
  `tarifa` tinyint(3) unsigned NOT NULL,
  `parcelas` tinyint(3) unsigned NOT NULL default '1',
  `parcelado` enum('S','L','O','D') NOT NULL default 'S',
  `nossonumero` varchar(25) default NULL,
  PRIMARY KEY  (`id`),
  KEY `username` (`username`),
  KEY `status` (`status`),
  KEY `data_envio` (`data_envio`),
  KEY `data_quitado` (`data_quitado`),
  KEY `envios` (`envios`),
  KEY `valor` (`valor`),
  KEY `valor_pago` (`valor_pago`),
  KEY `imp` (`imp`),
  KEY `data_vencido` (`data_vencido`),
  KEY `nossonumero` (`nossonumero`)
) ENGINE=MyISAM AUTO_INCREMENT=154 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `level`
--

DROP TABLE IF EXISTS `level`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `level` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `nome` varchar(255) NOT NULL default '',
  `mail_billing` varchar(255) NOT NULL,
  `mail_account` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `nome` (`nome`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `file` varchar(255) NOT NULL default '',
  `action` varchar(255) NOT NULL default '',
  `table` varchar(255) NOT NULL default '',
  `user` mediumint(8) unsigned default NULL,
  `servico` mediumint(8) unsigned default NULL,
  `value` longtext NOT NULL,
  `byuser` varchar(255) NOT NULL default '',
  `data` date NOT NULL default '0000-00-00',
  `tempo` time NOT NULL default '00:00:00',
  `debug` longtext,
  PRIMARY KEY  (`id`),
  KEY `file` (`file`),
  KEY `action` (`action`),
  KEY `table` (`table`),
  KEY `data` (`data`),
  KEY `tempo` (`tempo`),
  KEY `user` (`user`),
  KEY `byuser` (`byuser`),
  KEY `servico` (`servico`)
) ENGINE=InnoDB AUTO_INCREMENT=4169 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_mail`
--

DROP TABLE IF EXISTS `log_mail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_mail` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `byuser` varchar(20) default NULL,
  `user` mediumint(8) unsigned NOT NULL,
  `from` varchar(255) default NULL,
  `to` varchar(255) default NULL,
  `subject` varchar(255) default NULL,
  `body` longtext,
  `data` date NOT NULL default '0000-00-00',
  `tempo` time NOT NULL default '00:00:00',
  `enviado` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `user` (`user`),
  KEY `to` (`to`),
  KEY `data` (`data`),
  KEY `tempo` (`tempo`),
  KEY `byuser` (`byuser`),
  KEY `busca_areacliente` (`to`,`enviado`,`user`)
) ENGINE=InnoDB AUTO_INCREMENT=567 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_news`
--

DROP TABLE IF EXISTS `log_news`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_news` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `byuser` varchar(20) default NULL,
  `from` varchar(255) default NULL,
  `to` longtext,
  `subject` varchar(255) default NULL,
  `body` longtext,
  `data` date NOT NULL default '0000-00-00',
  `tempo` time NOT NULL default '00:00:00',
  PRIMARY KEY  (`id`),
  KEY `data` (`data`),
  KEY `tempo` (`tempo`),
  KEY `byuser` (`byuser`),
  FULLTEXT KEY `to` (`to`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log_sys`
--

DROP TABLE IF EXISTS `log_sys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_sys` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `file` varchar(255) NOT NULL default '',
  `action` varchar(255) NOT NULL default '',
  `table` varchar(255) NOT NULL default '',
  `user` mediumint(8) unsigned default NULL,
  `servico` mediumint(8) unsigned default NULL,
  `value` longtext NOT NULL,
  `data` date NOT NULL default '0000-00-00',
  `tempo` time NOT NULL default '00:00:00',
  `debug` longtext,
  PRIMARY KEY  (`id`),
  KEY `file` (`file`),
  KEY `action` (`action`),
  KEY `table` (`table`),
  KEY `data` (`data`),
  KEY `tempo` (`tempo`),
  KEY `user` (`user`),
  KEY `servico` (`servico`)
) ENGINE=InnoDB AUTO_INCREMENT=28347 DEFAULT CHARSET=latin1 ROW_FORMAT=COMPACT;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `touser` varchar(50) NOT NULL default '',
  `sender` varchar(50) NOT NULL default '',
  `date` varchar(20) NOT NULL default '',
  `subject` varchar(255) NOT NULL default '',
  `message` text NOT NULL,
  `stamp` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notes` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `owner` char(1) default NULL,
  `visible` char(1) default NULL,
  `action` varchar(255) default NULL,
  `call` mediumint(8) unsigned NOT NULL,
  `author` varchar(255) default NULL,
  `time` datetime default NULL,
  `ikey` varchar(255) default NULL,
  `comment` text,
  `poster_ip` varchar(40) default NULL,
  PRIMARY KEY  (`id`),
  KEY `pd_owner` (`owner`),
  KEY `pd_call` (`call`)
) ENGINE=MyISAM AUTO_INCREMENT=429 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online`
--

DROP TABLE IF EXISTS `online`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `online` (
  `username` varchar(255) NOT NULL default '0',
  `agent` longtext NOT NULL,
  `del` tinyint(1) NOT NULL default '0',
  `offset` tinyint(3) default '0',
  PRIMARY KEY  (`username`,`agent`(255)),
  KEY `del` (`del`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pagamento`
--

DROP TABLE IF EXISTS `pagamento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pagamento` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `nome` varchar(255) NOT NULL default '',
  `primeira` smallint(5) unsigned NOT NULL default '0',
  `intervalo` smallint(5) unsigned NOT NULL default '0',
  `parcelas` smallint(5) unsigned NOT NULL default '0',
  `pintervalo` smallint(5) unsigned NOT NULL default '30',
  `tipo` enum('S','L','O','D') NOT NULL default 'S',
  `repetir` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `nome` (`nome`),
  KEY `tipo` (`tipo`),
  KEY `repetir` (`repetir`),
  KEY `prepos` (`parcelas`,`primeira`)
) ENGINE=MyISAM AUTO_INCREMENT=26 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `planos`
--

DROP TABLE IF EXISTS `planos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `planos` (
  `servicos` smallint(5) unsigned NOT NULL default '0',
  `level` varchar(255) default NULL,
  `plataforma` enum('Linux','Windows','-') NOT NULL default 'Linux',
  `nome` varchar(25) NOT NULL default '',
  `tipo` enum('Hospedagem','Revenda','Registro','Adicional','Dedicado','Software') NOT NULL default 'Hospedagem',
  `descricao` varchar(100) default NULL,
  `campos` varchar(500) default NULL,
  `setup` decimal(20,3) NOT NULL default '0.000',
  `valor` decimal(20,3) default '0.000',
  `valor_tipo` enum('M','D','A','U') NOT NULL,
  `auto` varchar(50) default NULL,
  `pagamentos` varchar(255) default NULL,
  `alert` tinyint(1) unsigned default '0',
  `pservidor` smallint(5) unsigned default NULL,
  `notes` text,
  PRIMARY KEY  (`servicos`),
  KEY `plataforma` (`plataforma`),
  KEY `nome` (`nome`),
  KEY `tipo` (`tipo`),
  KEY `descricao` (`descricao`),
  KEY `level` (`level`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `planos_modules`
--

DROP TABLE IF EXISTS `planos_modules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `planos_modules` (
  `plano` smallint(5) unsigned NOT NULL default '0',
  `modulo` varchar(255) default NULL,
  PRIMARY KEY  (`plano`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `popservers`
--

DROP TABLE IF EXISTS `popservers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `popservers` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `pop_host` varchar(255) NOT NULL default '',
  `pop_user` varchar(255) NOT NULL default '',
  `pop_password` varchar(255) NOT NULL default '',
  `pop_port` varchar(5) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preans`
--

DROP TABLE IF EXISTS `preans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preans` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `author` varchar(255) default NULL,
  `subject` varchar(255) default NULL,
  `text` text,
  `date` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `author` (`author`,`subject`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promocao`
--

DROP TABLE IF EXISTS `promocao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `promocao` (
  `servico` mediumint(8) unsigned NOT NULL,
  `value` text,
  `type` tinyint(3) NOT NULL default '0',
  PRIMARY KEY  (`servico`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reviews`
--

DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reviews` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `owner` varchar(255) default NULL,
  `staff` varchar(255) default NULL,
  `nid` varchar(255) default NULL,
  `rating` varchar(255) default NULL,
  `comments` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `saldos`
--

DROP TABLE IF EXISTS `saldos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `saldos` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned NOT NULL default '0',
  `valor` decimal(20,3) NOT NULL default '0.000',
  `descricao` varchar(100) default NULL,
  `servicos` mediumint(8) unsigned default NULL,
  `invoice` mediumint(8) unsigned default NULL,
  PRIMARY KEY  (`id`),
  KEY `username` (`username`),
  KEY `servicos` (`servicos`),
  KEY `invoice` (`invoice`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `security`
--

DROP TABLE IF EXISTS `security`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `security` (
  `username` varchar(20) NOT NULL,
  `right` varchar(50) NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY  (`username`,`right`),
  KEY `right` (`right`),
  KEY `value` (`value`(100))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `securitygroups`
--

DROP TABLE IF EXISTS `securitygroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `securitygroups` (
  `groupname` varchar(20) NOT NULL,
  `right` varchar(50) NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY  (`groupname`,`right`),
  KEY `right` (`right`),
  KEY `value` (`value`(100))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servicos`
--

DROP TABLE IF EXISTS `servicos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servicos` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned NOT NULL default '0',
  `dominio` varchar(255) NOT NULL default 'Independente',
  `servicos` mediumint(4) unsigned NOT NULL default '0',
  `status` enum('A','S','B','T','E','P','C','F') NOT NULL default 'A',
  `inicio` date NOT NULL default '0000-00-00',
  `fim` date NOT NULL default '0000-00-00',
  `vencimento` date NOT NULL default '0000-00-00',
  `proximo` date NOT NULL default '0000-00-00',
  `servidor` smallint(5) unsigned default '0',
  `dados` text,
  `useracc` varchar(50) default NULL,
  `pg` smallint(5) unsigned NOT NULL default '0',
  `envios` tinyint(3) unsigned default NULL,
  `def` smallint(5) unsigned default '0',
  `action` enum('N','C','M','B','P','R','A') NOT NULL default 'N',
  `invoice` mediumint(11) unsigned default NULL,
  `pagos` smallint(11) unsigned default NULL,
  `desconto` decimal(20,3) unsigned default '0.000',
  `lock` tinyint(1) unsigned default '0',
  `parcelas` tinyint(1) unsigned NOT NULL default '1',
  `notes` text,
  PRIMARY KEY  (`id`),
  KEY `username` (`username`),
  KEY `status` (`status`),
  KEY `dominio` (`dominio`),
  KEY `inicio` (`inicio`),
  KEY `fim` (`fim`),
  KEY `vencimento` (`vencimento`),
  KEY `proximo` (`proximo`),
  KEY `servidor` (`servidor`),
  KEY `pg` (`pg`),
  KEY `envios` (`envios`),
  KEY `def` (`def`),
  KEY `action` (`action`),
  KEY `invoice` (`invoice`),
  KEY `pagos` (`pagos`),
  KEY `desconto` (`desconto`),
  KEY `lock` (`lock`),
  KEY `servicos` (`servicos`),
  KEY `parcelas` (`parcelas`)
) ENGINE=MyISAM AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servicos_set`
--

DROP TABLE IF EXISTS `servicos_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servicos_set` (
  `servico` mediumint(8) unsigned NOT NULL default '0',
  `MultiWEB` smallint(6) unsigned default NULL,
  `MultiDNS` smallint(5) unsigned default NULL,
  `MultiFTP` smallint(5) unsigned default NULL,
  `MultiDB` smallint(5) unsigned default NULL,
  `MultiMAIL` smallint(5) unsigned default NULL,
  `MultiSTATS` smallint(5) unsigned default NULL,
  PRIMARY KEY  (`servico`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servidores`
--

DROP TABLE IF EXISTS `servidores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servidores` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `nome` varchar(25) NOT NULL default '',
  `host` varchar(255) default NULL,
  `ip` varchar(15) default NULL,
  `port` varchar(6) default NULL,
  `ssl` varchar(1) default '0',
  `username` varchar(255) default NULL,
  `key` text,
  `ns1` varchar(255) default NULL,
  `ns2` varchar(255) default NULL,
  `os` enum('L','W','-') NOT NULL default 'L',
  `ativo` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `host-ip-port` (`host`,`ip`,`port`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servidores_set`
--

DROP TABLE IF EXISTS `servidores_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servidores_set` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `Rns1` varchar(255) default 'ns1',
  `Rns2` varchar(255) default 'ns2',
  `Hns1` varchar(255) default 'ns1',
  `Hns2` varchar(255) default 'ns2',
  `MultiWEB` varchar(255) default 'www',
  `MultiDNS` varchar(255) default 'dns',
  `MultiMAIL` varchar(255) default 'mail',
  `MultiFTP` varchar(255) default 'ftp',
  `MultiSTATS` varchar(255) default 'stats',
  `MultiDB` varchar(255) default 'db',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `settings` (
  `setting` varchar(50) NOT NULL default '',
  `value` text,
  UNIQUE KEY `setting` (`setting`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `skins`
--

DROP TABLE IF EXISTS `skins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `skins` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `setting` varchar(50) NOT NULL default '',
  `value` text NOT NULL,
  `name` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staff`
--

DROP TABLE IF EXISTS `staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `staff` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `username` varchar(20) default NULL,
  `password` varchar(255) default NULL,
  `name` varchar(50) default NULL,
  `email` varchar(255) default NULL,
  `access` varchar(255) default NULL,
  `notify` char(1) default NULL,
  `responsetime` varchar(20) default NULL,
  `callsclosed` varchar(10) default NULL,
  `signature` text,
  `rkey` char(5) default NULL,
  `lpage` varchar(255) default NULL,
  `play_sound` tinyint(1) default NULL,
  `llogin` varchar(255) default NULL,
  `admin` tinyint(1) NOT NULL default '0',
  `notes` text,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staffactive`
--

DROP TABLE IF EXISTS `staffactive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `staffactive` (
  `username` varchar(20) NOT NULL default '',
  `date` varchar(20) NOT NULL default ''
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staffgroups`
--

DROP TABLE IF EXISTS `staffgroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `staffgroups` (
  `username` varchar(20) NOT NULL,
  `group` varchar(50) NOT NULL,
  PRIMARY KEY  (`username`,`group`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stafflogin`
--

DROP TABLE IF EXISTS `stafflogin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stafflogin` (
  `username` varchar(50) NOT NULL default '',
  `date` varchar(20) default NULL,
  PRIMARY KEY  (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `staffread`
--

DROP TABLE IF EXISTS `staffread`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `staffread` (
  `username` varchar(50) NOT NULL default '',
  `date` varchar(20) NOT NULL default ''
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats`
--

DROP TABLE IF EXISTS `stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stats` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `username` mediumint(8) unsigned default NULL,
  `service` mediumint(8) unsigned default NULL,
  `invoice` mediumint(8) unsigned default NULL,
  `call` mediumint(8) unsigned default NULL,
  `conheceu` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tarifas`
--

DROP TABLE IF EXISTS `tarifas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tarifas` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `tipo` varchar(30) default NULL,
  `modo` varchar(30) default NULL,
  `modulo` varchar(255) NOT NULL default 'boleto',
  `valor` decimal(20,3) default '0.000',
  `tplIndex` varchar(255) NOT NULL,
  `autoquitar` tinyint(3) NOT NULL default '0',
  `visivel` tinyint(3) NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tarifas_set`
--

DROP TABLE IF EXISTS `tarifas_set`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tarifas_set` (
  `id` smallint(5) unsigned NOT NULL,
  `setting` varchar(50) NOT NULL,
  `value` text NOT NULL,
  KEY `setting` (`setting`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_events`
--

DROP TABLE IF EXISTS `user_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_events` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `user` varchar(255) default NULL,
  `time` varchar(255) default NULL,
  `subject` varchar(255) default NULL,
  `description` text,
  `date` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `username` mediumint(8) unsigned NOT NULL auto_increment,
  `password` varchar(255) NOT NULL default '',
  `vencimento` tinyint(2) unsigned zerofill NOT NULL default '01',
  `status` enum('CA','CP','CC') NOT NULL default 'CA',
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `empresa` varchar(100) default NULL,
  `cpf` varchar(11) NOT NULL default '0',
  `cnpj` varchar(15) default NULL,
  `telefone` varchar(20) default NULL,
  `endereco` varchar(255) NOT NULL default '',
  `numero` varchar(10) default NULL,
  `cidade` varchar(255) default NULL,
  `estado` char(2) NOT NULL default '',
  `cc` varchar(2) default NULL,
  `cep` varchar(11) default NULL,
  `level` varchar(255) NOT NULL default '',
  `inscricao` date NOT NULL default '0000-00-00',
  `rkey` varchar(5) default NULL,
  `pending` char(1) NOT NULL default '',
  `active` varchar(50) default NULL,
  `acode` varchar(50) default NULL,
  `lcall` varchar(255) NOT NULL default '',
  `conta` smallint(5) unsigned NOT NULL default '1',
  `forma` tinyint(3) unsigned NOT NULL default '1',
  `alert` tinyint(1) unsigned NOT NULL default '0',
  `alertinv` tinyint(3) unsigned NOT NULL default '0',
  `news` tinyint(1) unsigned NOT NULL default '1',
  `language` varchar(10) default NULL,
  `notes` text,
  PRIMARY KEY  (`username`),
  KEY `vencimento` (`vencimento`),
  KEY `status` (`status`),
  KEY `name` (`name`),
  KEY `email` (`email`),
  KEY `cpf` (`cpf`),
  KEY `cnpj` (`cnpj`),
  KEY `telefone` (`telefone`),
  KEY `cidade` (`cidade`),
  KEY `estado` (`estado`),
  KEY `level` (`level`),
  KEY `pending` (`pending`),
  KEY `alert` (`alert`),
  KEY `news` (`news`),
  KEY `alertinv` (`alertinv`)
) ENGINE=MyISAM AUTO_INCREMENT=1013 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_config`
--

DROP TABLE IF EXISTS `users_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_config` (
  `username` mediumint(8) unsigned NOT NULL,
  `setting` varchar(50) NOT NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`setting`,`username`),
  KEY `value` (`value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_del`
--

DROP TABLE IF EXISTS `users_del`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_del` (
  `username` mediumint(8) unsigned NOT NULL,
  PRIMARY KEY  (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_validate`
--

DROP TABLE IF EXISTS `users_validate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_validate` (
  `username` mediumint(8) unsigned NOT NULL,
  `password` varchar(255) NOT NULL default '',
  `vencimento` tinyint(2) unsigned zerofill NOT NULL default '01',
  `status` enum('CA','CP','CC') NOT NULL default 'CA',
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `empresa` varchar(100) default NULL,
  `cpf` varchar(11) NOT NULL default '0',
  `cnpj` varchar(15) default NULL,
  `telefone` varchar(10) default NULL,
  `endereco` varchar(255) NOT NULL default '',
  `numero` varchar(10) default NULL,
  `cidade` varchar(255) default NULL,
  `estado` char(2) NOT NULL default '',
  `cc` varchar(2) default NULL,
  `cep` varchar(11) default NULL,
  `level` varchar(255) NOT NULL default '',
  `inscricao` date NOT NULL default '0000-00-00',
  `rkey` varchar(5) default NULL,
  `pending` char(1) NOT NULL default '',
  `active` varchar(50) default NULL,
  `acode` varchar(50) default NULL,
  `lcall` varchar(255) NOT NULL default '',
  `conta` smallint(5) unsigned NOT NULL default '1',
  `forma` tinyint(3) unsigned NOT NULL default '1',
  `alert` tinyint(1) unsigned NOT NULL default '0',
  `alertinv` tinyint(3) unsigned NOT NULL default '0',
  `news` tinyint(1) unsigned NOT NULL default '1',
  `language` varchar(10) default NULL,
  KEY `username` (`username`),
  KEY `vencimento` (`vencimento`),
  KEY `status` (`status`),
  KEY `name` (`name`),
  KEY `email` (`email`),
  KEY `cpf` (`cpf`),
  KEY `cnpj` (`cnpj`),
  KEY `telefone` (`telefone`),
  KEY `cidade` (`cidade`),
  KEY `estado` (`estado`),
  KEY `level` (`level`),
  KEY `pending` (`pending`),
  KEY `alert` (`alert`),
  KEY `news` (`news`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `v1_ccinfo`
--

DROP TABLE IF EXISTS `v1_ccinfo`;
/*!50001 DROP VIEW IF EXISTS `v1_ccinfo`*/;
/*!50001 CREATE TABLE `v1_ccinfo` (
  `id` smallint(5) unsigned,
  `username` mediumint(8) unsigned,
  `name` varchar(255),
  `first` smallint(5) unsigned,
  `last` smallint(5) unsigned,
  `ccn` varchar(255),
  `exp` varchar(4),
  `cvv2` varchar(255),
  `active` tinyint(3),
  `tarifa` tinyint(3) unsigned,
  `tipo` varchar(30)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `v1_invoices`
--

DROP TABLE IF EXISTS `v1_invoices`;
/*!50001 DROP VIEW IF EXISTS `v1_invoices`*/;
/*!50001 CREATE TABLE `v1_invoices` (
  `id` mediumint(8) unsigned,
  `username` mediumint(8) unsigned,
  `status` enum('P','Q','C','D'),
  `nome` varchar(50),
  `data_envio` date,
  `data_vencido` date,
  `data_vencimento` date,
  `data_quitado` date,
  `envios` tinyint(1),
  `referencia` text,
  `services` text,
  `valor` decimal(20,3),
  `valor_pago` decimal(20,3),
  `imp` tinyint(3) unsigned,
  `conta` varchar(50),
  `tarifa` varchar(30),
  `parcelas` tinyint(3) unsigned,
  `parcelado` enum('S','L','O','D'),
  `nossonumero` varchar(25)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `v1_planos`
--

DROP TABLE IF EXISTS `v1_planos`;
/*!50001 DROP VIEW IF EXISTS `v1_planos`*/;
/*!50001 CREATE TABLE `v1_planos` (
  `servicos` smallint(5) unsigned,
  `level` varchar(255),
  `plataforma` enum('Linux','Windows','-'),
  `nome` varchar(25),
  `tipo` enum('Hospedagem','Revenda','Registro','Adicional','Dedicado','Software'),
  `descricao` varchar(100),
  `campos` varchar(500),
  `setup` decimal(20,3),
  `valor` decimal(20,3),
  `valor_tipo` enum('M','D','A','U'),
  `auto` varchar(50),
  `pagamentos` varchar(255),
  `alert` tinyint(1) unsigned,
  `pservidor` varchar(10),
  `modulo` varchar(255)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `v1_servicos`
--

DROP TABLE IF EXISTS `v1_servicos`;
/*!50001 DROP VIEW IF EXISTS `v1_servicos`*/;
/*!50001 CREATE TABLE `v1_servicos` (
  `id` mediumint(8) unsigned,
  `plano` mediumint(4) unsigned,
  `username` mediumint(8) unsigned,
  `dominio` varchar(255),
  `status` enum('A','S','B','T','E','P','C','F'),
  `action` enum('N','C','M','B','P','R','A'),
  `inicio` date,
  `fim` date,
  `vencimento` date,
  `proximo` date,
  `servidor` varchar(10),
  `useracc` varchar(50),
  `nome` varchar(25),
  `descricao` varchar(100),
  `tipo` enum('Hospedagem','Revenda','Registro','Adicional','Dedicado','Software'),
  `plataforma` enum('Linux','Windows','-'),
  `pagamento` varchar(255),
  `setup` decimal(20,3),
  `valor` decimal(20,3),
  `valor_tipo` enum('M','D','A','U'),
  `desconto` decimal(20,3) unsigned,
  `invoice` mediumint(11) unsigned,
  `envios` tinyint(3) unsigned,
  `def` smallint(5) unsigned,
  `primeira` smallint(5) unsigned,
  `intervalo` smallint(5) unsigned,
  `parcelas` smallint(5) unsigned
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `v2_servicos`
--

DROP TABLE IF EXISTS `v2_servicos`;
/*!50001 DROP VIEW IF EXISTS `v2_servicos`*/;
/*!50001 CREATE TABLE `v2_servicos` (
  `id` mediumint(8) unsigned,
  `username` mediumint(8) unsigned,
  `dominio` varchar(255),
  `servicos` mediumint(4) unsigned,
  `status` enum('A','S','B','T','E','P','C','F'),
  `inicio` date,
  `fim` date,
  `vencimento` date,
  `proximo` date,
  `servidor` smallint(5) unsigned,
  `dados` text,
  `useracc` varchar(50),
  `pg` smallint(5) unsigned,
  `envios` tinyint(3) unsigned,
  `def` smallint(5) unsigned,
  `action` enum('N','C','M','B','P','R','A'),
  `invoice` mediumint(11) unsigned,
  `pagos` smallint(11) unsigned,
  `desconto` decimal(20,3) unsigned,
  `lock` tinyint(1) unsigned,
  `parcelas` tinyint(1) unsigned,
  `intervalo` smallint(5) unsigned,
  `tipo` enum('Hospedagem','Revenda','Registro','Adicional','Dedicado','Software'),
  `valor_tipo` int(3),
  `parcela` decimal(31,7)
) ENGINE=MyISAM */;

--
-- Temporary table structure for view `v3_servicos`
--

DROP TABLE IF EXISTS `v3_servicos`;
/*!50001 DROP VIEW IF EXISTS `v3_servicos`*/;
/*!50001 CREATE TABLE `v3_servicos` (
  `id` mediumint(8) unsigned,
  `username` mediumint(8) unsigned,
  `dominio` varchar(255),
  `tipo` enum('Hospedagem','Revenda','Registro','Adicional','Dedicado','Software'),
  `plataforma` enum('Linux','Windows','-'),
  `plano` smallint(5) unsigned,
  `plano_nome` varchar(25),
  `status` enum('A','S','B','T','E','P','C','F'),
  `inicio` date,
  `fim` date,
  `vencimento` date,
  `proximo` date,
  `servidor` smallint(5) unsigned,
  `servidor_nome` varchar(10),
  `dados` text,
  `useracc` varchar(50),
  `pg` smallint(5) unsigned,
  `pg_nome` varchar(255),
  `envios` tinyint(3) unsigned,
  `def` smallint(5) unsigned,
  `action` enum('N','C','M','B','P','R','A'),
  `invoice` mediumint(11) unsigned,
  `pagos` smallint(11) unsigned,
  `desconto` decimal(20,3) unsigned,
  `lock` tinyint(1) unsigned,
  `parcelas` tinyint(1) unsigned
) ENGINE=MyISAM */;

--
-- Final view structure for view `v1_ccinfo`
--

/*!50001 DROP TABLE `v1_ccinfo`*/;
/*!50001 DROP VIEW IF EXISTS `v1_ccinfo`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v1_ccinfo` AS select `cc_info`.`id` AS `id`,`cc_info`.`username` AS `username`,`cc_info`.`name` AS `name`,`cc_info`.`first` AS `first`,`cc_info`.`last` AS `last`,`cc_info`.`ccn` AS `ccn`,`cc_info`.`exp` AS `exp`,`cc_info`.`cvv2` AS `cvv2`,`cc_info`.`active` AS `active`,`cc_info`.`tarifa` AS `tarifa`,`tarifas`.`tipo` AS `tipo` from (`cc_info` left join `tarifas` on((`cc_info`.`tarifa` = `tarifas`.`id`))) */;

--
-- Final view structure for view `v1_invoices`
--

/*!50001 DROP TABLE `v1_invoices`*/;
/*!50001 DROP VIEW IF EXISTS `v1_invoices`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v1_invoices` AS select `invoices`.`id` AS `id`,`invoices`.`username` AS `username`,`invoices`.`status` AS `status`,`invoices`.`nome` AS `nome`,`invoices`.`data_envio` AS `data_envio`,`invoices`.`data_vencido` AS `data_vencido`,`invoices`.`data_vencimento` AS `data_vencimento`,`invoices`.`data_quitado` AS `data_quitado`,`invoices`.`envios` AS `envios`,`invoices`.`referencia` AS `referencia`,`invoices`.`services` AS `services`,`invoices`.`valor` AS `valor`,`invoices`.`valor_pago` AS `valor_pago`,`invoices`.`imp` AS `imp`,`cc`.`nome` AS `conta`,`tarifas`.`tipo` AS `tarifa`,`invoices`.`parcelas` AS `parcelas`,`invoices`.`parcelado` AS `parcelado`,`invoices`.`nossonumero` AS `nossonumero` from ((`invoices` left join `tarifas` on((`tarifas`.`id` = `invoices`.`tarifa`))) left join `cc` on((`cc`.`id` = `invoices`.`conta`))) */;

--
-- Final view structure for view `v1_planos`
--

/*!50001 DROP TABLE `v1_planos`*/;
/*!50001 DROP VIEW IF EXISTS `v1_planos`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v1_planos` AS select `planos`.`servicos` AS `servicos`,`planos`.`level` AS `level`,`planos`.`plataforma` AS `plataforma`,`planos`.`nome` AS `nome`,`planos`.`tipo` AS `tipo`,`planos`.`descricao` AS `descricao`,`planos`.`campos` AS `campos`,`planos`.`setup` AS `setup`,`planos`.`valor` AS `valor`,`planos`.`valor_tipo` AS `valor_tipo`,`planos`.`auto` AS `auto`,`planos`.`pagamentos` AS `pagamentos`,`planos`.`alert` AS `alert`,(select `servidores`.`nome` AS `nome` from `servidores` where (`servidores`.`id` = `planos`.`pservidor`)) AS `pservidor`,`planos_modules`.`modulo` AS `modulo` from (`planos` left join `planos_modules` on((`planos`.`servicos` = `planos_modules`.`plano`))) */;

--
-- Final view structure for view `v1_servicos`
--

/*!50001 DROP TABLE `v1_servicos`*/;
/*!50001 DROP VIEW IF EXISTS `v1_servicos`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v1_servicos` AS select `servicos`.`id` AS `id`,`servicos`.`servicos` AS `plano`,`servicos`.`username` AS `username`,`servicos`.`dominio` AS `dominio`,`servicos`.`status` AS `status`,`servicos`.`action` AS `action`,`servicos`.`inicio` AS `inicio`,`servicos`.`fim` AS `fim`,`servicos`.`vencimento` AS `vencimento`,`servicos`.`proximo` AS `proximo`,(select `servidores`.`nome` AS `nome` from `servidores` where (`servidores`.`id` = `servicos`.`servidor`)) AS `servidor`,`servicos`.`useracc` AS `useracc`,`planos`.`nome` AS `nome`,`planos`.`descricao` AS `descricao`,`planos`.`tipo` AS `tipo`,`planos`.`plataforma` AS `plataforma`,`pagamento`.`nome` AS `pagamento`,`planos`.`setup` AS `setup`,`planos`.`valor` AS `valor`,`planos`.`valor_tipo` AS `valor_tipo`,`servicos`.`desconto` AS `desconto`,`servicos`.`invoice` AS `invoice`,`servicos`.`envios` AS `envios`,`servicos`.`def` AS `def`,`pagamento`.`primeira` AS `primeira`,`pagamento`.`intervalo` AS `intervalo`,`pagamento`.`parcelas` AS `parcelas` from ((`servicos` join `planos` on((`servicos`.`servicos` = `planos`.`servicos`))) join `pagamento` on((`servicos`.`pg` = `pagamento`.`id`))) */;

--
-- Final view structure for view `v2_servicos`
--

/*!50001 DROP TABLE `v2_servicos`*/;
/*!50001 DROP VIEW IF EXISTS `v2_servicos`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v2_servicos` AS select `servicos`.`id` AS `id`,`servicos`.`username` AS `username`,`servicos`.`dominio` AS `dominio`,`servicos`.`servicos` AS `servicos`,`servicos`.`status` AS `status`,`servicos`.`inicio` AS `inicio`,`servicos`.`fim` AS `fim`,`servicos`.`vencimento` AS `vencimento`,`servicos`.`proximo` AS `proximo`,`servicos`.`servidor` AS `servidor`,`servicos`.`dados` AS `dados`,`servicos`.`useracc` AS `useracc`,`servicos`.`pg` AS `pg`,`servicos`.`envios` AS `envios`,`servicos`.`def` AS `def`,`servicos`.`action` AS `action`,`servicos`.`invoice` AS `invoice`,`servicos`.`pagos` AS `pagos`,`servicos`.`desconto` AS `desconto`,`servicos`.`lock` AS `lock`,`servicos`.`parcelas` AS `parcelas`,`pagamento`.`intervalo` AS `intervalo`,`planos`.`tipo` AS `tipo`,(case `planos`.`valor_tipo` when _utf8'M' then 30 when _utf8'A' then 360 else 1 end) AS `valor_tipo`,((`planos`.`valor` * (`pagamento`.`intervalo` / (case `planos`.`valor_tipo` when _utf8'M' then 30 when _utf8'A' then 360 else 1 end))) - if((`servicos`.`desconto` > 0),ifnull(`servicos`.`desconto`,0),ifnull(`descontos`.`valor`,0))) AS `parcela` from (((`servicos` join `planos` on((`servicos`.`servicos` = `planos`.`servicos`))) left join `descontos` on(((`servicos`.`servicos` = `descontos`.`plano`) and (`servicos`.`pg` = `descontos`.`pg`)))) left join `pagamento` on((`servicos`.`pg` = `pagamento`.`id`))) having (`parcela` >= 0.01) */;

--
-- Final view structure for view `v3_servicos`
--

/*!50001 DROP TABLE `v3_servicos`*/;
/*!50001 DROP VIEW IF EXISTS `v3_servicos`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50001 VIEW `v3_servicos` AS select `servicos`.`id` AS `id`,`servicos`.`username` AS `username`,`servicos`.`dominio` AS `dominio`,`planos`.`tipo` AS `tipo`,`planos`.`plataforma` AS `plataforma`,`planos`.`servicos` AS `plano`,`planos`.`nome` AS `plano_nome`,`servicos`.`status` AS `status`,`servicos`.`inicio` AS `inicio`,`servicos`.`fim` AS `fim`,`servicos`.`vencimento` AS `vencimento`,`servicos`.`proximo` AS `proximo`,`servidores`.`id` AS `servidor`,`servidores`.`nome` AS `servidor_nome`,`servicos`.`dados` AS `dados`,`servicos`.`useracc` AS `useracc`,`pagamento`.`id` AS `pg`,`pagamento`.`nome` AS `pg_nome`,`servicos`.`envios` AS `envios`,`servicos`.`def` AS `def`,`servicos`.`action` AS `action`,`servicos`.`invoice` AS `invoice`,`servicos`.`pagos` AS `pagos`,`servicos`.`desconto` AS `desconto`,`servicos`.`lock` AS `lock`,`servicos`.`parcelas` AS `parcelas` from (((`servicos` join `planos` on((`servicos`.`servicos` = `planos`.`servicos`))) join `pagamento` on((`servicos`.`pg` = `pagamento`.`id`))) left join `servidores` on((`servidores`.`id` = `servicos`.`servidor`))) */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-09-21 12:02:25
