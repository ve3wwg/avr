for f in ../avr-ada-1.2.2/patches/gcc/4.7.2/*.patch; do 
	patch -p0 < "$f"
done
