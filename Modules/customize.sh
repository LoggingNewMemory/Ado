LATESTARTSERVICE=true

ui_print "------------------------------------"
ui_print "                 Ado                "
ui_print "------------------------------------"
ui_print "         By: Kanagawa Yamada        "
ui_print "------------------------------------"
ui_print " "

ui_print "------------------------------------"
ui_print "            MODULE INFO             "
ui_print "------------------------------------"
ui_print "Name : Ado"
ui_print "Version : 4.0"
ui_print "Support Root : Magisk / KernelSU / APatch"
ui_print " "

ui_print "          Installing Ado           "
ui_print " "

unzip -o "$ZIPFILE" 'AdoKang/*' -d $MODPATH >&2
set_perm_recursive $MODPATH/AdoKang 0 0 0774 0774