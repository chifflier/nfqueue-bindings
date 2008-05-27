all:
	[ -d build ] || mkdir build; \
	cd build && cmake .. && $(MAKE)

clean:
	rm -rf build
