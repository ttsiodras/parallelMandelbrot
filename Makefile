.PHONY:	bench clean

CPUS=2 # I use a Core2Duo

TARGETS = mandel

all:	${TARGETS} bench

% : %.hs
	#ghc -o $@ -W -fglasgow-exts -O --make $<
	ghc -threaded -o $@ -W -fglasgow-exts -O2 -fforce-recomp -fexcess-precision -funbox-strict-fields  --make $< -fvia-c -optc-O3 -optc-ffast-math -funfolding-keeness-factor=10 +RTS  -qb0 -N${CPUS} -RTS -feager-blackholing 

bench:	${TARGETS}
	@for i in $^ ; do echo Output of $${i}... ; ./$$i 1 > data.pnm && display ./data.pnm ; for j in `seq 1 8` ; do echo Benchmarking 3 times with $$j threads... ; time ./$$i $$j > /dev/null ;  time ./$$i $$j > /dev/null ;  time ./$$i $$j > /dev/null ; done ; done

clean:
	rm -f *.o *.hi data.pnm ${TARGETS}
