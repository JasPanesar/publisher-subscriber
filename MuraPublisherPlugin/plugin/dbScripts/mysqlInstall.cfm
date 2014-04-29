<cfoutput>
DROP TABLE IF EXISTS `p#variables.config.getPluginID()#_registrars`;
CREATE TABLE `p#variables.config.getPluginID()#_registrars` (
  `id` varchar(35) NOT NULL,
  `subscriberId` varchar(35) NOT NULL,
  `subscriberURL` varchar(255) NOT NULL,
  `status` varchar(50) NOT NULL default 'not approved',
  `statusUpdateDate` datetime NOT NULL default '0000-00-00 00:00:00',
  `requestDate` datetime NOT NULL default '0000-00-00 00:00:00',	
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
</cfoutput>