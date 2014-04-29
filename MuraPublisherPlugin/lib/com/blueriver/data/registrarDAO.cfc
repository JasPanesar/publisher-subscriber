<cfcomponent output="false" extends="DAO">

	<cfset variables.configBean = application.configBean />
	<cfset variables.dsn=application.configBean.getDatasource() />

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction name="save" access="public" returntype="void" output="false">
		<cfargument name="registrar" type="any" required="true" />
		
		<!--- if it's new then add --->
		<!--- otherwise update --->
		<cfif registrar.get( "isNew" )>
		
			<!--- insert record --->
			<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				INSERT INTO p#getPluginConfig().getPluginId()#_registrars
					(
						id,
						subscriberId,
						subscriberURL,
						status,
						statusUpdateDate,
						requestDate
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#createUUID()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#registrar.get( 'subscriberID' )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( registrar.get( 'subscriberURL' ) )#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#registrar.get( 'status' )#" />,
						<cfqueryparam cfsqltype="cf_sql_date" value="#now()#" />,
						<cfqueryparam cfsqltype="cf_sql_date" value="#now()#" />
					)
			</cfquery>
			
			<!--- set that the registrar is not new --->
			<cfset arguments.registrar.set( "isNew", false ) />
		<cfelse>	
			
			<!--- update record --->
			<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				UPDATE p#getPluginConfig().getPluginId()#_registrars SET
					subscriberId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#registrar.get( 'subscriberID' )#" />,
					subscriberURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim( registrar.get( 'subscriberURL' ) )#" />,
					status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#registrar.get( 'status' )#" />,
					statusUpdateDate = <cfqueryparam cfsqltype="cf_sql_date" value="#now()#" />
				WHERE
					id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#registrar.get( 'id' )#" />
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
				p#getPluginConfig().getPluginId()#_registrars
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
	<cffunction name="readBySubscriberURL" access="public" returntype="any" output="false">
		<cfargument name="subscriberURL" type="string" required="true" />
		
		<cfset var results = "" />
		<cfset var bean = new() />
		
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" name="results" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			SELECT
				*
			FROM
				p#getPluginConfig().getPluginId()#_registrars
			WHERE
				subscriberURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.subscriberURL#" />
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
				p#getPluginConfig().getPluginId()#_registrars
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
				p#getPluginConfig().getPluginId()#_registrars
			WHERE
				status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.status#" />
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
		<cfargument name="registrar" type="any" required="true" />
		
		<!--- query the database --->
		<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			DELETE FROM p#getPluginConfig().getPluginId()#_registrars
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.registrar.get( 'id' )#" />
		</cfquery>
		
	</cffunction>

</cfcomponent>