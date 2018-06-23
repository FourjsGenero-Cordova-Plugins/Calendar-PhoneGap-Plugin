# Property of Four Js*
# (c) Copyright Four Js 2017, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these
# samples are accurate and suitable for your purposes. Their inclusion is
# purely for information purposes only.

# Cordova calendar plugin sample
# Calendar plugin from https://github.com/EddyVerbruggen/Calendar-PhoneGap-Plugin
# bundled with Genero
OPTIONS SHORT CIRCUIT
IMPORT util
IMPORT os
IMPORT FGL fgldialog
IMPORT FGL fglcdvCalendar
DEFINE calOptions fglcdvCalendar.EventOptionsT
DEFINE calArr DYNAMIC ARRAY OF fglcdvCalendar.CalendarT
DEFINE evArr DYNAMIC ARRAY OF fglcdvCalendar.EventT
TYPE DisplayEventT RECORD
    title STRING,
    startDate DATETIME YEAR TO MINUTE
END RECORD

--helper macro to save a lot of boilerplate conversion between
--different record types, attention: datetimes must have exactly the same type!
&define ASSIGN_RECORD(src,dest) CALL util.JSON.parse(util.JSON.stringify(src),dest)

MAIN
    CALL fglcdvCalendar.initialize() --mandatory entry point
    --check the permissions once here to avoid to do that in several places
    DISPLAY "hasReadWrite:",fglcdvCalendar.hasReadWritePermission()
    IF ui.Interface.getFrontEndName()=="GMI" AND NOT fglcdvCalendar.requestReadWritePermission() THEN
      CALL fgl_winmessage("Info","Demo  will be terminated: No access to calendar","info")
      RETURN
    END IF
    MENU "Cordova Calendar Demo"
    ON ACTION list ATTRIBUTES(TEXT="List Calendars",COMMENT="Enumerates all calendars",IMAGE="fa-list",DISCLOSUREINDICATOR)
      IF listCalendars() THEN
        CALL showCalendars()
      END IF
    ON ACTION open ATTRIBUTES(TEXT="Open calendar",COMMENT="Opens the native calendar app",IMAGE="fa-calendar")
        CALL fglcdvCalendar.openCalendar(CURRENT)
    END MENU
END MAIN

#+ init an event with the current date
#+ allday can be used to turn the event into an allday event
FUNCTION fillEvent(title STRING,notes STRING,allDay BOOLEAN)
    INITIALIZE calOptions.* TO NULL
    LET calOptions.title=title
    LET calOptions.notes=notes
    IF allDay THEN 
      LET calOptions.startDate=CURRENT
      LET calOptions.endDate=CURRENT
      LET calOptions.options.allday=TRUE
    ELSE
      LET calOptions.startDate=CURRENT
      LET calOptions.endDate=calOptions.startDate+ 1 UNITS HOUR
    END IF

    LET calOptions.options.firstReminderMinutes=60
END FUNCTION

FUNCTION listCalendars()
  DEFINE err STRING
  DEFINE i INT
  CALL fglcdvCalendar.listCalendars() RETURNING calArr,err
  IF err IS NOT NULL THEN
    ERROR err
    RETURN FALSE
  END IF
  DISPLAY util.JSON.stringify(calArr)
  FOR i=calArr.getLength() TO 1 STEP -1
    IF calArr[i].name.getLength()==0 THEN
      CALL calArr.deleteElement(i)
    END IF
  END FOR
  IF calArr.getLength() IS NULL THEN
    ERROR "No Calendars active"
    RETURN FALSE
  ELSE
    DISPLAY "length:",calArr.getLength(),",content:",util.JSON.stringify(calArr)
    RETURN TRUE
  END IF
END FUNCTION

