<cfoutput>
DROP TABLE IF EXISTS `p#variables.config.getPluginID()#_subscriptions`;
CREATE TABLE `p#variables.config.getPluginID()#_subscriptions` (
  `id` varchar(35) NOT NULL,
  `publisherName` varchar(255) NOT NULL,
  `publisherProxyURL` varchar(255) NOT NULL,
  `publisherMuraProxyURL` varchar(255) NOT NULL,
  `publisherUsername` varchar(255) NOT NULL,
  `publisherPassword` varchar(255) NOT NULL,
  `publisherUserAssignedSiteId` varchar(255) NOT NULL,
  `enabled` bit NOT NULL default 1,
  `status` varchar(50) NOT NULL default 'not approved',
  `requestDate` datetime NOT NULL default '0000-00-00 00:00:00',	
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
</cfoutput>