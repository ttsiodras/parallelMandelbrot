.PHONY:	bench clean

TARGETS = mandel

all:	${TARGETS} bench

GHC_OPTS=-threaded -O3 -funbox-strict-fields -feager-blackholing -fexcess-precision \
	-fvia-C -fexcess-precision -optc-ffast-math -optc-O3 -optc-march=native

GHC_OPTS_P=

% : %.hs
	ghc ${GHC_OPTS} --make $< -o $@

bench:	${TARGETS}
	@echo Output of $<... ; ./$< > data.pnm && display ./data.pnm ; for j in `seq 1 2` ; do echo Benchmarking 3 times with $$j threads... ; time ./$< +RTS -N$$j -RTS > /dev/null ;  time ./$< +RTS -N$$j -RTS> /dev/null ;  time ./$< +RTS -N$$j -RTS > /dev/null ; done

clean:
	rm -f *.o *.hi data.pnm ${TARGETS}