FUNCTION showCalendars()
  DEFINE calendarName STRING 
  DEFINE result,calId,ok STRING
  DEFINE dummy BOOLEAN
    
  OPEN WINDOW calendars WITH FORM "calendars"
  DISPLAY ARRAY calArr TO arr.* ATTRIBUTE(CANCEL=FALSE,UNBUFFERED,DOUBLECLICK=showevents,ACCESSORYTYPE=DISCLOSUREINDICATOR)
    ON ACTION append
      LET int_flag=FALSE
      PROMPT "Enter name" FOR calendarName
      IF NOT int_flag THEN
        LET calId=fglcdvCalendar.createCalendar(calendarName,NULL)
        IF calId IS NULL THEN
          LET int_flag=TRUE
          ERROR fglcdvCalendar.getLastError()
        ELSE
          MESSAGE calId
          CALL listCalendars() RETURNING dummy
        END IF
      END IF
    ON DELETE
      LET int_flag=FALSE
      LET calendarName=calArr[arr_curr()].name
      IF fgldialog.fgl_winQuestion("Confirmation",sfmt("Delete calendar '%1'?",calendarName),"yes","yes|no","information",0)=="yes" THEN
        IF (ok:=fglcdvCalendar.deleteCalendar(calendarName)) IS NULL THEN
          ERROR fglcdvCalendar.getLastError()
          LET int_flag=TRUE
        ELSE
          MESSAGE ok
        END IF
      ELSE
        LET int_flag=TRUE
      END IF
    ON ACTION showevents --show events for today -1 year and +1 year 
      LET calendarName=calArr[arr_curr()].name
      IF findEventsPlusMinusYear(calendarName) THEN
        CALL displayEvents(calendarName)
      END IF
  END DISPLAY
  CLOSE WINDOW calendars
END FUNCTION

FUNCTION findEventsPlusMinusYear(calendarName STRING) RETURNS BOOLEAN
  DEFINE d fglcdvCalendar.CALENDAR_DATE
  DEFINE findOpts fglcdvCalendar.FindOptionsT
  DEFINE err STRING
  LET d=CURRENT
  LET findOpts.startDate=d - 1 UNITS YEAR
  LET findOpts.endDate=d + 1 UNITS YEAR
  LET findOpts.calendarName=calendarName
  IF ui.Interface.getFrontEndName() == "GMA" THEN
     --need to check if the selected calendarName is actually the default calendar
     --if its not, the just do a continue RETURN FALSE
  END IF
  CALL fglcdvCalendar.findEventsWithOptions(findOpts.*) RETURNING evArr,err
  IF err IS NOT NULL THEN
     ERROR err
     RETURN FALSE
  END IF
  DISPLAY sfmt("found %1 events",evArr.getLength())
  CALL evArr.sort("startDate",FALSE) --sort in ascending order
  RETURN TRUE
END FUNCTION

FUNCTION displayEvents(calendarName STRING)
  DEFINE result,newTitle,id,freq,newfreq STRING
  DEFINE i,refreshRow,dummy INT
  DEFINE event,ev fglcdvCalendar.EventT
  DEFINE changeOpts fglcdvCalendar.EventOptionsT
  DEFINE findOpts fglcdvCalendar.FindOptionsT
  DEFINE sArr DYNAMIC ARRAY OF DisplayEventT
  DEFINE spanFutureEvents,cancelDelete BOOLEAN
  OPEN WINDOW events WITH FORM "events"
&define REFRESH_LIST() \
        LET refreshRow=IIF(arr_curr()<=1,1,arr_curr()-1) \
        EXIT DISPLAY

