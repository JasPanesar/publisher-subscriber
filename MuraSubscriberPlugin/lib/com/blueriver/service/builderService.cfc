<cfcomponent output="false" extends="Service">

	<cfset variables.subscriberService = "" />
	<cfset variables.translatorService = "" />
	
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

	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="builderType" type="string" required="true" hint="I would be one of the mura types (Content, etc)" />
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteParentId" type="string" required="true" hint="If the content id passed has a parent id, then the parent is passed for greater filtering" />
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="false" default="" hint="I am the site ID of the subscriber" />
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />
		<cfargument name="contentBean" type="any" required="false" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
		
		<cfset var local = structNew() />
		
		<!--- ****************************************** --->
		<!--- BUILD THE BUILDER AND BUILD --->
		<!--- ****************************************** --->
		<!--- NOTES:
			1) The translator service is provided to the builder as well as the subscriber service 
		--->
		<!--- attempt to create the builder --->
		<cftry>
			<cfset local.builder = createObject( "component", "plugins.#getPluginConfig().getDirectory()#.lib.com.blueriver.builder.#arguments.builderType#Builder" ).init() /> 
			<cfcatch>
				<cfrethrow />
				<cfset local.builder = createObject( "component", "plugins.#getPluginConfig().getDirectory()#.lib.com.blueriver.builder.Builder" ).init() />
			</cfcatch>
		</cftry>
		
		<!--- pass in the subscriber service for fetch purposes --->
		<cfset local.builder.setSubscriberService( variables.subscriberService ) />
		<!--- pass in the translation service for clean up purposes --->
		<cfset local.builder.setTranslatorService( variables.translatorService ) />
		<!--- pass in this builder service so other builders can use it --->
		<cfset local.builder.setBuilderService( this ) />
		
		<!--- translate the bean --->
		<cfset local.builder.build( argumentCollection:arguments ) />
	</cffunction>

</cfcomponent>