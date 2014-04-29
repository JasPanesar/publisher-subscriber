<cfcomponent output="false" extends="DAO">

	<cfset variables.configBean = application.configBean />
	<cfset variables.dsn=application.configBean.getDatasource() />

	<cffunction name="save" access="public" returntype="void" output="false">
		<cfargument name="subscriber" type="any" required="true" />
		
		<!--- if it's new then add --->
		<!--- otherwise update --->
		<cfif subscriber.get( "isNew" )>
		
			<!--- insert record --->
			<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				INSERT INTO p#getPluginConfig().getPluginId()#_subscriptions
					(
						id,
						publisherName,
						publisherProxyURL,
						publisherMuraProxyURL,
						publisherUsername,
						publisherPassword,
						publisherUserAssignedSiteId,
						enabled,				
						status,
						requestDate
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'id' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherName' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( subscriber.get( 'publisherProxyURL' ) )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( subscriber.get( 'publisherMuraProxyURL' ) )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherUsername' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherPassword' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherUserAssignedSiteId' )#" />,
						<cfqueryparam cfsqltype="cf_sql_bit" value="#subscriber.get( 'enabled' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'status' )#" />,
						<cfqueryparam cfsqltype="cf_sql_date" value="#now()#" />
					)
			</cfquery>
			
			<!--- set that the registrar is not new --->
			<cfset arguments.subscriber.set( "isNew", false ) />
		<cfelse>	
			
			<!--- update record --->
			<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				UPDATE p#getPluginConfig().getPluginId()#_subscriptions SET
					publisherName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherName' )#" />,
					publisherProxyURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( subscriber.get( 'publisherProxyURL' ) )#" />,
					publisherMuraProxyURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( subscriber.get( 'publisherMuraProxyURL' ) )#" />,
					publisherUsername = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherUsername' )#" />,
					publisherPassword = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherPassword' )#" />,
					publisherUserAssignedSiteId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'publisherUserAssignedSiteId' )#" />,
					enabled = <cfqueryparam cfsqltype="cf_sql_bit" value="#subscriber.get( 'enabled' )#" />,
					status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'status' )#" />
				WHERE
					id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#subscriber.get( 'id' )#" /> 
			</cfquery>	
	
		</cfif>
	</cffunction>

	<cffunction name="readById" access="public" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" />
		
		<cfset var results = "" />
		<cfset var bean = new() />
		
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_subscriptions
			WHERE
				id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" />
		</cfquery>
		
		<!--- if a record is not found then setup --->
		<cfif results.recordcount>
			<!--- set the bean --->
			<cfset bean.setValues( results ) />
			<!--- set that the bean is not new --->
			<cfset bean.set( "isNew", false ) />
		</cfif>
		
		<cfreturn bean />
	</cffunction>
	<cffunction name="readByPublisherProxyURL" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		
		<cfset var results = "" />
		<cfset var bean = new() />
		
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_subscriptions
			WHERE
				publisherProxyURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.publisherProxyURL#" />
		</cfquery>
		
		<!--- if a record is not found then setup --->
		<cfif results.recordcount>
			<!--- set the bean --->
			<cfset bean.setValues( results ) />
			<!--- set that the bean is not new --->
			<cfset bean.set( "isNew", false ) />
		</cfif>
		
		<cfreturn bean />
	</cffunction>
	
	<cffunction name="list" access="public" returntype="query" output="false">
	
		<cfset var results = "" />
	
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_subscriptions
		</cfquery>
		
		<cfreturn results />
	</cffunction>
	<cffunction name="listByStatus" access="public" returntype="query" output="false">
		<cfargument name="status" type="string" required="true" />
		
		<cfset var results = "" />
	
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_subscriptions
			WHERE
				status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.status#" />
		</cfquery>
		
		<cfreturn results />
	</cffunction>
	<cffunction name="listByEnabled" access="public" returntype="query" output="false">
		<cfargument name="enabled" type="string" required="true" />
		
		<cfset var results = "" />
	
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_subscriptions
			WHERE
				enabled = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.enabled#" />
		</cfquery>
		
		<cfreturn results />
	</cffunction>
	
	<cffunction name="new" access="public" returntype="any" output="false">
		<cfset var bean = createObject( "component", "bean.Bean" ).init() />
		<cfset bean.set( "id", createUUID() ) />
		<cfset bean.set( "isNew", true ) />
		<cfset bean.set( "status", "not approved" ) />
		<cfreturn bean />
	</cffunction>
	
	<cffunction name="delete" access="public" returntype="void" output="false">
		<cfargument name="subscriber" type="any" required="true" />
		
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			DELETE FROM p#getPluginConfig().getPluginId()#_subscriptions
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.subscriber.get( 'id' )#" />
		</cfquery>
		
	</cffunction>

</cfcomponent>