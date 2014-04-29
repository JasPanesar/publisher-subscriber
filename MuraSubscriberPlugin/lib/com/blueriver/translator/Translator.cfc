<cfcomponent output="false">

	<cfset variables.subscriberService = "" />

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction name="setSubscriberService" access="public" returntype="void" output="false">
		<cfargument name="subscriberService" type="any" required="true" />
		<cfset variables.subscriberService = arguments.subscriberService />
	</cffunction>
	<cffunction name="getSubscriberService" access="public" returntype="any" output="false">
		<cfreturn variables.subscriberService />
	</cffunction>

	<cffunction name="translate" access="public" returntype="void" output="false">
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<!--- GLOBAL SCRUB --->
		<cfset structDelete( arguments.data, "remoteId" ) />
		<cfset structDelete( arguments.data, "remoteURL" ) />
		<cfset structDelete( arguments.data, "remoteSourceURL" ) />
		<cfset structDelete( arguments.data, "siteId" ) />
		
		<!--- if a bean structure is passed then clean it up --->
		<cfif isDefined( "arguments.data.bean" )>
			<cfset structDelete( arguments.data.bean, "remoteId" ) />
			<cfset structDelete( arguments.data.bean, "remoteURL" ) />
			<cfset structDelete( arguments.data.bean, "remoteSourceURL" ) />
			<cfset structDelete( arguments.data.bean, "siteId" ) />
		</cfif>
		
	</cffunction>

</cfcomponent>