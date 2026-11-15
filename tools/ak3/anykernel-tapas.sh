### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## Adapted for Redmi Note 12 4G (tapas/topaz) Linux 6.18 ACK by SanketRohilla

### AnyKernel setup
# global properties
properties() { '
kernel.string=Linux 6.18.32 ACK for Redmi Note 12 4G (tapas/topaz) by SanketRohilla
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=tapas
device.name2=topaz
device.name3=tapasn
device.name4=topazn
device.name5=spes
device.name6=spesn
device.name7=SM6225
device.name8=sm6225
device.name9=khaje
supported.versions=13 - 16
'; } # end properties

### AnyKernel install
BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot;
flash_boot;
## end boot install