LABEL refresh:
  IF refreshRow>0 THEN
    CALL findEventsPlusMinusYear(calendarName) RETURNING dummy
  END IF
  CALL sArr.clear()
  FOR i=1 TO evArr.getLength()
    LET sArr[i].title=evArr[i].title
    LET sArr[i].startDate=evArr[i].startDate
  END FOR
  DISPLAY ARRAY sArr TO arr.* ATTRIBUTE(DOUBLECLICK=showevent,ACCESSORYTYPE=DISCLOSUREINDICATOR,ACCEPT=FALSE,UNBUFFERED)
    BEFORE DISPLAY
      IF refreshRow>0 THEN
        CALL fgl_set_arr_curr(refreshRow)
        LET refreshRow=0
      END IF
      --modify is not present on GMA
      IF ui.Interface.getFrontEndName()=="GMA" THEN
        CALL DIALOG.setActionHidden("modifyinteractively",1)
        CALL DIALOG.setActionHidden("modifydate",1)
        CALL DIALOG.setActionHidden("modifytitle",1)
      END IF
    ON ACTION showevent
      IF showOrUpdateEvent(evArr[arr_curr()].*,sArr) THEN
        REFRESH_LIST()
      END IF
    ON ACTION modifyinteractively ATTRIBUTE(ROWBOUND,TEXT="Modify Interactively")
      --this demonstrates the preferred way to edit an event interactively 
      --because the native build in controller has much more internal knowledge
      --about recurring, participants, locations etc
      LET event.*=evArr[arr_curr()].*
      DISPLAY "event:",util.JSON.stringify(event)
      LET event.calendar=calendarName
      --we get back "Canceled","Saved" or "Deleted"
      LET result=fglcdvCalendar.modifyEventInteractively(event.*)
      IF result IS NULL THEN
        ERROR fglcdvCalendar.getLastError()
      ELSE
        MESSAGE result
        IF result=="Canceled" THEN
          CONTINUE DISPLAY
        END IF
        --Deleted or Saved - we just refresh
        REFRESH_LIST()
      END IF
    --demonstrates the IOS programmatic modifyEventWithOptions API
    ON ACTION modifytitle ATTRIBUTE(ROWBOUND,TEXT="Modify Title") --rename title
      LET event.*=evArr[arr_curr()].*
      INITIALIZE changeOpts.* TO NULL
      LET changeOpts.title=event.title," - ",event.id
      LET changeOpts.notes=event.notes,"--*"
      CALL modifyEvent(event.*,changeOpts.*,sArr) RETURNING evArr[arr_curr()].*
    ON ACTION modifydate ATTRIBUTE(ROWBOUND,TEXT="Modify Date") --rename title and move the current entry one day
      LET event.*=evArr[arr_curr()].*
      INITIALIZE changeOpts.* TO NULL
      LET changeOpts.startDate=event.startDate+1 UNITS DAY
      LET changeOpts.endDate=event.endDate+1 UNITS DAY
      CALL modifyEvent(event.*,changeOpts.*,sArr) RETURNING evArr[arr_curr()].*
    ON DELETE
      LET event.*=evArr[arr_curr()].*
      CALL askDeleteFutureEvents(event.*) RETURNING spanFutureEvents,cancelDelete
      IF cancelDelete THEN
        CONTINUE DISPLAY
      END IF
      CALL fglcdvCalendar.deleteEvent(event.*,spanFutureEvents) RETURNING result
      IF result IS NULL THEN
        LET int_flag=TRUE
        ERROR "Can't delete:",fglcdvCalendar.getLastError()
      ELSE
        REFRESH_LIST()
      END IF
    ON APPEND
      LET newTitle=newTitle("Event",sArr)
      CALL fillEvent(newTitle,sfmt("Some note %1",i),FALSE)
      LET calOptions.options.calendarName=calendarName
      LET id=fglcdvCalendar.createEventWithOptions(calOptions.*)
      IF id IS NULL THEN
        ERROR fglcdvCalendar.getLastError()
        LET int_flag=TRUE
      ELSE
        CALL fetchEvent(id,calOptions.*) RETURNING event.*
        LET evArr[arr_curr()].* = event.*
        LET sArr[arr_curr()].title=event.title
        LET sArr[arr_curr()].startDate=event.startDate
      END IF
    ON ACTION add ATTRIBUTE(TEXT="Add Interactive")
      LET newTitle=newTitle("EventI",sArr)
      CALL fillEvent(newTitle,"this event was added using 'createEventInteractively'",TRUE)
      --if an event should be created via UI, this is the preferred API to do that
      LET result=fglcdvCalendar.createEventInteractively(calOptions.*)
      IF result IS NULL THEN
        ERROR fglcdvCalendar.getLastError()
      ELSE
        --ios: we could fetch the concrete event by id
        --android: as we cannot fetch by id we just refill the whole array
        REFRESH_LIST()
      END IF
  END DISPLAY
  IF refreshRow>0 THEN
    GOTO refresh
  END IF
  CLOSE WINDOW events     
