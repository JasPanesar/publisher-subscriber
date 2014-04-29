<cfcomponent output="false" extends="Service">

	<cfset variables.subscriberService = "" />
	
	<cffunction name="setSubscriberService" access="public" returntype="void" output="false">
		<cfargument name="subscriberService" type="any" required="true" />
		<cfset variables.subscriberService = arguments.subscriberService />
	</cffunction>
	<cffunction name="getSubscriberService" access="public" returntype="any" output="false">
		<cfreturn variables.subscriberService />
	</cffunction>

	<cffunction name="translate" access="public" returntype="void" output="false">
		<cfargument name="translatorType" type="string" required="true" />
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<cfset var local = structNew() />
		
		<!--- get the bean type --->
		<!--- get meta data --->
		<!---
		<cfset local.meta = getMetadata( arguments.bean ) />
		<!--- get the class name --->
		<cfset local.className = listLast( local.meta.name, "." ) />
		--->
		
		<!--- ****************************************** --->
		<!--- BUILD THE TRANSLATOR AND TRANSLATE --->
		<!--- ****************************************** --->			
		<!--- attempt to create the translator --->
		<cftry>
			<cfset local.translator = createObject( "component", "plugins.#getPluginConfig().getDirectory()#.lib.com.blueriver.translator.#arguments.translatorType#Translator" ).init() /> 
			<cfcatch>
				<cfrethrow />
				<cfset local.translator = createObject( "component", "plugins.#getPluginConfig().getDirectory()#.lib.com.blueriver.translator.Translator" ).init() />
			</cfcatch>
		</cftry>
		
		<!--- pass the subscriber service to the translator --->
		<cfset local.translator.setSubscriberService( getSubscriberService() ) />
		
		<!--- translate the bean --->
		<cfset local.translator.translate( argumentCollection:arguments ) />
	</cffunction>

</cfcomponent>