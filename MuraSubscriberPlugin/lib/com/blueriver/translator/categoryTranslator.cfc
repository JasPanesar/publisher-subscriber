<cfcomponent output="false" extends="Translator">

	<cffunction name="translate" access="public" returntype="void" output="false">
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<cfset var deepCopy = duplicate( bean.getAllValues() ) />
			
		<!--- GLOBAL SCRUB --->
		<cfset super.translate( argumentCollection:arguments ) />
		
		<!--- ***************************************** --->
		<!--- SCRUB CONTENT --->
		<!--- ***************************************** --->	
		<!--- IMPORTANT: it's important to really scrub the data before it's inserted into the bean
		otherwise extenedsetid's could be off --->
		<cfset structDelete( arguments.data, "categoryId" ) />
		<cfset structDelete( arguments.data, "remotePubDate" ) />
		
		<!--- set the release date --->
		<cfset arguments.bean.setRemotePubDate( arguments.data.lastUpdate ) />
		
		<!--- set the data into the bean --->
		<cfset arguments.bean.set( arguments.data ) />
		
	</cffunction>
	
</cfcomponent>