END FUNCTION

--just have a blabla title
FUNCTION newTitle(base STRING,sArr DYNAMIC ARRAY OF DisplayEventT)
  DEFINE i INT
  DEFINE newTitle STRING
  FOR i=1 TO 10000 
    LET newTitle=sfmt("%1%2",base,i)
    IF sArr.search("title",newTitle)==0 THEN
      RETURN newTitle
    END IF
  END FOR
  RETURN "Bummer"
END FUNCTION

FUNCTION askDeleteFutureEvents(event fglcdvCalendar.EventT)
  DEFINE spanFutureEvents BOOLEAN
  DEFINE cancelDelete BOOLEAN
  IF fglcdvCalendar.isRecurring(event.*) THEN
    LET cancelDelete=FALSE
    MENU "This is a repeating event." ATTRIBUTE(STYLE="popup")
      COMMAND "Delete This Event Only"
        LET spanFutureEvents=FALSE
      COMMAND "Delete All Future Events"
        LET spanFutureEvents=TRUE
      ON ACTION cancel
        LET cancelDelete=TRUE
      END MENU
  ELSE
    LET spanFutureEvents=NULL
  END IF
  RETURN spanFutureEvents,cancelDelete
END FUNCTION

FUNCTION askModifyFutureEvents(event fglcdvCalendar.EventT)
  DEFINE spanFutureEvents BOOLEAN
  DEFINE cancelModify BOOLEAN
  IF fglcdvCalendar.isRecurring(event.*) THEN
    LET cancelModify=FALSE
    MENU "This is a repeating event." ATTRIBUTE(STYLE="popup")
      COMMAND "Save for this event only"
        LET spanFutureEvents=FALSE
      COMMAND "Save for future events"
        LET spanFutureEvents=TRUE
      ON ACTION cancel
        LET cancelModify=TRUE
      END MENU
  ELSE
    LET spanFutureEvents=NULL
  END IF
  RETURN spanFutureEvents,cancelModify
END FUNCTION

#+ returns true if the event has been modified
FUNCTION showOrUpdateEvent(event fglcdvCalendar.EventT,
                        sArr DYNAMIC ARRAY OF DisplayEventT) RETURNS BOOLEAN
  DEFINE changeOpts fglcdvCalendar.EventOptionsT
  DEFINE spanFutureEvents,cancelModify,modified BOOLEAN
  DEFINE result STRING
  DEFINE inputEvent RECORD
    title STRING,
    allday INT,
    startDate DATETIME YEAR TO MINUTE,
    endDate DATETIME YEAR TO MINUTE,
    freq STRING,
    firstReminderMinutes INT,
    secondReminderMinutes INT,
    url STRING,
    notes STRING
  END RECORD
  DISPLAY "event:",util.JSON.stringify(event)
  OPEN WINDOW event WITH FORM "newevent"
&define ASSIGN_INPUT_EVENT() \
  ASSIGN_RECORD(event,inputEvent) \
  LET inputEvent.startDate=event.startDate \
  LET inputEvent.endDate=event.endDate \
  LET inputEvent.freq=event.rrule.freq 

  ASSIGN_INPUT_EVENT()
  DISPLAY BY NAME inputEvent.*
  MENU
    ON ACTION edit
      ASSIGN_INPUT_EVENT()
