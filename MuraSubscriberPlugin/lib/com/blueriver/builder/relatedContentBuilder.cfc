<cfcomponent output="false" extends="Builder">

	<cfset variables.acceptedDisplayObjects = "Component,Form" />

	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="true" hint="I am the site ID of the subscriber" />
		<cfargument name="contentBean" type="any" required="true" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
	
		<cfset var local = structNew() />
	
		<!--- LOG --->
		<cfdump var="Gathering Related Content" output="console" />
	
		<cfset local.contentRelatedContentData = getSubscriberService().cacheFetch( 
			fetchMethod: "fetchRemoteData",
			key: arguments.remoteId,
			bean: arguments.contentBean,	
			publisherProxyURL: arguments.publisherProxyURL,
			subscriberId: arguments.subscriberId,
			id: arguments.remoteId,
			siteId: arguments.remoteSiteId,
			tempCache: arguments.tempCache
		) />
		
		<!--- loop over the related content --->
		<cfloop query="local.contentRelatedContentData.relatedContent">
			<!--- 
			check to see if the related content exists .
			if it does then we want to link it up locally
			--->
			<cfset local.bean = application.contentManager.getBean().loadBy( remoteId:"#arguments.remoteSiteId#|#local.contentRelatedContentData.relatedContent.contentId#", siteId:arguments.localSiteId ) />
			<cfif NOT local.bean.getValue( "isNew" )>
				<!--- append related contentId to the list of related content (if doesn't exist in list already) --->
				<cfif NOT listFindNoCase( arguments.contentBean.getValue( "relatedContentId" ), local.bean.getContentId() )>
					<cfset arguments.contentBean.setValue( "relatedContentID", listAppend( arguments.contentBean.getValue( "relatedContentID" ), local.bean.getContentId() ) ) />
				</cfif>
			</cfif>
		</cfloop>
	
	</cffunction>
	
</cfcomponent>