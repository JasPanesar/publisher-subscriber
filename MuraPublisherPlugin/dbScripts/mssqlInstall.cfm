<cfoutput>
CREATE TABLE [dbo].[p#variables.config.getPluginID()#_registrars] (
	[id] [nvarchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[subscriberId] [nvarchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[subscriberURL] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[status] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[statusUpdateDate] [datetime] NULL ,
	[requestDate] [datetime] NULL
) ON [PRIMARY]
</cfoutput>