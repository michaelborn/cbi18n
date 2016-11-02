<!-----------------------------------------------------------------------
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
----------------------------------------------------------------------->
<cfcomponent name="i18n"
			 hint="Internationalization and localization support for ColdBox"
			 output="false"
			 singleton>

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->

	<cfproperty name="resourceService" 	inject="resourceService@cbi18n">
	<cfproperty name="controller" 		inject="coldbox">

	<cffunction name="init" access="public" returntype="i18n" hint="Constructor" output="false">
		<cfscript>
			// Internal Java Objects
			instance.aDFSymbol		= createObject( "java", "java.text.DecimalFormatSymbols" );
			instance.aDateFormat	= createObject( "java", "java.text.DateFormat" );
			instance.sDateFormat	= createObject( "java", "java.text.SimpleDateFormat" );
			instance.aLocale		= createObject( "java", "java.util.Locale" );
			instance.timeZone		= createObject( "java", "java.util.TimeZone" );
			instance.aCalendar		= createObject( "java", "java.util.GregorianCalendar" ).init( buildLocale() );
			instance.dateSymbols 	= createObject( "java", "java.text.DateFormatSymbols" ).init( buildLocale() );

			// internal settings
			instance.localeStorage 			= "";
			instance.defaultResourceBundle 	= "";
			instance.defaultLocale 			= "";

			return this;
		</cfscript>
	</cffunction>

	<cffunction name="configure" access="public" output="false" hint="Reads,parses,saves the locale and resource bundles defined in the config. Called only internally by the framework. Use at your own risk" returntype="void">
		<cfscript>
			// Default instance settings
			instance.localeStorage 			= variables.controller.getSetting( "LocaleStorage" );
			instance.defaultResourceBundle 	= variables.controller.getSetting( "DefaultResourceBundle" );
			instance.defaultLocale 			= variables.controller.getSetting( "DefaultLocale" );

			// set locale setup on configuration file
			setFWLocale( instance.defaultLocale, true );

			// test for rb file and if it exists load it as the default resource bundle
			if( len( instance.defaultResourceBundle ) ){
				variables.resourceService.loadBundle( rbFile=instance.defaultResourceBundle, rbLocale=instance.defaultLocale, rbAlias="default" );
			}

			// are we loading multiple resource bundles? If so, load up their default locale
			var resourceBundles = variables.controller.getSetting( name="resourceBundles", defaultValue=structNew() );
			if( structCount( resourceBundles ) ){
				for( var thisBundle in resourceBundles ){
					variables.resourceService.loadBundle( rbFile=resourceBundles[ thisBundle ], rbLocale=instance.defaultLocale, rbAlias=lcase( thisBundle ) );
				}
			}
		</cfscript>
	</cffunction>

<!------------------------------------------- STUPID GETTER/SETTERS (CF8 REMOVE BY CB4) ------------------------------------------->

	<cffunction name="getLocaleStorage" access="public" output="false" hint="Get the locale storage string">
		<cfreturn instance.localeStorage>
	</cffunction>
	<cffunction name="getDefaultLocale" access="public" output="false" hint="Get the default locale string">
		<cfreturn instance.defaultLocale>
	</cffunction>
	<cffunction name="getDefaultResourceBundle" access="public" output="false" hint="Get the default resource bundle path">
		<cfreturn instance.defaultResourceBundle>
	</cffunction>
	<cffunction name="getRBundles" access="public" output="false" hint="Get a reference to the loaded language keys" returntype="struct">
		<cfreturn variables.resourceService.getBundles()>
	</cffunction>

	<cffunction name="setLocaleStorage" access="public" output="false" hint="Set the locale storage">
		<cfargument name="localeStorage" required="true">
		<cfset instance.localeStorage = arguments.localeStorage>
		<cfreturn this>
	</cffunction>
	<cffunction name="setDefaultLocale" access="public" output="false" hint="Set the default locale">
		<cfargument name="defaultLocale" required="true">
		<cfset instance.defaultLocale = arguments.defaultLocale>
		<cfreturn this>
	</cffunction>
	<cffunction name="setDefaultResourceBundle" access="public" output="false" hint="Set the default resource bundle">
		<cfargument name="defaultResourceBundle" required="true">
		<cfset instance.defaultResourceBundle = arguments.defaultResourceBundle>
		<cfreturn this>
	</cffunction>

