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
BUNDLE_IDENTIFIER_GMA = com.fourjs.cdvcalendar
APPNAME             = CDVCalendar
DEVICE              = simulator
MODE                = debug
IDENTITY='(59W7RY75ZU)'
PROVISIONING_PROFILE=/Users/leo/Library/MobileDevice/Provisioning\ Profiles/4js_wildcard
INSTALL=yes

PLUGIN=Calendar-PhoneGap-Plugin
# in case you build the demo when having the plugin checked out of github 
# then we use the fglcvdCalendar.42m in the fgl dir of the plugin
ifneq ($(wildcard ../../fgldemo),)
  PLUGIN=../..
  export FGLLDPATH=../../fgl
# figure out the directory name of the plugin because 
# gmabuildtool can't handle a plugin name like ../..
# in the scaffold --install-plugin option
  ABSPATH=$(abspath .)
  DEMODIR=$(shell  dirname $(ABSPATH))
  PLUGINDIR=$(shell dirname $(DEMODIR))
  GMAPLUGIN=$(notdir $(PLUGINDIR))
# $(warning ABSPATH=$(ABSPATH),DEMODIR=$(DEMODIR),PLUGINDIR=$(PLUGINDIR),GMAPLUGIN=$(GMAPLUGIN))
else
  GMAPLUGIN=$(PLUGIN)
endif

MODULES  = $(patsubst %.4gl, %.42m, $(wildcard *.4gl))
FORMS    = $(patsubst %.per, %.42f, $(wildcard *.per))

%.42m: %.4gl
	fglcomp -M $*

%.42f: %.per
	fglform -M $*

all:: $(MODULES) $(FORMS)

ifneq ($(wildcard ../../fgldemo),)
FGLCDVCALENDAR_42M=../../fgl/fglcdvCalendar.42m
../../fgl/fglcdvCalendar.42m: ../../fgl/fglcdvCalendar.4gl
	$(MAKE) -C ../../fgl
endif
main.42m: $(FGLCDVCALENDAR_42M) calendars.42f events.42f newevent.42f

run: main.42m
	fglrun main

gmi.build: all
	gmibuildtool --app-name=$(APPNAME) --bundle-id=$(BUNDLE_IDENTIFIER) --provisioning=$(PROVISIONING_PROFILE) --certificate=$(IDENTITY) --device=$(DEVICE) --install=no --mode=$(MODE) --build-cordova=$(PLUGIN)

gmi.install: all
	gmibuildtool --app-name=$(APPNAME) --bundle-id=$(BUNDLE_IDENTIFIER) --provisioning=$(PROVISIONING_PROFILE) --certificate=$(IDENTITY) --device=$(DEVICE) --install=$(INSTALL) --mode=$(MODE) --build-cordova=$(PLUGIN)

gma.build: all
ifneq ($(wildcard ../../fgldemo),)
#build the plugin out of this repository and do not use the bundled one
	rm -rf project
	gmabuildtool scaffold --install-plugins ../../../$(GMAPLUGIN)
endif
	gmabuildtool build -map main.42m --build-quietly --build-cordova $(GMAPLUGIN) --build-app-name $(APPNAME) --build-app-package-name $(BUNDLE_IDENTIFIER_GMA) 


gma.install: gma.build
#	adb install -r ./gma/project/app/build/app/outputs/apk/app-unsigned.apk
	adb install -r project/build/app/outputs/apk/gma/app.apk

clean::
	rm -rf build bin distbin gma project
	rm -f *.42* gmi/*.a gmi/link_flags.sh *.4pwvs *.4pwdb
ifneq ($(wildcard ../../fgldemo),)
	rm -f ../../fgl/fglcdvCalendar.42m
endif
