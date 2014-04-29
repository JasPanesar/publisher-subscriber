<cfcomponent extends="mura.plugin.pluginGenericEventHandler">

	<cffunction name="onApplicationLoad" output="false" returntype="any">
		<cfargument name="event" /> 
		
		<cfset var libPackage = structNew() />
		
		<!--- push components into the plugin memory scope --->
		<cfset pluginConfig.getApplication().setValue( "libPackage", libPackage ) />
		
		<!--- create components and store them into memory for later use --->
		<cfset libPackage.proxy = createObject( "component", "plugins.#pluginConfig.getDirectory()#.proxy" ) />
		
		<cfdump var="#now()#" output="console" />
		
		<!--- publisher/subscriber specific --->
		<cfset libPackage.registrarDAO = createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.com.blueriver.data.registrarDAO" ).init() />			
		<cfset libPackage.registrarDAO.setPluginConfig( pluginConfig ) />
					
		<!--- TODO: this should be setup upon application reload for Mura --->
		<cfif not structKeyExists(application,"proxyServices")>
			<cfset application.proxyServices=structNew()>
		</cfif>
		
		<!--- injet the publisher service into the application proxy service if it's not available --->
		<!--- TODO: might need to consider how this will work when there are multiple publishers installed onto one system --->
		<cfset application.proxyServices["publisher"]=createObject("component","plugins.#pluginConfig.getDirectory()#.lib.proxy.publisher").init()>
		
		<cfset variables.pluginConfig.addEventHandler(this)>
	</cffunction>

	<!--- ******************************************************* --->
	<!--- CATEGORY LOGIC --->
	<!--- ******************************************************* --->
	<cffunction name="onCategorySave" output="false" returntype="any">
		<cfargument name="event" />
		<cfset triggerSave( "category", event.getValue( "categoryBean" ) ) />
	</cffunction>

	<!--- ******************************************************* --->
	<!--- FEED LOGIC --->
	<!--- ******************************************************* --->
	<cffunction name="onFeedSave" output="false" returntype="any">
		<cfargument name="event" />
		<cfset triggerSave( "feed", event.getValue( "feedBean" ) ) />
	</cffunction>

	<!--- ******************************************************* --->
	<!--- CONTENT LOGIC --->
	<!--- ******************************************************* --->
	<cffunction name="onAfterContentSave" output="false" returntype="any">
		<cfargument name="event" />
		
		<!--- only run if set to active --->
		<cfif NOT event.valueExists( "preventEventRefire" )
			AND
			(
				(
				event.getValue( "contentBean" ).hasParent() 
					and event.getValue( "contentBean" ).getParent().getValue( "publisherOverrideChildrenToActive" ) IS "Yes"
					and event.getValue( "contentBean" ).getParent().getValue( "activePublisherPage" ) IS "Yes"
				) 
				OR 
				event.getValue( "contentBean" ).getValue( "activePublisherPage" ) IS "Yes"	
			)>
			
			<cfset triggerSave( "content", event.getValue( "contentBean" ) ) />	
		</cfif>
	
	</cffunction>

	<cffunction name="onAfterComponentSave" output="false" returntype="any">
		<cfargument name="event" />
		
		<!--- TODO: Save auto save components from a per subscription level --->
		<cfset triggerSave( "contentBean", event.getValue( "contentBean" ) ) />
	</cffunction>
	
	<cffunction name="onAfterFormSave" output="false" returntype="any">
		<cfargument name="event" />
		
		<!--- TODO: Save auto save forms from a per subscription level --->
		<cfset triggerSave( "contentBean", event.getValue( "contentBean" ) ) />
	</cffunction>

	<!--- ******************************************************* --->
	<!--- PRIVATE --->
	<!--- ******************************************************* --->
	<cffunction name="triggerSave" access="private" output="false" returntype="any">
		<cfargument name="beanType" type="string" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<cfset var attributes = structNew()>
		<cfset attributes.beanType = arguments.beanType>
		<cfset attributes.bean = arguments.bean>
		<cfset attributes.pluginConfig = pluginConfig>
		
		<!--- loop over registrars --->
		<cfthread name="MuraPublisher#createUUID()#" action="run" beanType="#arguments.beanType#" bean="#arguments.bean#" pluginConfig="#pluginConfig#">
				
			<!--- loop over subscribers --->
			<cfset var local = structNew() />
			
			<!--- get the lib package that has been pushed to the plugin application scope --->
			<cfset local.libPackage = attributes.pluginConfig.getApplication().getValue( "libPackage" ) />
			
			<!--- read out registrars --->
			<cfset local.approvedRegistrarsQry = local.libPackage.registrarDAO.listByStatus( "approved" ) />
			
			<!--- loop over registrars --->
			<cfloop query="local.approvedRegistrarsQry">
				
				<cftry>
					<cfinvoke 
						method="newRequest"
						returnvariable="local.webserviceResults"
						webservice="#subscriberURL#?wsdl">
						<cfinvokeargument name="builderType" value="#attributes.beanType#" />
						<cfinvokeargument name="publisherProxyURL" value="#local.libPackage.proxy.buildMuraURLByCGI()#plugins/#attributes.pluginConfig.getDirectory()#/proxy.cfc" />
						<cfinvokeargument name="subscriberId" value="#subscriberID#" />
						<cfinvokeargument name="remoteId" value="#attributes.bean.getValue( 'contentId' )#" />
						<cfinvokeargument name="remoteParentId" value="#attributes.bean.getValue( 'parentId' )#" />
						<cfinvokeargument name="remoteSiteId" value="#attributes.bean.getValue( 'siteId' )#" />
						<!--- <cfinvokeargument name="isParentRefresh" value="false" /> --->
						<cfinvokeargument name="forceRequest" value="false" />
					</cfinvoke>
					
					<cfcatch>
						
						<!--- capture error --->
						<cfsavecontent variable="local.errorDump">SUBSCRIBER: <cfoutput>#subscriberURL#</cfoutput><br /><cfdump var="#cfcatch#" /></cfsavecontent>
						<!--- ammend to log --->
						<cffile action="write" file="#getDirectoryFromPath( getCurrentTemplatePath() )#/../log/error_#getTickCount()#.html" output="#local.errorDump#" />
						
					</cfcatch>
				</cftry>
			</cfloop>
			
		</cfthread>
	</cffunction>

</cfcomponent>

