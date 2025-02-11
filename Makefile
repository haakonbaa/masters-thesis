PROJECT = main
SRC_DIR = ./src
BUILD_DIR_ROOT = build
BUILD_DIR = ../$(BUILD_DIR_ROOT)
LATEX_ARGS = -output-directory=$(BUILD_DIR) -interaction=errorstopmode \
			 -shell-escape
BIBER_ARGS = --output-directory $(BUILD_DIR) -quiet
GLOS_ARGS = -d $(BUILD_DIR) -q

# Diff settings
DIFF_OLD = "main"
DIFF_NEW = "HEAD"

# Targets
.PHONY: all clean small diff

all: $(BUILD_DIR)/$(PROJECT).pdf

# we need to run pdflatex multiple times to get the references right :(
$(BUILD_DIR)/$(PROJECT).pdf: $(SRC_DIR)/$(PROJECT).tex
	mkdir -p $(BUILD_DIR_ROOT)
	cd $(SRC_DIR) && pdflatex $(LATEX_ARGS) $(PROJECT).tex
	cd $(SRC_DIR) && biber $(BIBER_ARGS) $(PROJECT)
	cd $(SRC_DIR) && makeglossaries $(GLOS_ARGS) $(PROJECT)
	cd $(SRC_DIR) && pdflatex $(LATEX_ARGS) $(PROJECT).tex
	cd $(SRC_DIR) && pdflatex $(LATEX_ARGS) $(PROJECT).tex

# fast compilation, but no bibliography
small: $(SRC_DIR)/$(PROJECT).tex
	mkdir -p $(BUILD_DIR_ROOT)
	cd $(SRC_DIR) && pdflatex $(LATEX_ARGS) $(PROJECT).tex

diff: $(SRC_DIR)/$(PROJECT).tex
	# create a diff between
	rm -rf $(BUILD_DIR_ROOT)/diff
	mkdir -p $(BUILD_DIR_ROOT)/diff/v1
	mkdir -p $(BUILD_DIR_ROOT)/diff/v2
	#git --work-tree=$(BUILD_DIR_ROOT)/diff/v1 checkout $(DIFF_OLD) -- src
	cd $(BUILD_DIR_ROOT)/diff && git clone -b $(DIFF_OLD) ../.. v1
	#cp -r src $(BUILD_DIR_ROOT)/diff/v1;
	# to create a diff between two commits
	#git --work-tree=$(BUILD_DIR_ROOT)/diff/v2 checkout $(DIFF_NEW) -- src;
	cp -r src $(BUILD_DIR_ROOT)/diff/v2;
	cp ./Makefile $(BUILD_DIR_ROOT)/diff/v2
	latexdiff --flatten $(BUILD_DIR_ROOT)/diff/v1/src/$(PROJECT).tex \
		$(BUILD_DIR_ROOT)/diff/v2/src/$(PROJECT).tex > \
		$(BUILD_DIR_ROOT)/diff/v2/src/main-diff.tex
	cd $(BUILD_DIR_ROOT)/diff/v2 && make all PROJECT=main-diff
	mv $(BUILD_DIR_ROOT)/diff/v2/build/main-diff.pdf $(BUILD_DIR_ROOT)/diff.pdf

clean:
	rm -rf $(BUILD_DIR_ROOT)/*
