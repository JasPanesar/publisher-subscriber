<cfcomponent output="false">

	<cfset variables.configBean = application.configBean />
	<cfset variables.dsn=application.configBean.getDatasource() />
	<cfset variables.subscriberService = "" />
	<cfset variables.translatorService = "" />
	<cfset variables.builderService = "" />
	
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
	<cffunction name="setTranslatorService" access="public" returntype="void" output="false">
		<cfargument name="translatorService" type="any" required="true" />
		<cfset variables.translatorService = arguments.translatorService />
	</cffunction>
	<cffunction name="getTranslatorService" access="public" returntype="any" output="false">
		<cfreturn variables.translatorService />
	</cffunction>
	<cffunction name="setBuilderService" access="public" returntype="void" output="false">
		<cfargument name="builderService" type="any" required="true" />
		<cfset variables.builderService = arguments.builderService />
	</cffunction>
	<cffunction name="getBuilderService" access="public" returntype="any" output="false">
		<cfreturn variables.builderService />
	</cffunction>
	
	<cffunction name="serializeKey" access="private" returntype="string" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfreturn hash( "#getMetaData(this).name##key#", "MD5" ) />
	</cffunction>
	
	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="bean" type="any" required="true" />
		
	</cffunction>
			
</cfcomponent>