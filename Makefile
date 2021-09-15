
PACK = shadowplay-composerpack

.PHONY: composerpack clean

all: composerpack

composerpack: $(PACK).zip

$(PACK).zip:
	mkdir -p $(PACK)
	cp pd/qlister.pd $(PACK)/
	cp -R pd/theremin $(PACK)/
	cp -R composerpack/* $(PACK)/
	zip -r $(PACK) $(PACK) -x "*.DS_Store"

clean:
	rm -rf $(PACK) $(PACK).zip
