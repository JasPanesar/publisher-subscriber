<cfcomponent output="false">

	<cfset variables.config=""/>
	<cfset variables.validPublisherTypes = "Page,Folder" />
	
	<cffunction name="init" returntype="any" access="public" output="false">
		<cfargument name="config"  type="any" default="">
		<cfset variables.config = arguments.config>
	</cffunction>
	
	<cffunction name="install" returntype="void" access="public" output="false">
		
		<cfset var sql = "">
		<cfset var x = "">
		<cfset var aSql = "">
		
		<cfset configure() />
		
        <cfif application.configBean.getDBType() eq "mysql">
            
			<cfsavecontent variable="sql">
                <cfinclude template="./dbScripts/mysqlInstall.cfm">
            </cfsavecontent>
			
            <cfset aSql = ListToArray(sql, ';')>
    
            <cfloop index="x" from="1" to="#arrayLen(aSql)#">
                <cfif len(trim(aSql[x]))>
	                <cfquery datasource="#application.configBean.getDatasource()#">
	                    #keepSingleQuotes(aSql[x])#
	                </cfquery>
				</cfif>
            </cfloop>
            
        <cfelseif application.configBean.getDBType() eq "mssql">
        	
			<cfsavecontent variable="sql">
                <cfinclude template="./dbScripts/mssqlInstall.cfm">
            </cfsavecontent>
    
            <cfquery datasource="#application.configBean.getDatasource()#">
                #keepSingleQuotes(sql)#
            </cfquery>
            
        <cfelse>
        	<h1>Only MySQL and Microsoft SQL Server are supported.</h1>
        	<cfabort>
        </cfif>
		
	</cffunction>
	
	<cffunction name="update" returntype="void" access="public" output="false">
		<cfset configure() />
	</cffunction>
	
	<cffunction name="delete" returntype="void" access="public" output="false">

	</cffunction>

	<!--- ************************** PRIVATE ************************** --->

	<cffunction name="configure" returntype="void" access="private" output="false">
	
		<cfset var local = structNew() />
		<cfset local.assignedSiteQry = variables.config.getAssignedSites() />
		<cfset local.subType = "" />
		<cfset local.extendSet = "" />
	
		<!--- reinit the application --->
		<cfset application.appInitialized=false />
	
		<!--- loop over siteId's --->
		<cfloop query="local.assignedSiteQry">
		
			<!--- loop over the valid publisher types --->
			<cfloop list="#variables.validPublisherTypes#" index="local.type">
			
				<!--- add in Default subtype --->
				<cfset local.subType = saveSubType( 
										local.assignedSiteQry.siteId,
										local.type, 
										"Default" 
									) />
				
				<!--- add in default extendset --->
				<cfset local.extendSet = saveExtendSet( 
										local.subType, 
										"Mura Publisher" 
									) />
										
				<!--- add attributes --->
				<cfset saveAttribute( 
							extendSet: local.extendSet, 
							name: "activePublisherPage",
							label: "Active",
							type: "RadioGroup",
							optionList: "No^Yes",
							optionLabelList: "No^Yes",
							defaultValue: "No"
						) />
						
				<!--- add attributes --->
					<cfset saveAttribute( 
							extendSet: local.extendSet, 
							name: "publisherOverrideChildrenToActive",
							label: "Publish all children? (overrides child settings)",
							type: "RadioGroup",
							optionList: "No^Yes",
							optionLabelList: "No^Yes",
							defaultValue: "Yes"
						) />
						
			</cfloop>
					
		</cfloop>	
	
	</cffunction>

	<cffunction name="keepSingleQuotes" returntype="string" output="false">
		<cfargument name="str">
		<cfreturn preserveSingleQuotes(arguments.str)>
	</cffunction>

	<cffunction name="saveSubType" returntype="any" access="private" output="false">
		<cfargument name="siteId" type="string" required="true" />
		<cfargument name="typeName" type="string" required="true" />
		<cfargument name="subTypeName" type="string" required="true" />
		
		<!--- create a new subType --->
		<cfset subType = application.classExtensionManager.getSubTypeBean() />
		<cfset subType.setType( arguments.typeName ) />
		<cfset subType.setSubType( arguments.subTypeName ) />
		<cfset subType.setSiteId( arguments.siteId ) />
		<!--- we load the subType in case it already exists --->
		<cfset subType.load() />
		<!--- save the subType --->
		<cfset subType.save() />
		
		<!--- return the subtype --->
		<cfreturn subType />
	</cffunction>
	<cffunction name="saveExtendSet" returntype="any" access="private" output="false">
		<cfargument name="subType" type="any" required="true" />
		<cfargument name="extendSetName" type="string" required="true" />
		
		<!--- get the extend set. this is automatically created for every subType --->
		<cfset var extendSet = arguments.subType.getExtendSetByName( arguments.extendSetName ) />
		<!--- save the extendset --->
		<cfset extendSet.save() />
		
		<cfreturn extendSet />
	</cffunction>
	<cffunction name="saveAttribute" returntype="void" access="private" output="false">
		<cfargument name="extendSet" type="any" required="true" />
		<cfargument name="name" type="any" required="true" />
	
		<cfset var attribute = arguments.extendSet.getAttributeByName( arguments.name ) />
		
		<!--- pass in the arguments so they can be set to the attribute bean --->	
		<cfset attribute.set( arguments ) />
		
		<!--- save the attribute --->
		<cfset attribute.save() />
	
	</cffunction>

</cfcomponent>
