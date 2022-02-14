NAME = mst

NVCC = nvcc
KLAP = klap
THRESHOLD_T := 128
COARSE_FACTOR := 4
THRESHOLD_AGG := 1
GRANULARITY := 32

ARCH = -gencode arch=compute_35,code=sm_35 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_70,code=compute_70
FLAGS = -Xcompiler '-fPIC' -dc -m64 --default-stream per-thread

INCLUDE  = -I. -I../../include
MACROS = -D__THRESHOLD_T=$(THRESHOLD_T) -D__COARSE_FACTOR=$(COARSE_FACTOR) -DTHRESHOLD_AGG=$(THRESHOLD_AGG) -D__GRANULARITY=$(GRANULARITY)
SRC = main.cu
OBJ = $(SRC:.cu=.o)

BIN = $(NAME).nocdp $(NAME).cdp $(NAME).aw $(NAME).ab $(NAME).ag $(NAME).dag $(NAME).tcdp $(NAME).taw $(NAME).tab $(NAME).tag $(COARSENING_VERSIONS) $(NAME).ctdag1
COARSENING_VERSIONS = $(NAME).ccdp1 $(NAME).caw1 $(NAME).cab1 $(NAME).cag1  $(NAME).ctcdp1 $(NAME).ctaw1 $(NAME).ctab1 $(NAME).ctag1
EXPERIMENTAL = $(NAME).ccdp2 $(NAME).ccdp3 $(NAME).caw2 $(NAME).cab2 $(NAME).cag2 $(NAME).caw3 $(NAME).cab3 $(NAME).cag3 $(NAME).ctcdp2 $(NAME).ctaw2 $(NAME).ctab2 $(NAME).ctag2 $(NAME).ctcdp3 $(NAME).ctaw3 $(NAME).ctab3 $(NAME).ctag3

cdp: $(NAME).cdp

tcdp: $(NAME).tcdp

all: $(BIN)

.SECONDARY:

kernel.a%.cu: kernel.de.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.da%.cu: kernel.de.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.de.cu: kernel.cdp.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

%.o: %.cu
	$(NVCC) $(ARCH) $(FLAGS) $(INCLUDE) -o $@ -c $< $(MACROS) "-maxrregcount=64"

$(NAME).%: kernel.%.o $(OBJ)
	$(NVCC) $(ARCH) -o $@ $+ -lcudadevrt "-maxrregcount=64"

clean:
	rm -f *.o $(BIN) $(EXPERIMENTAL) kernel.?cdp.cu kernel.ctcdp.cu kernel.a?.cu kernel.ta?.cu kernel.ca??.cu kernel.cta?.cu kernel.de.cu kernel.?de.cu kernel.ctde.cu kernel.ccdp?.cu kernel.cde?.cu kernel.ctde?.cu kernel.ca??.cu kernel.cta??.cu kernel.ctcdp?.cu kernel.dag.cu kernel.cda* kernel.t* kernel.ctda*.cu

test:
	./test.sh

test-all: all
	./test.sh

kernel.tcdp.cu: kernel.cdp.cu
	$(KLAP) $< -t te -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib
	$(KLAP) $@ -t sk -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib
	$(KLAP) $@ -t th -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.tde.cu: kernel.tcdp.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ta%.cu: kernel.tde.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.tda%.cu: kernel.tde.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ctde1.cu: kernel.ctcdp1.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ctde2.cu: kernel.ctcdp2.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ctde3.cu: kernel.ctcdp3.cu
	$(KLAP) $< -t de -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib $(MACROS)

kernel.ctcdp1.cu: kernel.tcdp.cu
	$(KLAP) $< -t tc1 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ctcdp2.cu: kernel.tcdp.cu
	$(KLAP) $< -t tc2 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ctcdp3.cu: kernel.tcdp.cu
	$(KLAP) $< -t tc3 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.cta%1.cu: kernel.ctde1.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2 | tr -d '1'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ctda%1.cu: kernel.ctde1.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2 | tr -d '1'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.cta%2.cu: kernel.ctde2.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2 | tr -d '2'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.cta%3.cu: kernel.ctde3.cu
	$(KLAP) $< -t `echo $@ | cut -d '.' -f2 | cut -d 't' -f2 | tr -d '3'` -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ccdp1.cu: kernel.cdp.cu
	$(KLAP) $< -t tc1 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ccdp2.cu: kernel.cdp.cu
	$(KLAP) $< -t tc2 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

kernel.ccdp3.cu: kernel.cdp.cu
	$(KLAP) $< -t tc3 -o $@ -- --cuda-device-only $(INCLUDE) --no-cuda-version-check -nocudalib

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
