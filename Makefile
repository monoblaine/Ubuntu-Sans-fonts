SOURCES=$(shell python3 scripts/read-config.py --sources )
FAMILY=$(shell python3 scripts/read-config.py --family )
DRAWBOT_SCRIPTS=$(shell ls documentation/*.py)
DRAWBOT_OUTPUT=$(shell ls documentation/*.py | sed 's/\.py/.png/g')

help:
	@echo "###"
	@echo "# Build targets for $(FAMILY)"
	@echo "###"
	@echo
	@echo "  make build:  Builds the fonts and places them in the fonts/ directory"
	@echo "  make test:   Tests the fonts with fontbakery"
	@echo "  make proof:  Creates HTML proof documents in the proof/ directory"
	@echo "  make images: Creates PNG specimen images in the documentation/ directory"
	@echo

build: build.stamp

dev: venv .init.stamp sources/config-dev.yaml $(SOURCES)
	. venv/bin/activate; rm -rf fonts/; gftools builder sources/config-dev.yaml; python3 scripts/fixGDEF.py; python3 scripts/addVersionToNames.py ./fonts/variable;

venv: venv/touchfile

build.stamp: venv .init.stamp sources/config.yaml $(SOURCES)
	. venv/bin/activate; rm -rf fonts/; gftools builder sources/config.yaml && touch build.stamp; rm -rf instance_ufo/; python3 scripts/fixStaticsNames.py; python3 scripts/fixGDEF.py; python3 scripts/fixTTHinting.py; python3 scripts/makeWebfonts.py

.init.stamp: venv
	. venv/bin/activate; python3 scripts/first-run.py

venv/touchfile: requirements.txt
	test -d venv || python3 -m venv venv
	. venv/bin/activate; pip install -Ur requirements.txt
	touch venv/touchfile

test: venv build.stamp
	. venv/bin/activate; mkdir -p out/ out/fontbakery; fontbakery check-googlefonts -l WARN --succinct --badges out/badges --html out/fontbakery/fontbakery-report.html --ghmarkdown out/fontbakery/fontbakery-report.md $(shell find fonts/ttf -type f)

testvf: venv build.stamp
	. venv/bin/activate; mkdir -p out/ out/fontbakery; fontbakery check-googlefonts -l WARN --succinct --badges out/badges --html out/fontbakery/fontbakery-var-report.html --ghmarkdown out/fontbakery/fontbakery-var-report.md $(shell find fonts/variable -type f)

proof: venv build.stamp
	. venv/bin/activate; mkdir -p out/ out/proof; gftools gen-html proof $(shell find fonts/ttf -type f) -o out/proof

images: venv build.stamp $(DRAWBOT_OUTPUT)
	git add documentation/*.png && git commit -m "Rebuild images" documentation/*.png

%.png: %.py build.stamp
	python3 $< --output $@

clean:
	rm -rf venv
	find . -name "*.pyc" | xargs rm delete

update-ufr:
	npx update-template https://github.com/googlefonts/Unified-Font-Repository/

update:
	pip3 install --upgrade $(dependency); pip freeze > requirements.txt
