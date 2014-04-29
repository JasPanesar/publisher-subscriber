<cfcomponent output="false" extends="Translator">

	<cffunction name="translate" access="public" returntype="void" output="false">
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<cfset var deepCopy = duplicate( bean.getAllValues() ) />
		
		<!--- GLOBAL SCRUB --->
		<cfset super.translate( argumentCollection:arguments ) />
		
		<!--- transpose the content id's --->
		<cfset arguments.data.bean.contentId = getSubscriberService().transpose( arguments.data.bean.contentId, arguments.bean.getSiteId(), "feed" ) />
		<!--- transpose the category id's --->
		<cfset arguments.data.bean.categoryId = getSubscriberService().transpose( arguments.data.bean.categoryId, arguments.bean.getSiteId(), "category" ) />
					
		<!--- ***************************************** --->
		<!--- SCRUB CONTENT --->
		<!--- ***************************************** --->	
		<!--- IMPORTANT: it's important to really scrub the data before it's inserted into the bean
		otherwise extenedsetid's could be off --->
		<cfset structDelete( arguments.data.bean, "feedId" ) />
		<cfset structDelete( arguments.data.bean, "remotePubDate" ) />
		
		<!--- set the release date --->
		<cfset arguments.bean.setRemotePubDate( arguments.data.bean.lastUpdate ) />
		
		<!--- set the data into the bean --->
		<cfset arguments.bean.set( arguments.data.bean ) />
		
		
	</cffunction>
	
</cfcomponent>