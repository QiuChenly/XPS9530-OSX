#!/bin/sh

# Bold / Non-bold
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[1;34m"
#echo -e "\033[0;32mCOLOR_GREEN\t\033[1;32mCOLOR_LIGHT_GREEN"
OFF="\033[m"

# Repository location
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
GIT_DIR="${REPO}"

# SSDT variables
SSDT_DptfTabl=""
SSDT_SaSsdt=""
SSDT_SgPeg=""
SSDT_OptTabl=""
	
locate_ssdt()
{
	SSDT_DptfTabl=$(grep -l "DptfTabl" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located DptfTabl SSDT in ${SSDT_DptfTabl}"
		
	SSDT_SaSsdt=$(grep -l "SaSsdt" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located SaSsdt SSDT in ${SSDT_SaSsdt}"

	SSDT_SgPeg=$(grep -l "SgPeg" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located SgPeg SSDT in ${SSDT_SgPeg}"
	
	SSDT_OptTabl=$(grep -l "OptTabl" $1/*.dsl)	
	echo "${BLUE}[SSDT]${OFF}: Located OptTabl SSDT in ${SSDT_OptTabl}"
}

git_update()
{
	cd ${REPO}
	echo "${GREEN}[GIT]${OFF}: Updating local data to latest version"
	
	echo "${BLUE}[GIT]${OFF}: Updating to latest XPS9530-OSX git master"
	git pull
	
	echo "${BLUE}[GIT]${OFF}: Initializing Laptop-DSDT-Patch & ssdtPRgen"
	git submodule update --init --recursive
	
	echo "${BLUE}[GIT]${OFF}: Updating Laptop-DSDT-Patch & ssdtPRgen"
	git submodule foreach git pull origin master
}

decompile_dsdt() 
{
	echo "${GREEN}[DSDT]${OFF}: Decompiling DSDT / SSDT in ./DSDT/raw"
	cd "${REPO}"
	
	./tools/iasl -w1 -da -dl ./DSDT/raw/DSDT.aml ./DSDT/raw/SSDT-*.aml &> ./logs/dsdt_decompile.log
	echo "${BLUE}[DSDT]${OFF}: Log created in ./logs/dsdt_decompile.log"
	
	locate_ssdt ./DSDT/raw
	
	rm ./DSDT/decompiled/* 2&>/dev/null
	cp -v ./DSDT/raw/DSDT.dsl ./DSDT/decompiled/
	cp -v ${SSDT_DptfTabl} ./DSDT/decompiled/	
	cp -v ${SSDT_SaSsdt} ./DSDT/decompiled/	
	cp -v ${SSDT_SgPeg} ./DSDT/decompiled/
	cp -v ${SSDT_OptTabl} ./DSDT/decompiled/
}

patch_dsdt()
{
	echo "${GREEN}[DSDT]${OFF}: Patching DSDT / SSDT"
	
	locate_ssdt ./DSDT/decompiled
	
	echo "${BLUE}[DSDT]${OFF}: Patching DSDT in ./DSDT/decompiled"
	
	echo "${BOLD}[syn] Fix PARSEOP_ZERO Error${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/syntax/fix_PARSEOP_ZERO.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/syntax/fix_PARSEOP_ZERO.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[syn] Fix ADBG Error${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/syntax/fix_ADBG.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/syntax/fix_ADBG.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[usb] Fix USB _PRW${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/usb/usb_prw_0x0d_xhc.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/usb/usb_prw_0x0d_xhc.txt ./DSDT/decompiled/DSDT.dsl
	
	echo "${BOLD}[bat] Acer Aspire E1-571${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/battery/battery_Acer-Aspire-E1-571.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/battery/battery_Acer-Aspire-E1-571.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] IRQ Fix${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_IRQ.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_IRQ.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] SMBus Fix${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_SMBUS.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_SMBUS.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] AC Adapter Fix${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_ADP1.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_ADP1.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Add MCHC${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_MCHC.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_MCHC.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Fix _WAK Arg0 v2${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_WAK2.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_WAK2.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Add IMEI${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_IMEI.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_IMEI.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] Fix Non-zero Mutex${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/system/system_Mutex.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_Mutex.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}[sys] OS Check Fix${OFF} - ${GREEN}/DSDT/patches/system_OSYS.txt${OFF}"
	#./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/system/system_OSYS.txt ./DSDT/decompiled/DSDT.dsl
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_OSYS.txt ./DSDT/decompiled/DSDT.dsl
	
#	echo "${BOLD}[sys] Add Haswell LPC${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/misc/misc_Haswell-LPC.txt${OFF}"
#	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./externals/Laptop-DSDT-Patch/misc/misc_Haswell-LPC.txt ./DSDT/decompiled/DSDT.dsl
	
	echo "${BOLD}Audio Layout${OFF} - ${GREEN}/DSDT/patches/audio_HDEF-layout1.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/audio_HDEF-layout1.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}Rename B0D3 to HDAU${OFF} - ${GREEN}/DSDT/patches/audio_B0D3_HDAU.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/audio_B0D3_HDAU.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}Remove GLAN device${OFF} - ${GREEN}/DSDT/patches/remove_glan.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/remove_glan.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}Renaming PNP devices${OFF} - ${GREEN}/DSDT/patches/misc_devices.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/misc_devices.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}System Deep Idle${OFF} - ${GREEN}/DSDT/patches/system_deep_idle.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_deep_idle.txt ./DSDT/decompiled/DSDT.dsl

	echo "${BOLD}System Deep Sleep${OFF} - ${GREEN}/DSDT/patches/system_deep_sleep.txt${OFF}"
	./tools/patchmatic ./DSDT/decompiled/DSDT.dsl ./DSDT/patches/system_deep_sleep.txt ./DSDT/decompiled/DSDT.dsl

	########################
	# SSDT-DptfTabl Patches
	########################

	echo "${BLUE}[SSDT-DptfTabl]${OFF}: Patching ${SSDT_DptfTabl}"

	echo "${BOLD}_BST package size${OFF} - ${GREEN}/DSDT/patches/_BST-package-size.txt${OFF}"
	./tools/patchmatic ${SSDT_DptfTabl} ./DSDT/patches/_BST-package-size.txt ${SSDT_DptfTabl}

	echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt${OFF}"
	./tools/patchmatic ${SSDT_DptfTabl} ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ${SSDT_DptfTabl}

	########################
	# SSDT-SaSsdt Patches
	########################

	echo "${BLUE}[SSDT-SaSsdt]${OFF}: Patching ${SSDT_SaSsdt}"

	echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ${SSDT_SaSsdt}

	echo "${BOLD}Haswell HD4400/HD4600/HD5000${OFF} - ${GREEN}/DSDT/patches/graphics_Intel_HD4600.txt${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./DSDT/patches/graphics_Intel_HD4600.txt ${SSDT_SaSsdt}

	echo "${BOLD}[gfx] Brightness fix (Haswell)${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_PNLF_haswell.txt${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./externals/Laptop-DSDT-Patch/graphics/graphics_PNLF_haswell.txt ${SSDT_SaSsdt}

	echo "${BOLD}Rename B0D3 to HDAU${OFF} - ${GREEN}/DSDT/patches/audio_B0D3_HDAU.txt${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./DSDT/patches/audio_B0D3_HDAU.txt ${SSDT_SaSsdt}

	echo "${BOLD}Insert HDAU device${OFF} - ${GREEN}/DSDT/patches/audio_Intel_HD4600.txt${OFF}"
	./tools/patchmatic ${SSDT_SaSsdt} ./DSDT/patches/audio_Intel_HD4600.txt ${SSDT_SaSsdt}

	########################
	# SSDT-SgPeg Patches
	########################

	echo "${BLUE}[SSDT-SgPeg]${OFF}: Patching ${SSDT_SgPeg}"	

	echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt${OFF}"
	./tools/patchmatic ${SSDT_SgPeg} ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ${SSDT_SgPeg}

	########################
	# SSDT-OptTabl Patches
	########################

	echo "${BLUE}[SSDT-OptTabl]${OFF}: Patching ${SSDT_OptTabl}"	

	echo "${BOLD}Remove invalid operands${OFF} - ${GREEN}/DSDT/patches/WMMX-invalid-operands.txt${OFF}"
	./tools/patchmatic ${SSDT_OptTabl} ./DSDT/patches/WMMX-invalid-operands.txt ${SSDT_OptTabl}

	echo "${BOLD}[gfx] Rename GFX0 to IGPU${OFF} - ${GREEN}/externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt${OFF}"
	./tools/patchmatic ${SSDT_OptTabl} ./externals/Laptop-DSDT-Patch/graphics/graphics_Rename-GFX0.txt ${SSDT_OptTabl}

	echo "${BOLD}Disable Nvidia card (Non-operational in OS X)${OFF} - ${GREEN}/DSDT/patches/graphics_Disable_Nvidia.txt${OFF}"
	./tools/patchmatic ${SSDT_OptTabl} ./DSDT/patches/graphics_Disable_Nvidia.txt ${SSDT_OptTabl}
}

compile_dsdt()
{
	echo "${GREEN}[DSDT]${OFF}: Compiling DSDT / SSDT in ./DSDT/compiled"
	cd "${REPO}"
	
	locate_ssdt ./DSDT/decompiled

	rm ./DSDT/compiled/*
	
	echo "${BLUE}[SSDT]${OFF}: Copying untouched original SSDTs to ./DSDT/compiled"
	grep -L "DptfTabl\|SaSsdt\|SgPeg\|OptTabl" ./DSDT/raw/SSDT-[0-9].aml ./DSDT/raw/SSDT-[1-9][0-9].aml | xargs -I{} cp -v {} ./DSDT/compiled

	echo "${BLUE}[DSDT]${OFF}: Compiling DSDT to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/DSDT.aml -I ./DSDT/decompiled/ ./DSDT/decompiled/DSDT.dsl

	echo "${BLUE}[SSDT-10]${OFF}: Compiling SSDT-DptfTabl to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_DptfTabl}`aml -I ./DSDT/decompiled/ ${SSDT_DptfTabl}

	echo "${BLUE}[SSDT-12]${OFF}: Compiling SSDT-SaSsdt to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_SaSsdt}`aml -I ./DSDT/decompiled/ ${SSDT_SaSsdt}

	echo "${BLUE}[SSDT-13]${OFF}: Compiling SSDT-SgPeg to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_SgPeg}`aml -I ./DSDT/decompiled/ ${SSDT_SgPeg}

	echo "${BLUE}[SSDT-15]${OFF}: Compiling SSDT-OptTabl to ./DSDT/compiled"
	./tools/iasl -vr -w1 -ve -p ./DSDT/compiled/`basename -s dsl ${SSDT_OptTabl}`aml -I ./DSDT/decompiled/ ${SSDT_OptTabl}

	# Additional custom SSDT
	# ssdtPRgen (P-states / C-states)
#	if [[ `sysctl machdep.cpu.brand_string` == *"i7-4702HQ"* ]]
#	then
#		echo "${BLUE}[SSDT-pr]${OFF}: Intel ${BOLD}i7-4702HQ${OFF} processor found"
#		echo "${BLUE}[SSDT-pr]${OFF}: Installing SSDT-pr (CPU P-States / C-States) to ./DSDT/compiled"
#		cp ./DSDT/custom/CpuPm-4702HQ.aml ./DSDT/compiled/SSDT-pr.aml
#	fi
	
#	if [[ `sysctl machdep.cpu.brand_string` == *"i7-4712HQ"* ]]
#	then
#		echo "${BLUE}[SSDT-pr]${OFF}: Intel ${BOLD}i7-4712HQ${OFF} processor found"
#		echo "${BLUE}[SSDT-pr]${OFF}: Installing SSDT-pr (CPU P-States / C-States) to ./DSDT/compiled"
#		cp ./DSDT/custom/CpuPm-4712HQ.aml ./DSDT/compiled/SSDT-pr.aml
#	fi
	
	# Rehabman NullEthernet.kext
	echo "${BLUE}[RMNE]${OFF}: Installing SSDT-rmne (Rehabmans NullEthernet) to ./DSDT/compiled"
		cp ./DSDT/custom/SSDT-rmne.aml ./DSDT/compiled/SSDT-rmne.aml
}

patch_iokit_execute()
{
	# OS X - 10.9, 10.10, 10.11
	sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
	sudo codesign -f -s - /System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit
	echo "         Patched"
}

patch_coredisplay_execute()
{
	# OS X - 10.12
	sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay
	sudo codesign -f -s - /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay
	echo "         Patched"
}

patch_iokit()
{
	iokit_md5=$(md5 -q "/System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit")

	echo "${GREEN}[IOKit]${OFF}: Patching IOKit for maximum pixel clock"
	echo "${BLUE}[IOKit]${OFF}: Current IOKit md5 is ${BOLD}${iokit_md5}${OFF}"
	
	case $iokit_md5 in
		"2a8cbc2f6616d3f7a5e499bd2d5593ab")
		echo "         --> Yosemite 10.10.1 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"a94dc8e1b6bb6491e5f610f0a3caf960")
		echo "         --> Yosemite 10.10.2 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"29d7632362b2fa4993156717671a5642")
		echo "         --> Yosemite 10.10.3 / 10.10.4 / 10.10.5 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"131978134faf623c7803458c2a204d60")
		echo "         --> El Capitan 10.11 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"7359b413a4dca7a189b80da750ce43dd")
		echo "         --> El Capitan 10.11.1 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"a7afb2dd9df1e4c48f12b4b52f7da212")
		echo "         --> El Capitan 10.11.2 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"3cec8ae287ee52a3622082bfc049bb86")
		echo "         --> El Capitan 10.11.3 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"50fef4db03f5680e83c6bbb969e3e85e")
		echo "         --> El Capitan 10.11.4 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"a73dd1ed37da96000958bb781ce4ac15")
		echo "         --> El Capitan 10.11.5 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute
		;;
		"2c22a2f92d07ba79bb1c76c0ebdff9a3")
		echo "         --> Sierra 10.12 DP1 IOKit (${GREEN}unpatched${OFF})"
		patch_iokit_execute_v2
		;;
		*)
		echo "         --> Unknown IOKit version or already patched (${RED}no action taken${OFF})"
		echo "         Do you want to try and apply the patch nontheless?"
			select yn in "Yes" "No"; do
				case $yn in
					Yes)
					patch_iokit_execute;
					break
					;;
					No)
					exit
					;;
				esac
			done
		;;
	esac
}

patch_coredisplay()
{
	coredisplay_md5=$(otool -t "/System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay" | tail -n +3 | md5)

	echo "${GREEN}[CoreDisplay]${OFF}: Patching CoreDisplay for maximum pixel clock"
	echo "${BLUE}[CoreDisplay]${OFF}: Current CoreDisplay md5 is ${BOLD}${coredisplay_md5}${OFF}"
	
	case $coredisplay_md5 in
		"079c6486d738f8df31c79c65f596af77")
		echo "         --> Sierra 10.12.2 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"ce726e38a99d9a6958c8694b1f5f57cb")
		echo "         --> Sierra 10.12.3 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"079c6486d738f8df31c79c65f596af77")
		echo "         --> Sierra 10.12.3 CoreDisplay (${RED}already patched${OFF})"
		;;
		"c9013fcb63e494db278eebedefb2f9a0")
		echo "         --> Sierra 10.12.4 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"8880d8a0cbfcd8590d8ff689b20009d6")
		echo "         --> Sierra 10.12.4 CoreDisplay (${RED}already patched${OFF})"
		;;
		"e83c022c40e3bb1db2ca999a27b5eaef")
		echo "         --> Sierra 10.12.5 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"8d4dee6b0bc6df6280657d4ac1e1a771")
		echo "         --> Sierra 10.12.5 CoreDisplay (${RED}already patched${OFF})"
		;;
		"92d32cfeefdfc3abcff0d1cd8bd43e1d")
		echo "         --> Sierra 10.12.6 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"11c758b3faa252c998cb3624c81b3d09")
		echo "         --> Sierra 10.12.6 CoreDisplay (${RED}already patched${OFF})"
		;;
		"f2a57f30bf9595f4a78aa8cdacf1a853")
		echo "         --> High Sierra 10.13.0 CoreDisplay (${GREEN}unpatched${OFF})"
		patch_coredisplay_execute
		;;
		"21ff29bdb15d544ce7c9619d8a028774")
		echo "         --> High Sierra 10.13.0 CoreDisplay (${RED}already patched${OFF})"
		;;
		*)
		echo "         --> Unknown CoreDisplay version (${coredisplay_md5}) or already patched (${RED}no action taken${OFF})"
		echo "         Do you want to try and apply the patch nontheless?"
			select yn in "Yes" "No"; do
				case $yn in
					Yes)
					patch_coredisplay_execute;
					break
					;;
					No)
					exit
					;;
				esac
			done
		;;
	esac
}

patch_pixel_clock()
{
	if [ -f /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay ]
	then
		patch_coredisplay
	else
		patch_iokit	
	fi
}

patch_hda()
{
	echo "${GREEN}[HDA]${OFF}: Creating AppleHDA injection kernel extension for ${BOLD}ALC668${OFF}"
	cd "${REPO}"
	
	plist=./audio/AppleHDA_ALC668.kext/Contents/Info.plist
	
	echo "       --> ${BOLD}Creating AppleHDA_ALC668 file layout${OFF}"
	rm -R ./audio/AppleHDA_ALC668.kext 2&>/dev/null
	
	cp -R /System/Library/Extensions/AppleHDA.kext ./audio/AppleHDA_ALC668.kext
	rm -R ./audio/AppleHDA_ALC668.kext/Contents/Resources/*
	rm -R ./audio/AppleHDA_ALC668.kext/Contents/PlugIns
	rm -R ./audio/AppleHDA_ALC668.kext/Contents/_CodeSignature
	rm -R ./audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA
	rm ./audio/AppleHDA_ALC668.kext/Contents/version.plist
	ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA ./audio/AppleHDA_ALC668.kext/Contents/MacOS/AppleHDA

	echo "       --> ${BOLD}Copying AppleHDA_ALC668 audio platform & layouts${OFF}"
	cp ./audio/*.zlib ./audio/AppleHDA_ALC668.kext/Contents/Resources/

	echo "       --> ${BOLD}Configuring AppleHDA_ALC668 Info.plist${OFF}"
	replace=`/usr/libexec/plistbuddy -c "Print :NSHumanReadableCopyright" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :NSHumanReadableCopyright '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleGetInfoString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleGetInfoString '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleVersion" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleVersion '$replace'" $plist
	replace=`/usr/libexec/plistbuddy -c "Print :CFBundleShortVersionString" $plist | perl -Xpi -e 's/(\d*\.\d*)/9\1/'`
	/usr/libexec/plistbuddy -c "Set :CFBundleShortVersionString '$replace'" $plist
	/usr/libexec/plistbuddy -c "Add ':HardwareConfigDriver_Temp' dict" $plist
	/usr/libexec/plistbuddy -c "Merge /System/Library/Extensions/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist ':HardwareConfigDriver_Temp'" $plist
	/usr/libexec/plistbuddy -c "Copy ':HardwareConfigDriver_Temp:IOKitPersonalities:HDA Hardware Config Resource' ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
	/usr/libexec/plistbuddy -c "Delete ':HardwareConfigDriver_Temp'" $plist
	/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $plist
	/usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $plist
	/usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $plist
	/usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
	/usr/libexec/plistbuddy -c "Merge ./audio/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
    
	echo "       --> ${BOLD}Created AppleHDA_ALC668.kext${OFF}"
	sudo cp -r ./audio/AppleHDA_ALC668.kext /Library/Extensions
	echo "       --> ${BOLD}Installed AppleHDA_ALC668.kext to /Library/Extensions${OFF}"
#	sudo cp -r ./audio/CodecCommander.kext /Library/Extensions
#	echo "       --> ${BOLD}Installed CodecCommander.kext to /Library/Extensions${OFF}"
}

enable_trim()
{
	echo "${GREEN}[TRIM]${OFF}: Enabling ${BOLD}TRIM${OFF} support for 3rd party SSD"
	sudo trimforce enable
}

enable_3rdparty()
{
	echo "${GREEN}[3rd Party${OFF}: Enabling ${BOLD}3rd Party${OFF} application support"
	sudo spctl --master-disable
}

RETVAL=0

case "$1" in
	--update)
		git_update
		RETVAL=1
		;;
	--decompile-dsdt)
		decompile_dsdt
		RETVAL=1
		;;
	--compile-dsdt)
		compile_dsdt
		RETVAL=1
		;;
	--patch-dsdt)
		patch_dsdt
		RETVAL=1
		;;
	--patch-pixelclock)
		patch_pixel_clock
		RETVAL=1
		;;
	--patch-hda)
		patch_hda
		RETVAL=1
		;;
	--enable-trim)
		enable_trim
		RETVAL=1
		;;
	--enable-3rdparty)
		enable_3rdparty
		RETVAL=1
		;;
	*)
		echo "${BOLD}Dell XPS 9530${OFF} - El Capitan 10.12.2 (16C68)"
		echo "https://github.com/robvanoostenrijk/XPS9530-OSX"
		echo
		echo "\t${BOLD}--update${OFF}: Update to latest git version (including externals)"
		echo "\t${BOLD}--decompile-dsdt${OFF}: Decompile DSDT files in ./DSDT/raw"
		echo "\t${BOLD}--patch-dsdt${OFF}: Patch DSDT files in ./DSDT/decompiled"
		echo "\t${BOLD}--compile-dsdt${OFF}: Compile DSDT files to ./DSDT/compiled"
		echo "\t${BOLD}--patch-pixelclock${OFF}: Patch maximum pixel clock in IOKit / CoreDisplay"
		echo "\t${BOLD}--patch-hda${OFF}: Create AppleHDA injector kernel extension"
		echo "\t${BOLD}--enable-trim${OFF}: Enable trim support for 3rd party SSD"
		echo "\t${BOLD}--enable-3rdparty${OFF}: Enable 3rd party application support (run app from anywhere)"
		echo
		echo "Credits:"
		echo "${BLUE}Laptop-DSDT${OFF}: https://github.com/RehabMan/Laptop-DSDT-Patch"
		echo "${BLUE}ssdtPRgen${OFF}: https://github.com/Piker-Alpha/ssdtPRGen.sh"
		echo "${BLUE}AppleHDA ALC668${OFF}: https://github.com/vbourachot/Dell-XPS13-9333-DSDT-Patch/"
		echo "${BLUE}AppleALC${OFF}: https://github.com/vit9696/AppleALC"
		echo
		RETVAL=1
	    ;;
esac

exit $RETVAL
