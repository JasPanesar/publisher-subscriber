<cfcomponent output="false">

	<cfset variables.instance = structNew() />

	<cffunction name="init" access="public" returntype="Bean" output="false">
		
		<cfif isDefined( "arguments" )>
			<cfset setValues( arguments ) />
		</cfif>
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="dump" access="public" returntype="struct" output="false">
		<cfreturn variables.instance />
	</cffunction>
	
	<cffunction name="set" access="public" returntype="void" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="value" type="any" required="true" />
		<cfset variables.instance[arguments.key] = arguments.value />
	</cffunction>
	<cffunction name="setValues" access="public" returntype="void" output="false">
		<cfargument name="collection" type="any" required="true" />
		<cfset var key = "" />
		<cfif isQuery( arguments.collection )>
			<cfloop list="#arguments.collection.columnList#" index="local.column">
				<cfset variables.instance[local.column] = arguments.collection[local.column][1] />
			</cfloop>
		<cfelse>
			<cfloop collection="#arguments.collection#" item="key">
				<cfset variables.instance[key] = arguments.collection[key] />
			</cfloop>
		</cfif>
	</cffunction>
	<cffunction name="get" access="public" returntype="any" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="default" type="any" required="false" default="" />
		<cfif structKeyExists( variables.instance, arguments.key )>
			<cfreturn variables.instance[arguments.key] />
		</cfif>
		<cfreturn arguments.default />
	</cffunction>
	
	<cffunction name="has" access="public" returntype="boolean" output="false">
		<cfargument name="key" type="string" required="true" />
		<cfif structKeyExists( variables.instance, arguments.key )>
			<cfreturn true />
		</cfif>
		<cfreturn false />
	</cffunction>

</cfcomponent>