LABEL inputAgain:
      LET int_flag=FALSE
      INPUT BY NAME inputEvent.* WITHOUT DEFAULTS
      IF NOT int_flag THEN
        CALL askModifyFutureEvents(event.*) RETURNING spanFutureEvents, cancelModify
        IF cancelModify THEN
          GOTO inputAgain
        END IF
        --note: on android there is no modifyEvent API, we need to 
        --delete and re create the event again

        IF fglcdvCalendar.deleteEvent(event.*,spanFutureEvents) IS NULL THEN
          ERROR fglcdvCalendar.getLastError()
          GOTO inputAgain
        END IF
         
        INITIALIZE changeOpts.* TO NULL
        ASSIGN_RECORD(inputEvent,changeOpts)
        LET changeOpts.startDate=inputEvent.startDate
        LET changeOpts.endDate=inputEvent.endDate
        LET changeOpts.options.allday=inputEvent.allday
        IF spanFutureEvents OR
          (inputEvent.freq IS NOT NULL AND NOT fglcdvCalendar.isRecurring(event.*))  THEN
          LET changeOpts.options.recurrence=IIF(ui.Interface.getFrontEndName()=="GMA",UPSHIFT(inputEvent.freq),inputEvent.freq)
          LET changeOpts.options.recurrenceInterval=1
        END IF
        LET changeOpts.options.firstReminderMinutes=inputEvent.firstReminderMinutes
        LET changeOpts.options.secondReminderMinutes=inputEvent.secondReminderMinutes
        LET changeOpts.options.url=inputEvent.url
        LET result=fglcdvCalendar.createEventWithOptions(changeOpts.*)
        IF result IS NULL THEN 
          ERROR fglcdvCalendar.getLastError()
          GOTO inputAgain
        END IF
        MESSAGE result
        CALL fetchEvent(result,changeOpts.*) RETURNING event.*
        LET sArr[arr_curr()].title=event.title
        LET sArr[arr_curr()].startDate=event.startDate
        ASSIGN_INPUT_EVENT()
        DISPLAY BY NAME inputEvent.*
        LET modified=TRUE
      END IF
    ON ACTION close
      EXIT MENU
  END MENU
  CLOSE WINDOW event
  RETURN modified
END FUNCTION

FUNCTION modifyEvent(event fglcdvCalendar.EventT,
                     changeOpts fglcdvCalendar.EventOptionsT,
                     sArr DYNAMIC ARRAY OF DisplayEventT)
                     RETURNS fglcdvCalendar.EventT
  DEFINE result STRING
  DEFINE findOptions fglcdvCalendar.FindOptionsT
  INITIALIZE findOptions.* TO NULL
  LET findOptions.id=event.id
  LET changeOpts.options.spanFutureEvents=TRUE
  LET result=fglcdvCalendar.modifyEventWithOptions(findOptions.*,changeOpts.*)
  IF result IS NULL THEN
    ERROR fglcdvCalendar.getLastError()
  ELSE
    MESSAGE result
    CALL fetchEvent(result,changeOpts.*) RETURNING event.*
    LET sArr[arr_curr()].title=event.title
    LET sArr[arr_curr()].startDate=event.startDate
  END IF
  RETURN event.*
END FUNCTION

--fetches a particular event by id + options
FUNCTION fetchEvent(eventId STRING,options fglcdvCalendar.EventOptionsT)
  DEFINE findOpts fglcdvCalendar.FindOptionsT
  DEFINE findArr DYNAMIC ARRAY OF fglcdvCalendar.EventT
  DEFINE event fglcdvCalendar.EventT
  DEFINE err STRING
  CALL fglcdvCalendar.getFindOptions() RETURNING findOpts.*
  ASSIGN_RECORD(options,findOpts)
  LET findOpts.id=eventId
  CALL fglcdvCalendar.findEventsWithOptions(findOpts.*) RETURNING evArr,err
  IF err IS NULL AND evArr.getLength()==1 THEN
    RETURN evArr[1].*
  END IF
  INITIALIZE event.* TO NULL
  RETURN event.*
END FUNCTION
