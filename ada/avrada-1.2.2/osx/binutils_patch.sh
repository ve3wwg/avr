for f in ../avr-ada-1.2.2/patches/binutils/2.20.1/*.patch; do
    patch -p0 <"$f"
done
