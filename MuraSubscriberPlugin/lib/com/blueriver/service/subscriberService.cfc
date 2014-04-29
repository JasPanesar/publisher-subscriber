<cfcomponent output="false" extends="Service">

	<cfset variables.subscriberDAO = "" />
	
	<cffunction name="setSubscriberDAO" access="public" returntype="void" output="false">
		<cfargument name="subscriberDAO" type="any" required="true" />
		<cfset variables.subscriberDAO = arguments.subscriberDAO />
	</cffunction>
	<cffunction name="getSubscriberDAO" access="public" returntype="any" output="false">
		<cfreturn variables.subscriberDAO />
	</cffunction>

	<cffunction name="readByPublisherProxyURL" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfreturn getSubscriberDAO().readByPublisherProxyURL( argumentCollection:arguments ) />
	</cffunction>

	<cffunction name="transpose" access="public" returntype="string" output="false">
		<cfargument name="list" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		<cfargument name="transposeType" type="string" required="true" />
		<cfargument name="excludeMissingKeys" type="boolean" required="false" default="true" />
		
		<cfset var local = structNew() />
		<cfset var local.transposedList = "" />
		<cfset var local.bean = "" />
		
		<!--- UGLY: but we need to use the right bean in order to continue --->
		<cfswitch expression="#arguments.transposeType#">
		
			<cfcase value="category">
				<cfset local.bean = application.categoryManager.getBean() />
				<cfset local.idKey = "categoryId" />
			</cfcase>
		
			<cfcase value="feed">
				<cfset local.bean = application.feedManager.getBean() />
				<cfset local.idKey = "feedId" />
			</cfcase>
			
			<cfdefaultcase>
				<cfset local.bean = application.contentManager.getBean() />
				<cfset local.idKey = "contentId" />
			</cfdefaultcase>
		
		</cfswitch>
		
		<!--- loop over contentId list --->
		<cfloop list="#arguments.list#" index="local.id">
			
			<!--- check to see if the remote id exists locally --->
			<cfset local.bean.loadBy(
				remoteId: local.id,
				siteId: arguments.siteId
			) />
			
			<!--- default the transposed value to N/A --->
			<cfset local.transposedValue = "___N/A___" />
			<!--- only get transposed contentid if the bean is not new (record persists) --->
			<cfif NOT local.bean.getValue( "isNew" )>
				<cfset local.transposedValue = local.bean.getValue( local.idKey ) />
			</cfif>
			
			<cfif (arguments.excludeMissingKeys AND local.transposedValue IS "___N/A___")>
			<cfelse>
				<!--- append the value to the transposed list --->
				<cfset local.transposedList = listAppend( local.transposedList, local.transposedValue ) />	
			</cfif>
			
		</cfloop>
		
		<!--- return transposed list --->
		<cfreturn local.transposedList />
	</cffunction>

	<cffunction name="localNewRequest" access="public" returntype="any" output="false">
		<cfargument name="builderType" type="string" required="true" />
		<cfargument name="publisherId" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" />
		<cfargument name="remoteParentId" type="string" required="true" />
		<cfargument name="remoteSiteId" type="string" required="true" />
		<cfargument name="topId" type="string" required="true" />
		
		<cfset var local = structNew() />
		
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- trigger this as a refresh --->
		<!--- this should only happen if the parent is requesting the refresh --->
		<!--- <cfset arguments.isParentRefresh = true /> --->
		<!--- we want to force the update since the admin requested it --->
		<cfset arguments.forceRequest = true />
		
		<!--- get the publisher URL --->
		<cfset local.publisher = local.subscriberDAO.readById( arguments.publisherId ) />
		<cfset arguments.publisherProxyURL = local.publisher.get( 'publisherProxyURL' ) />

		<!--- ask to make request --->
		<cfset newRequest( argumentCollection:arguments ) />
		
		<!--- route back to appropriate location --->
		<cflocation url="/admin/index.cfm?fuseaction=cArch.list&siteid=#arguments.subScriberSiteId#&topid=#arguments.topId#&moduleid=00000000000000000000000000000000000" addtoken="true" />
	</cffunction>
	<cffunction name="newRequest" access="public" returntype="any" output="false">
		<cfargument name="builderType" type="string" required="true" />
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" />
		<cfargument name="remoteParentId" type="string" required="true" />
		<cfargument name="remoteSiteId" type="string" required="true" />
		<cfargument name="localSiteId" type="string" required="false" default="" />
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />
		
		<cfset var local = structNew() />
		
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get builderService --->
		<cfset local.builderService = local.subscriberPlugin.getApplication().getValue( property:"builderService", autowire:true ) />
		
		<!--- ***************************************** --->
		<!--- CALL FOR THE BUILDER --->
		<!--- ***************************************** --->
		<!--- builds and stuff the proper bean type based on the type string passed --->
		<cfset local.bean = local.builderService.build( argumentCollection:arguments ) />
	</cffunction>

	<!--- *************************************** --->
	<!--- FETCH CALL ( VERY LOOSE AOP... IF YOU WANT TO CALL IT THAT ) --->
	<!--- *************************************** --->
	<cffunction name="cacheFetch" access="public" returntype="any" output="false">
		<cfargument name="fetchMethod" type="string" required="true" />
		<cfargument name="key" type="string" required="true" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
		
		<cfset var local = structNew() />
		
		<!--- LOG --->				
		<cfdump var="Cache size: #structCount( arguments.tempCache )#" output="console" />		
		<cfdump var="Cache key: #arguments.key#" output="console" />
		
		<cfif NOT structKeyExists( arguments.tempCache, hash( arguments.key, "MD5" ) )>
			<!--- LOG --->
			<cfdump var="Data cached" output="console" />
							
			<cfinvoke component="#this#" method="#arguments.fetchMethod#" argumentcollection="#arguments#" returnvariable="local.results" />
			
			<!--- if cache is on, then cache results --->
			<cfif getPluginConfig().getSetting( "doCache" ) IS "Yes"> 
				<cfset arguments.tempCache[ hash( arguments.key, "MD5" ) ] = local.results />
			</cfif>
		<cfelse>
			<!--- LOG --->
			<cfdump var="Data pulled from cached" output="console" />
								
			<cfset local.results = arguments.tempCache[ hash( arguments.key, "MD5" ) ] />
		</cfif>
		
		<!--- since the results could be complex (struct) we don't want to pass that back in case data changes later on --->
		<!--- instead we pass over the original value each time --->
		<cfreturn duplicate( local.results ) />
		
	</cffunction>

	<!--- *************************************** --->
	<!--- REMOTE CALLS --->
	<!--- *************************************** --->
	<!--- *************************************** --->
	<!--- CONTENT BEAN --->
	<!--- *************************************** --->
	<cffunction name="fetchRemoteData" access="public" returntype="any" output="false">
		<cfargument name="bean" type="any" required="true" />
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />
	
		<cfset var local = structNew() />
		<cfset local.webserviceResults = structNew() />
		<cfset local.webserviceResults.bean = structNew() />
		
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.builderService = local.subscriberPlugin.getApplication().getValue( property:"builderService", autowire:true ) />
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
								
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- throw an error if the publisher is disabled or does not exist --->
		<cfif local.publisher.get( "isNew" ) OR NOT local.publisher.get( "enabled" )>
			<cfreturn "ERROR: Publisher disabled or does not exist" />
		</cfif>
	
		<!--- only attempt to update the page if set to auto-update or the update is forced --->
		<cfif 
			listFindNoCase( "Component,Form,File", arguments.bean.getType() )
			OR arguments.bean.getValue( "autoUpdateSubscriberPage" ) IS "Yes" 
			OR arguments.forceRequest 
			OR arguments.bean.getValue( "IsNew" ) IS "Yes">
			
			<!--- *************************************** --->
			<!--- REMOTE LOGIN --->
			<!--- *************************************** --->
			<!--- get content from publisher --->
			<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
				method="login"
				returnVariable="local.login">
				<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
				<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
				<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
			</cfinvoke>
			
			<!--- *************************************** --->
			<!--- REMOTE CONTENT BEAN REQUEST --->
			<!--- *************************************** --->
			<!--- get data from mura proxy --->
			<cfset local.webserviceArgs = structNew() />
			<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
			<cfset local.webserviceArgs.contentId = arguments.id />
			<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
				method="call"
				returnVariable="local.webserviceResults">
				<cfinvokeargument name="serviceName" value="publisher">
				<cfinvokeargument name="methodName" value="read">
				<cfinvokeargument name="authToken" value="#local.login#">
				<cfinvokeargument name="args" value="#local.webserviceArgs#">
			</cfinvoke>	
								
		</cfif>		
		
		<cfreturn local.webserviceResults />
	</cffunction>
	<!--- *************************************** --->
	<!--- CATEGORIES --->
	<!--- *************************************** --->
	<cffunction name="fetchContentCategoryData" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		
		<cfset var local = structNew() />
			
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- ************************************ --->
		<!--- REMOTE LOGIN --->
		<!--- ************************************ --->
		<!--- get content from publisher --->
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
		</cfinvoke>
		
		<!--- *************************************** --->
		<!--- REMOTE CATEGORY REQUEST --->
		<!--- *************************************** --->						
		<!--- get data from mura proxy --->
		<cfset local.webserviceArgs = structNew() />
		<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfset local.webserviceArgs.contentId = arguments.id />

		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getCategories">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.webserviceArgs#">
		</cfinvoke>	
		
		<cfreturn local.webserviceResults />
	</cffunction>
	<cffunction name="fetchCategoryData" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="categoryId" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		
		<cfset var local = structNew() />
				
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- ************************************ --->
		<!--- REMOTE LOGIN --->
		<!--- ************************************ --->
		<!--- get content from publisher --->
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
		</cfinvoke>
		
		<!--- *************************************** --->
		<!--- REMOTE CATEGORY REQUEST --->
		<!--- *************************************** --->						
		<!--- get data from mura proxy --->
		<cfset local.webserviceArgs = structNew() />
		<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfset local.webserviceArgs.categoryId = arguments.categoryId />
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getCategory">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.webserviceArgs#">
		</cfinvoke>	
		
		<cfreturn local.webserviceResults />
	</cffunction>
	<!--- *************************************** --->
	<!--- DISPLAY OBJECTS --->
	<!--- *************************************** --->
	<cffunction name="fetchContentDisplayRegionData" access="public" returntype="any" output="false">
		<cfargument name="regionNum" type="numeric" required="true" />
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		
		<cfset var local = structNew() />
			
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- ************************************ --->
		<!--- REMOTE LOGIN --->
		<!--- ************************************ --->
		<!--- get content from publisher --->
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
		</cfinvoke>
		
		<!--- *************************************** --->
		<!--- REMOTE DISPLAY OBJECT REQUEST --->
		<!--- *************************************** --->						
		<!--- get data from mura proxy --->
		<cfset local.webserviceArgs = structNew() />
		<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfset local.webserviceArgs.contentId = arguments.id />
		<cfset local.webserviceArgs.regionNum = arguments.regionNum />
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getDisplayRegion">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.webserviceArgs#">
		</cfinvoke>	
		
		<cfreturn local.webserviceResults />
	</cffunction>
	<!--- *************************************** --->
	<!--- KIDS --->
	<!--- *************************************** --->
	<cffunction name="fetchRemoteKidsData" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		
		<cfset var local = structNew() />
				
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- ************************************ --->
		<!--- REMOTE LOGIN --->
		<!--- ************************************ --->
		<!--- get content from publisher --->
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
		</cfinvoke>
		
		<!--- ************************************ --->
		<!--- GET KIDS --->
		<!--- ************************************ --->
		<!--- get data from mura proxy --->
		<cfset local.webserviceArgs = structNew() />
		<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfset local.webserviceArgs.contentId = arguments.id />
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="call"
			returnVariable="local.webserviceKidsResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getKids">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.webserviceArgs#">
		</cfinvoke>
		
		<cfreturn local.webserviceKidsResults />
	</cffunction>
	
	<!--- *************************************** --->
	<!--- FEED --->
	<!--- *************************************** --->
	<cffunction name="fetchFeedData" access="public" returntype="any" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		
		<cfset var local = structNew() />
				
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get subscriberDAO --->
		<cfset local.subscriberDAO = local.subscriberPlugin.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- ************************************ --->
		<!--- REMOTE LOGIN --->
		<!--- ************************************ --->
		<!--- get content from publisher --->
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
		</cfinvoke>
		
		<!--- *************************************** --->
		<!--- REMOTE CATEGORY REQUEST --->
		<!--- *************************************** --->						
		<!--- get data from mura proxy --->
		<cfset local.webserviceArgs = structNew() />
		<cfset local.webserviceArgs.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfset local.webserviceArgs.feedId = arguments.id />
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getFeed">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.webserviceArgs#">
		</cfinvoke>	
		
		<cfreturn local.webserviceResults />
	</cffunction>

</cfcomponent>