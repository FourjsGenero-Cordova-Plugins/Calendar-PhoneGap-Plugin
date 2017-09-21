# Property of Four Js*
# (c) Copyright Four Js 2017, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these
# samples are accurate and suitable for your purposes. Their inclusion is
# purely for information purposes only.

# calling make without parameters simply creates an GMI executable for the simulator
# use "make gmi.install" to install on the simulator or device depending on the TARGET

BUNDLE_IDENTIFIER   = com.4js.cdvcalendar
APPNAME             = CDVCalendar
DEVICE              = simulator
MODE                = debug
BUILD_FGL           = no
IDENTITY='(59W7RY75ZU)'
PROVISIONING_PROFILE=/Users/leo/Library/MobileDevice/Provisioning\ Profiles/4js_wildcard

PLUGIN=Calendar-PhoneGap-Plugin

# in case you build the demo when having the plugin checked out of github 
# then we use the fglcvdCalendar.42m in the fgl dir of the plugin
ifneq ($(wildcard ../../fgl),)
export FGLLDPATH    = ../../fgl
PLUGIN= $(CURDIR)/../..
endif

MODULES  = $(patsubst %.4gl, %.42m, $(wildcard *.4gl))
FORMS    = $(patsubst %.per, %.42f, $(wildcard *.per))

%.42m: %.4gl
	fglcomp -M $*

%.42f: %.per
	fglform -M $*

all:: $(MODULES) $(FORMS)


gmi.install: all
	gmibuildtool --app-name=$(APPNAME) --bundle-id=$(BUNDLE_IDENTIFIER) --provisioning=$(PROVISIONING_PROFILE) --certificate=$(IDENTITY) --device=$(DEVICE) --mode=$(MODE) --build-cordova=$(PLUGIN)

main.42m: calendars.42f events.42f newevent.42f

clean::
	rm -rf build bin distbin
	rm -f *.42* gmi/*.a gmi/link_flags.sh *.4pwvs *.4pwdb
