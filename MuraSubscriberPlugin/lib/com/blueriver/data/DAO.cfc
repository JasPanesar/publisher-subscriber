<cfcomponent output="false">

	<cffunction name="init" access="public" returntype="any" output="false">
		<cfreturn this />
	</cffunction>

	<cffunction name="setPluginConfig" access="public" returntype="void" output="false">
		<cfargument name="pluginConfig" type="any" required="true" />
		<cfset variables.pluginConfig = arguments.pluginConfig />
	</cffunction>
	<cffunction name="getPluginConfig" access="public" returntype="any" output="false">
		<cfreturn variables.pluginConfig />
	</cffunction>

</cfcomponent>