<!------------------------------------------- CHOSEN LOCAL METHODS ------------------------------------------->

	<!--- Discover fw Locale --->
	<cffunction name="getfwLocale" access="public" output="false" returnType="any" hint="Get the user's locale">
		<cfscript>
			var storage = "";

			// locale check
			if ( NOT len(instance.localeStorage) ){
				throw( message="The LocaleStorage setting cannot be found. Please make sure you create the i18n elements.", type="i18N.DefaultSettingsInvalidException" );
			}

			//storage switch
			switch(instance.localeStorage){
				case "session" : { storage = session; break; }
				case "client"  : { storage = client; break;  }
				case "cookie"  : { storage = cookie; break;  }
				case "request" : { storage = request; break; }
			}

			// check if default locale exists, else set it to the default locale.
			if ( not structKeyExists(storage,"DefaultLocale") ){
				setfwLocale(instance.defaultLocale);
			}

			// return locale
			return storage["DefaultLocale"];
		</cfscript>
	</cffunction>

	<!--- set the fw locale for a user --->
	<cffunction name="setfwLocale" access="public" output="false" returnType="any" hint="Set the default locale to use in the framework for a specific user.">
		<!--- ************************************************************* --->
		<cfargument name="locale"     		type="string"  required="false"  default=""   hint="The locale to change and set. Must be Java Style: en_US. If none passed, then we default to default locale from configuration settings">
		<cfargument name="dontloadRBFlag" 	type="boolean" required="false"  default="false" hint="Flag to load the resource bundle for the specified locale (If not already loaded) or just change the framework's locale.">
		<!--- ************************************************************* --->

		<!--- No locale check --->
		<cfif NOT len( arguments.locale )><cfset arguments.locale = instance.defaultLocale></cfif>

		<!--- Storage of the Locale in the user storage --->
		<cfif instance.localeStorage eq "session">
			<cfset session.DefaultLocale = arguments.locale>
		<cfelseif instance.localeStorage eq "client">
			<cfset client.DefaultLocale = arguments.locale>
		<cfelseif instance.localeStorage eq "request">
			<cfset request.DefaultLocale = arguments.locale>
		<cfelse>
			<cfcookie name="DefaultLocale" value="#arguments.locale#" />
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="getFWLocaleDisplay" access="public" output="false" returntype="string" hint="Returns a name for the locale that is appropriate for display to the user. Eg: English (United States)">
       <cfreturn buildLocale(getfwLocale()).getDisplayName()>
	</cffunction>

	<cffunction name="getFWCountry" access="public" output="false" returntype="string" hint="returns a human readable country name for the chosen application locale. Eg: United States">
       <cfreturn buildLocale(getfwLocale()).getDisplayCountry()>
	</cffunction>

	<cffunction name="getFWCountryCode" access="public" output="false" returntype="string" hint="returns 2-letter ISO country name for the chosen application locale. Eg: us">
		<cfreturn buildLocale(getfwLocale()).getCountry()>
	</cffunction>

	<cffunction name="getFWISO3CountryCode" access="public" output="false" returntype="string" hint="returns 3-letter ISO country name for the chosen application locale. Eg: USA">
		<cfreturn buildLocale(getfwLocale()).getISO3Country()>
	</cffunction>

	<cffunction name="getFWLanguage" access="public" output="false" returntype="string" hint="Returns a human readable name for the locale's language. Eg: English">
		<cfreturn buildLocale(getfwLocale()).getDisplayLanguage()>
	</cffunction>

	<cffunction name="getFWLanguageCode" access="public" output="false" returntype="string" hint="Returns the two digit code for the locale's language. Eg: en">
		<cfreturn buildLocale(getfwLocale()).getLanguage()>
	</cffunction>

	<cffunction name="getFWISO3LanguageCode" access="public" output="false" returntype="string" hint="Returns the ISO 3 code for the locale's language. Eg: eng">
		<cfreturn buildLocale(getfwLocale()).getISO3Language()>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->

	<cffunction name="isValidLocale"  access="public" output="false" returntype="boolean" hint="Validate a locale">
		<!--- ************************************************************* --->
		<cfargument name="thisLocale" required="yes" type="string" hint="Locale to validate">
		<!--- ************************************************************* --->
		<cfif listFind(arrayToList(getLocales()),arguments.thisLocale)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>

	<cffunction name="getLocales" access="public" output="false" returntype="array" hint="returns array of locales">
    	<cfreturn instance.aLocale.getAvailableLocales()>
	</cffunction>

	<cffunction name="getLocaleNames" access="public" output="false" returntype="string" hint="returns list of locale names, UNICODE direction char (LRE/RLE) added as required">
	<cfscript>
	       var orgLocales=getLocales();
	       var theseLocales="";
	       var thisName="";
	       var i=0;
	       for (i=1; i LTE arrayLen(orgLocales); i=i+1) {
	               if (listLen(orgLocales[i],"_") EQ 2) {
	                       if (left(orgLocales[i],2) EQ "ar" or left(orgLocales[i],2) EQ "iw")
	                               thisName=chr(8235)&orgLocales[i].getDisplayName(orgLocales[i])&chr(8234);
	                       else
	                               thisName=orgLocales[i].getDisplayName(orgLocales[i]);
	                       theseLocales=listAppend(theseLocales,thisName);
	               } // if locale more than language
	       } //for
	       return theseLocales;
	</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getISOlanguages"  access="public" output="false" returntype="array" hint="returns array of 2 letter ISO languages">
    	<cfreturn instance.aLocale.getISOLanguages()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getISOcountries" access="public"  output="false" returntype="array" hint="returns array of 2 letter ISO countries">
    	<cfreturn instance.aLocale.getISOCountries()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<!--- core java uses 'iw' for hebrew, leaving 'he' just in case this is a version thing --->
	<cffunction name="isBidi" access="public" output="false" returntype="boolean" hint="determines if given locale is BIDI">
		<cfif listFind("ar,iw,fa,ps,he",left(buildLocale(getfwLocale()).toString(),2))>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getCurrencySymbol" access="public" returntype="string" output="false" hint="returns currency symbol for this locale">
		<!--- ************************************************************* --->
		<cfargument name="localized" required="no" type="boolean" default="true" hint="return international (USD, THB, etc.) or localized ($,etc.) symbol">
		<!--- ************************************************************* --->
		<cfset var aCurrency=createObject("java","com.ibm.icu.util.Currency")>
		<cfset var tmp=arrayNew(1)>
		<cfif arguments.localized>
			<cfset arrayAppend(tmp,true)>
		    <cfreturn aCurrency.getInstance(buildLocale(getfwLocale())).getName(buildLocale(getfwLocale()),aCurrency.SYMBOL_NAME,tmp)>
		</cfif>

		<cfreturn aCurrency.getInstance(buildLocale(getfwLocale())).getCurrencyCode()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getDecimalSymbols"  access="public"  output="false" returntype="struct" hint="returns strucure holding decimal format symbols for this locale">
	<cfscript>
	       var dfSymbols=instance.aDFSymbol.init(buildLocale(getfwLocale()));
	       var symbols=structNew();
	       // symbols.plusSign=dfSymbols.getPlusSign().toString();
	       symbols.Percent=dfSymbols.getPercent().toString();
	       symbols.minusSign=dfSymbols.getMinusSign().toString();
	       symbols.currencySymbol=dfSymbols.getCurrencySymbol().toString();
	       symbols.internationCurrencySymbol=dfSymbols.getInternationalCurrencySymbol().toString();
	       symbols.monetaryDecimalSeparator=dfSymbols.getMonetaryDecimalSeparator().toString();
	       symbols.exponentSeparator=dfSymbols.getExponentSeparator().toString();
	       symbols.perMille=dfSymbols.getPerMill().toString();
	       symbols.decimalSeparator=dfSymbols.getDecimalSeparator().toString();
	       symbols.groupingSeparator=dfSymbols.getGroupingSeparator().toString();
	       symbols.zeroDigit=dfSymbols.getZeroDigit().toString();
	       return symbols;
	</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nDateTimeFormat" access="public" output="false" returntype="string">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
		<cfargument name="thisDateFormat" default="1" required="No" type="numeric" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="thisTimeFormat" default="1" required="No" type="numeric" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	       <cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	       <cfset var tDateFormatter=instance.aDateFormat.getDateTimeInstance(tDateFormat,tTimeFormat,buildLocale(getfwLocale()))>
	       <cfset var tTZ=instance.timeZone.getTimezone(arguments.tz)>
	       <cfset tDateFormatter.setTimezone(tTZ)>
	       <cfreturn tDateFormatter.format(arguments.thisOffset)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nDateFormat" access="public" output="false" returntype="string">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
		<cfargument name="thisDateFormat" default="1" required="No" type="numeric" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
		   <cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	       <cfset var tDateFormatter=instance.aDateFormat.getDateInstance(tDateFormat,buildLocale(getfwLocale()))>
	       <cfset var tTZ=instance.timeZone.getTimezone(arguments.tz)>
	       <cfset tDateFormatter.setTimezone(tTZ)>
	       <cfreturn tDateFormatter.format(arguments.thisOffset)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nTimeFormat" access="public" output="false" returntype="string">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric" hint="java epoch offset">
		<cfargument name="thisTimeFormat" default="1" required="No" type="numeric" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
	    <!--- ************************************************************* --->
	       <cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	       <cfset var tTimeFormatter=instance.aDateFormat.getTimeInstance(tTimeFormat,buildLocale(getfwLocale()))>
	       <cfset var tTZ=instance.timeZone.getTimezone(arguments.tz)>
	       <cfset tTimeFormatter.setTimezone(tTZ)>
	       <cfreturn tTimeFormatter.format(arguments.thisOffset)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="dateLocaleFormat" access="public" returnType="any" output="false"
				hint="locale version of dateFormat. Needs object instantiation. That is your job not mine.">
		<!--- ************************************************************* --->
		<cfargument name="date" type="date" required="true">
		<cfargument name="style" type="string" required="false" default="LONG" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<!--- ************************************************************* --->
		<cfscript>
		// hack to trap & fix varchar mystery goop coming out of mysql datetimes
		try {
			return instance.aDateFormat.getDateInstance(instance.aDateFormat[arguments.style],buildLocale(getfwLocale())).format(arguments.date);
		}
		catch(Any e) {
			instance.aCalendar.setTime(arguments.date);
			return instance.aDateFormat.getDateInstance(instance.aDateFormat[arguments.style],buildLocale(getfwLocale())).format(instance.aCalendar.getTime());
		}
		</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="timeLocaleFormat" access="public" returnType="any" output="false"
				hint="locale version of timeFormat. Needs object instantiation. That is your job not mine.">
		<!--- ************************************************************* --->
		<cfargument name="date"  type="date" 	required="true">
		<cfargument name="style" type="string"  required="false" default="SHORT" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<!--- ************************************************************* --->
		<cfscript>
		// hack to trap & fix varchar mystery goop coming out of mysql datetimes
		try {
			return instance.aDateFormat.getTimeInstance(instance.aDateFormat[arguments.style],buildLocale(getfwLocale())).format(arguments.date);
		}
		catch (Any e) {
			instance.aCalendar.setTime(arguments.date);
			return instance.aDateFormat.getTimeInstance(instance.aDateFormat[arguments.style],buildLocale(getfwLocale())).format(instance.aCalendar.getTime());
		}
		</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="datetimeLocaleFormat" access="public" returnType="any" output="false" hint="locale date/time format. Needs object instantiation. That is your job not mine.">
		<!--- ************************************************************* --->
		<cfargument name="date" 		type="date" required="true">
		<cfargument name="dateStyle" 	type="string" required="false" default="SHORT" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="timeStyle" 	type="string" required="false" default="SHORT" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<!--- ************************************************************* --->
		<cfscript>
		// hack to trap & fix varchar mystery goop coming out of mysql datetimes
		try {
			return instance.aDateFormat.getDateTimeInstance(instance.aDateFormat[arguments.dateStyle],instance.aDateFormat[arguments.timeStyle],buildLocale(getfwLocale())).format(arguments.date);
		}
		catch (Any e) {
			instance.aCalendar.setTime(arguments.date);
			return instance.aDateFormat.getDateTimeInstance(instance.aDateFormat[arguments.dateStyle],instance.aDateFormat[arguments.timeStyle],buildLocale(getfwLocale())).format(instance.aCalendar.getTime());
		}
		</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nDateParse" access="public" output="false" returntype="numeric" hint="parses localized date string to datetime object or returns blank if it can't parse">
		<!--- ************************************************************* --->
		<cfargument name="thisDate" required="yes" type="string">
		<!--- ************************************************************* --->
			<cfset var isOk=false>
			<cfset var i=0>
			<cfset var parsedDate="">
			<cfset var tDateFormatter="">
			<!--- holy cow batman, can't parse dates in an elegant way. bash! pow! socko! --->
			<cfloop index="i" from="0" to="3">
				<cfset isOK=true>
				<cfset tDateFormatter=instance.aDateFormat.getDateInstance(javacast("int",i),buildLocale(getfwLocale()))>
				<cftry>
					<cfset parsedDate=tDateFormatter.parse(arguments.thisDate)>
					<cfcatch type="Any">
						<cfset isOK=false>
					</cfcatch>
				</cftry>
				<cfif isOK>
					<cfbreak>
				</cfif>
	        </cfloop>
	        <cfreturn parsedDate.getTime()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nDateTimeParse" access="public" output="false" returntype="numeric" hint="parses localized datetime string to datetime object or returns blank if it can't parse">
		<!--- ************************************************************* --->
		<cfargument name="thisDate" required="yes" type="string">
		<!--- ************************************************************* --->
			<cfset var isOk=false>
			<cfset var i=0>
			<cfset var j=0>
			<cfset var dStyle=0>
			<cfset var tStyle=0>
			<cfset var parsedDate="">
			<cfset var tDateFormatter="">
			<!--- holy cow batman, can't parse dates in an elegant way. bash! pow! socko! --->
			<cfloop index="i" from="0" to="3">
				<cfset dStyle=javacast("int",i)>
				<cfloop index="j" from="0" to="3">
					<cfset tStyle=javacast("int",j)>
					<cfset isOK=true>
					<cfset tDateFormatter=instance.aDateFormat.getDateTimeInstance(dStyle,tStyle,buildLocale(getfwLocale()))>
					<cftry>
						<cfset parsedDate=tDateFormatter.parse(arguments.thisDate)>
						<cfcatch type="Any">
							<cfset isOK=false>
						</cfcatch>
					</cftry>
					<cfif isOK>
						<cfbreak>
					</cfif>
				</cfloop>
	       </cfloop>
	       <cfreturn parsedDate.getTime()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getDateTimePattern" access="public" output="false" returntype="string" hint="returns locale date/time pattern">
		<!--- ************************************************************* --->
		<cfargument name="thisDateFormat" required="no" type="numeric" default="1" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<cfargument name="thisTimeFormat" required="no" type="numeric" default="3" hint="FULL=0, LONG=1, MEDIUM=2, SHORT=3">
		<!--- ************************************************************* --->
	       <cfset var tDateFormat=javacast("int",arguments.thisDateFormat)>
	       <cfset var tTimeFormat=javacast("int",arguments.thisTimeFormat)>
	       <cfset var tDateFormatter=instance.aDateFormat.getDateTimeInstance(tDateFormat,tTimeFormat,buildLocale(getfwLocale()))>
	       <cfreturn tDateFormatter.toPattern()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="formatDateTime" access="public" output="false" returntype="string" hint="formats a date/time to given pattern">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric">
		<cfargument name="thisPattern" required="yes" type="string">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var tDateFormatter=instance.aDateFormat.getDateTimeInstance(instance.aDateFormat.LONG,instance.aDateFormat.LONG,buildLocale(getfwLocale()))>
	       <cfset tDateFormatter.applyPattern(arguments.thisPattern)>
	       <cfreturn tDateFormatter.format(arguments.thisOffset)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="weekStarts" access="public" returnType="string" output="false" hint="Determines the first DOW.">
	       <cfreturn instance.aCalendar.getFirstDayOfWeek() />
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getLocalizedYear" access="public" returnType="string" output="false" hint="Returns localized year, probably only useful for BE calendars like in thailand, etc.">
		<!--- ************************************************************* --->
		<cfargument name="thisYear"   type="numeric" required="true" />
		<!--- ************************************************************* --->
	       <cfset var thisDF=instance.sDateFormat.init("yyyy", buildLocale(getfwLocale()))>
	       <cfreturn thisDF.format(createDate(arguments.thisYear, 1, 1)) />
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getLocalizedMonth" access="public" returnType="string" output="false" hint="Returns localized month.">
		<!--- ************************************************************* --->
		<cfargument name="month" type="numeric" required="true">
	    <!--- ************************************************************* --->
	       <cfset var thisDF=instance.sDateFormat.init("MMMM",buildLocale(getfwLocale()))>
	       <cfreturn thisDF.format(createDate(1999,arguments.month,1))>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getLocalizedDays" access="public" returnType="any" output="false"
				hint="Facade to getShortWeedDays. For compatability">
		<cfscript>
		return getShortWeekDays();
		</cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getShortWeekDays" access="public" output="false" returntype="array" hint="returns short day names for this calendar">
		<!--- ************************************************************* --->
		<cfargument name="calendarOrder" required="no" type="boolean" default="true">
		<!--- ************************************************************* --->
	       <cfset var theseDateSymbols= createObject("java","java.text.DateFormatSymbols").init(buildLocale(arguments.locale))>
	       <cfset var localeDays="">
	       <cfset var i=0>
	       <cfset var tmp=listToArray(arrayToList(theseDateSymbols.getShortWeekDays()))>
	       <cfif NOT arguments.calendarOrder>
	               <cfreturn tmp>
	       <cfelse>
	               <cfswitch expression="#weekStarts(buildLocale(arguments.locale))#">
		               <cfcase value="1"> <!--- "standard" dates --->
		                       <cfreturn tmp>
		               </cfcase>
		               <cfcase value="2"> <!--- euro dates, starts on monday needs kludge --->
		                       <cfset localeDays=arrayNew(1)>
		                       <cfset localeDays[7]=tmp[1]>; <!--- move sunday to last --->
		                       <cfloop index="i" from="1" to="6">
		                               <cfset localeDays[i]=tmp[i+1]>
		                       </cfloop>
		                       <cfreturn localeDays>
		               </cfcase>
		               <cfcase value="7"> <!--- starts saturday, usually arabic, needs kludge --->
		                       <cfset localeDays=arrayNew(1)>
		                       <cfset localeDays[1]=tmp[7]> <!--- move saturday to first --->
		                       <cfloop index="i" from="1" to="6">
		                               <cfset localeDays[i+1]=tmp[i]>
		                       </cfloop>
		                       <cfreturn localeDays>
		               </cfcase>
	               </cfswitch>
	       </cfif>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getYear" output="false" access="public" returntype="numeric" hint="returns year from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset"   required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" 			required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.YEAR)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getMonth" output="false" access="public" returntype="numeric" hint="returns month from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.MONTH)+1> <!--- java months start at 0 --->
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getDay" output="false" access="public" returntype="numeric" hint="returns day from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.DATE)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getHour" output="false" access="public" returntype="numeric" hint="returns hour of day, 24 hr format, from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.HOUR_OF_DAY)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getMinute" output="false" access="public" returntype="numeric" hint="returns minute from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.MINUTE)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getSecond" output="false" access="public" returntype="numeric" hint="returns second from epoch offset">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset" type="numeric">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimeZone(thisTZ)>
	       <cfreturn instance.aCalendar.get(instance.aCalendar.SECOND)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="toEpoch" access="public" output="false" returnType="numeric" hint="converts datetime to java epoch offset">
		<cfargument name="thisDate" required="Yes" hint="datetime to convert to java epoch" type="date">
	       <cfreturn arguments.thisDate.getTime()>
	 </cffunction>
 	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="fromEpoch" access="public" output="false" returnType="date" hint="converts java epoch offset to datetime">
		<cfargument name="thisOffset" required="Yes" hint="java epoch offset to convert to datetime" type="numeric">
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfreturn instance.aCalendar.getTime()>
	 </cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getAvailableTZ" output="false" returntype="array" access="public" hint="returns an array of timezones available on this server">
		<cfreturn instance.timeZone.getAvailableIDs()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="usesDST" output="false" returntype="boolean" access="public" hint="determines if a given timezone uses DST">
		<cfargument name="tz" required="no" default="#instance.timeZone.getDefault().getID()#">
	       <cfreturn instance.timeZone.getTimeZone(arguments.tz).useDaylightTime()>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getRawOffset" output="false" access="public" returntype="numeric" hint="returns rawoffset in hours">
		<cfargument name="tZ" required="no" default="#instance.timeZone.getDefault().getID()#">
               <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tZ)>
               <cfreturn thisTZ.getRawOffset()/3600000>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getDST" output="false" access="public" returntype="numeric" hint="returns DST savings in hours">
		<cfargument name="thisTZ" required="no" default="#instance.timeZone.getDefault().getID()#">
	       <cfset var tZ=instance.timeZone.getTimeZone(arguments.thisTZ)>
	       <cfreturn tZ.getDSTSavings()/3600000>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getTZByOffset" output="false" returntype="array" access="public" hint="returns a list of timezones available on this server for a given raw offset">
		<cfargument name="thisOffset" required="Yes" type="numeric">
	       <cfset var rawOffset=javacast("long",arguments.thisOffset * 3600000)>
	       <cfreturn instance.timeZone.getAvailableIDs(rawOffset)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getServerTZ" output="false" access="public" returntype="any" hint="returns server TZ">
	       <cfset var serverTZ=instance.timeZone.getDefault()>
	       <cfreturn serverTZ.getDisplayName(true,instance.timeZone.LONG)>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="inDST" output="false" returntype="boolean" access="public" hint="determines if a given date in a given timezone is in DST">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric">
		<cfargument name="tzToTest" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var thisTZ=instance.timeZone.getTimeZone(arguments.tzToTest)>
	       <cfset instance.aCalendar.setTimeInMillis(arguments.thisOffset)>
	       <cfset instance.aCalendar.setTimezone(thisTZ)>
	       <cfreturn thisTZ.inDaylightTime(instance.aCalendar.getTime())>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="getTZOffset" output="false" access="public" hint="returns offset in hours">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric">
		<cfargument name="thisTZ" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfset var tZ=instance.timeZone.getTimeZone(arguments.thisTZ)>
	       <cfreturn tZ.getOffset(arguments.thisOffset)/3600000> <!--- return hours --->
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<cffunction name="i18nDateAdd" access="public" output="false" returntype="numeric">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric">
		<cfargument name="thisDatePart" required="yes" type="string">
		<cfargument name="dateUnits" required="yes" type="numeric">
		<cfargument name="thisTZ" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
	       <cfscript>
	               var dPart="";
	               var tZ=instance.timeZone.getTimeZone(arguments.thisTZ);
	               switch (arguments.thisDatepart) {
	                       case "y" :
	                       case "yr" :
	                       case "yyyy" :
	                       case "year" :
	                               dPart=instance.aCalendar.YEAR;
	                       break;
	                       case "m" :
	                       case "month" :
	                               dPart=instance.aCalendar.MONTH;
	                       break;
	                       case "w" :
	                       case "week" :
	                               dPart=instance.aCalendar.WEEK_OF_MONTH;
	                       break;
	                       case "d" :
	                       case "day" :
	                               dPart=instance.aCalendar.DATE;
	                       break;
	                       case "h" :
	                       case "hr":
	                       case "hour" :
	                               dPart=instance.aCalendar.HOUR;
	                       break;
	                       case "n" :
	                       case "minute" :
	                               dPart=instance.aCalendar.MINUTE;
	                       break;
	                       case "s" :
	                       case "second" :
	                               dPart=instance.aCalendar.SECOND;
	                       break;
	               }
	               instance.aCalendar.setTimeInMillis(arguments.thisOffset);
	               instance.aCalendar.setTimezone(tZ);
	               instance.aCalendar.add(dPart,javacast("int",arguments.dateUnits));
	               return instance.aCalendar.getTimeInMillis();
	       </cfscript>
	</cffunction>
	<!--- ************************************************************* --->

	<!--- ************************************************************* --->
	<!--- oh my is this nasty in core java --->
	<cffunction name="i18nDateDiff"  access="public" output="false" returntype="numeric">
		<!--- ************************************************************* --->
		<cfargument name="thisOffset" required="yes" type="numeric">
		<cfargument name="thatOffset" required="yes" type="numeric">
		<cfargument name="thisDatePart" required="yes" type="string">
		<cfargument name="thisTZ" required="no" default="#instance.timeZone.getDefault().getID()#">
		<!--- ************************************************************* --->
		<cfscript>
		       var dPart="";
		       var elapsed=0;
		       var before=createObject("java","java.util.GregorianCalendar");
		       var after=createObject("java","java.util.GregorianCalendar");
		       var tZ=instance.timeZone.getTimeZone(arguments.thisTZ);
		       var e=0;
		       var s=0;
		       var direction=1;
		       // lets shortcut first
		       if (arguments.thisOffset EQ arguments.thatOffset)
		               return 0;
		       else {  // setup calendars to test
		               if (arguments.thisOffset LT arguments.thatOffset) {
		                       before.setTimeInMillis(arguments.thisOffset);
		                       after.setTimeInMillis(arguments.thatOffset);
		                       before.setTimezone(tZ);
		                       after.setTimezone(tZ);
		               } else {
		                       before.setTimeInMillis(arguments.thatOffset);
		                       after.setTimeInMillis(arguments.thisOffset);
		                       before.setTimezone(tZ);
		                       after.setTimezone(tZ);
		                       direction=-1;
		               } // which offset came first
		               switch (arguments.thisDatepart) {
		                       case "y" :
		                       case "yr" :
		                       case "yyyy" :
		                       case "year" :
		                               dPart=instance.aCalendar.YEAR;
		                               before.clear(instance.aCalendar.DATE);
		                               after.clear(instance.aCalendar.DATE);
		                               before.clear(instance.aCalendar.MONTH);
		                               after.clear(instance.aCalendar.MONTH);
		                       break;
		                       case "m" :
		                       case "month" :
		                               dPart=instance.aCalendar.MONTH;
		                               before.clear(instance.aCalendar.DATE);
		                               after.clear(instance.aCalendar.DATE);
		                       break;
		                       case "w" :
		                       case "week" :
		                               dPart=instance.aCalendar.WEEK_OF_YEAR;
		                               before.clear(instance.aCalendar.DATE);
		                               after.clear(instance.aCalendar.DATE);
		                       break;
		                       case "d" :
		                       case "day" :
		                               // very much a special case
		                               e=after.getTimeInMillis()+after.getTimeZone().getOffset(after.getTimeInMillis());
		                               s=before.getTimeInMillis()+before.getTimeZone().getOffset(before.getTimeInMillis());
		                               return int((e-s)/86400000)*direction;
		                       break;
		                       case "h" :
		                       case "hr" :
		                       case "hour" :
		                               e=after.getTimeInMillis()+after.getTimeZone().getOffset(after.getTimeInMillis());
		                               s=before.getTimeInMillis()+before.getTimeZone().getOffset(before.getTimeInMillis());
		                               return int((e-s)/3600000)*direction;
		                       break;
		                       case "n" :
		                       case "minute" :
		                               e=after.getTimeInMillis()+after.getTimeZone().getOffset(after.getTimeInMillis());
		                               s=before.getTimeInMillis()+before.getTimeZone().getOffset(before.getTimeInMillis());
		                               return int((e-s)/60000)*direction;
		                       break;
		                       case "s" :
		                       case "second" :
		                               e=after.getTimeInMillis()+after.getTimeZone().getOffset(after.getTimeInMillis());
		                               s=before.getTimeInMillis()+before.getTimeZone().getOffset(before.getTimeInMillis());
		                               return int((e-s)/1000)*direction;
		                       break;
		               }// datepart switch
		               while (before.before(after)){
		                       before.add(dPart,1);
		                       elapsed=elapsed+1;
		               } //count dateparts
		               return elapsed * direction;
		       } // if start & end times are the same
		</cfscript>
	</cffunction>

	<cffunction name="getLocaleQuery" access="public" output="false" returntype="query" hint="returns a sorted query of locales (locale,country,language,dspName,localname. 'localname' will contain the locale's name in its native characters). Suitable for use in creating select lists.">
		<cfscript>
			var aLocales = getLocales();
			var qryLocale = queryNew("locale,country,language,dspName,localname");
			var stNames = structnew();
			var i=0;
			//building an array of locales,country name, language name, and sorting alphabetically...
			for(i=1;i LTE arraylen(aLocales);i=i+1){
				queryAddRow(qryLocale,1);
				querySetCell(qryLocale,"locale",aLocales[i].toString());
				if(left(aLocales[i],2) IS "ar" or left(aLocales[i],2) IS "iw"){//need to write the value from right to left
					querySetCell(qryLocale,"localname",chr(8235)& aLocales[i].getDisplayName(aLocales[i]) & chr(8234));
				} else {
					querySetCell(qryLocale,"localname",aLocales[i].getDisplayName(aLocales[i]));
				}
				querySetCell(qryLocale,"dspName",aLocales[i].getDisplayName());
				querySetCell(qryLocale,"language",aLocales[i].getDisplayLanguage());
				querySetCell(qryLocale,"country",aLocales[i].getDisplayCountry());
			}
		</cfscript>
		<cfquery name="qryLocale" dbtype="query">
			select locale,country,[language],dspName,localname
			from qryLocale
			order by dspName,[language]
		</cfquery>
		<cfreturn qryLocale />
	</cffunction>

	<cffunction name="getTZQuery" access="public" output="false" returntype="query" hint="returns a sorted query of timezones, optionally filters for only unique display names (fields:id,offset,dspName,longname,shortname,usesDST). Suitable for use in creating select lists.">
		<cfargument name="returnUnique" type="boolean" required="true" default="true"/>
		<cfscript>
			var aTZID = getAvailableTZ();
			var stNames = structnew();
			var qryTZ = queryNew("id,offset,dspName,longname,shortname,usesDST");
			var i = 0;
			//build our initial query...
			for(i=1;i LTE arraylen(aTZID);i=i+1){
				tmpName = getTZDisplayName(aTZID[i]);
				if(arguments.returnUnique){
					if(not structkeyexists(stNames,tmpname)){
						queryAddRow(qryTZ,1);
						querySetCell(qryTZ,"id",aTZID[i]);
						querySetCell(qryTZ,"offset",getRawOffset(aTZID[i]));
						querySetCell(qryTZ,"dspName",tmpName);
						querySetCell(qryTZ,"longname",getTZDisplayName(aTZID[i],"long"));
						querySetCell(qryTZ,"shortname",getTZDisplayName(aTZID[i],"short"));
						querySetCell(qryTZ,"usesDST",usesDST(aTZID[i]));
						if(arguments.returnUnique){
							//add this name to  our unique list
							stnames[tmpName] = "";
						}
					}
				} else {
					queryAddRow(qryTZ,1);
					querySetCell(qryTZ,"id",aTZID[i]);
					querySetCell(qryTZ,"offset",getRawOffset(aTZID[i]));
					querySetCell(qryTZ,"dspName",tmpName);
					querySetCell(qryTZ,"longname",getTZDisplayName(aTZID[i],"long"));
					querySetCell(qryTZ,"shortname",getTZDisplayName(aTZID[i],"short"));
					querySetCell(qryTZ,"usesDST",usesDST(aTZID[i]));
				}
			}
		</cfscript>
		<!--- sort the results... --->
		<cfquery name="qryTZ" dbtype="query">
			select id,offset,dspname,longname,shortname,usesDST
			from qryTZ
			order by offset,dspname
		</cfquery>
		<cfreturn qryTZ />
	</cffunction>

	<cffunction name="getTZDisplayName" output="false" access="public" returntype="string" hint="returns the display name of the timezone requested in either long, short, or default style">
		<cfargument name="thisTZ" required="no" default="#instance.timeZone.getDefault().getID()#">
		<cfargument name="dspType" required="no" type="string" default="" />
	       <cfset var tZ=instance.timeZone.getTimeZone(arguments.thisTZ)>
	       <cfif arguments.dspType IS "long">
	       		<cfreturn tZ.getDisplayName(JavaCast("boolean",false),JavaCast("int",1)) />
	       <cfelseif arguments.dspType IS "short">
	       		<cfreturn tZ.getDisplayName(JavaCast("boolean",false),JavaCast("int",0)) />
	       <cfelse>
	       	 <cfreturn tZ.getDisplayName()>
	       </cfif>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

	<cffunction name="buildLocale"  access="private" output="false" hint="creates valid core java locale from java style locale ID">
		<!--- ************************************************************* --->
		<cfargument name="thisLocale" required="false" type="string" default="en_US">
		<!--- ************************************************************* --->
		<cfscript>
			var l=listFirst( arguments.thisLocale, "_" );
			var c="";
			var v="";
			var tLocale=instance.aLocale.getDefault(); // if we fail fallback on server default

			// Check locale
			if ( not isValidLocale(arguments.thisLocale) ){
				throw( message="Specified locale must be of the form language_COUNTRY_VARIANT where language, country and variant are 2 characters each, ISO 3166 standard.",
				       detail="The locale tested is: #arguments.thisLocale#",
				       type="i18n.InvalidLocaleException" );
			}

			switch (listLen(arguments.thisLocale,"_")) {
			       case 1:
			               tLocale=instance.aLocale.init(l);
			       break;
			       case 2:
			               c=listLast(arguments.thisLocale,"_");
			               tLocale=instance.aLocale.init(l,c);
			       break;
			       case 3:
			               c=listGetAt(arguments.thisLocale,2,"_");
			               v=listLast(arguments.thisLocale,"_");
			               tLocale=instance.aLocale.init(l,c,v);
			       break;
			}
			return tLocale;
		</cfscript>
	</cffunction>
	<!--- ************************************************************* --->


</cfcomponent>