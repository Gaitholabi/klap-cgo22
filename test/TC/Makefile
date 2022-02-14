NAME = tc

NVCC = nvcc
KLAP = klap

COARSE_FACTOR :=1
GRANULARITY := 256

MACROS = -D__COARSE_FACTOR=$(COARSE_FACTOR) -D__GRANULARITY=$(GRANULARITY)


ARCH = -gencode arch=compute_35,code=sm_35 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=compute_70
FLAGS = -Xcompiler '-fPIC' -dc -m64 --default-stream per-thread

INCLUDE  = -I. -I../../include $(MACROS)
SRC = main.cu tc.cu utilities.cu
OBJ = $(SRC:.cu=.o)
BIN = $(NAME).base $(NAME).aw $(NAME).ab $(NAME).ag $(NAME).ccdp1 $(NAME).cag1 $(NAME).cab1 $(NAME).caw1 $(NAME).ccdp2 $(NAME).cag2 $(NAME).cab2 $(NAME).caw2 $(NAME).ccdp3 $(NAME).cag3 $(NAME).cab3 $(NAME).caw3 $(NAME).cdag1 $(NAME).dag

base: $(NAME).base

all: $(BIN)

.SECONDARY:

kernel.a%.cu: kernel.de.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2` -m 53554432 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.da%.cu: kernel.de.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.de.cu: kernel.base.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

%.o: %.cu
	$(NVCC) $(ARCH) $(FLAGS) $(INCLUDE) -o $@ -c $< $(MACROS)

$(NAME).%: kernel.%.o $(OBJ)
	$(NVCC) $(ARCH) -o $@ $+ -lcudadevrt

clean:
	rm -f *.o $(BIN) $(EXPERIMENTAL) kernel.?cdp.cu kernel.ctcdp.cu kernel.a?.cu kernel.ta?.cu kernel.ca??.cu kernel.cta?.cu kernel.de.cu kernel.?de.cu kernel.ctde.cu kernel.ccdp?.cu kernel.cde?.cu kernel.ctde?.cu kernel.ca??.cu kernel.cta??.cu kernel.ctcdp?.cu kernel.dag.cu kernel.cda* kernel.t* kernel.ctda*.cu

test:
	./test.sh

test-all: all
	./test.sh

#coarsened version
kernel.ccdp1.cu: kernel.base.cu
	$(KLAP) kernel.base.cu -t tc1 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ccdp2.cu: kernel.base.cu
	$(KLAP) kernel.base.cu -t tc2 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ccdp3.cu: kernel.base.cu
	$(KLAP) kernel.base.cu -t tc3 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.cde1.cu: kernel.ccdp1.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.cde2.cu: kernel.ccdp2.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.cde3.cu: kernel.ccdp3.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ca%1.cu: kernel.cde1.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 'c' -f2 | tr -d '1'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.cda%1.cu: kernel.cde1.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 'c' -f2 | tr -d '1'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ca%2.cu: kernel.cde2.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 'c' -f2 | tr -d '2'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ca%3.cu: kernel.cde3.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 'c' -f2 | tr -d '3'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib