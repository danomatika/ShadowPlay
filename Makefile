
PACK = shadowplay-composerpack

.PHONY: composerpack clean

all: composerpack

composerpack: $(PACK).zip

$(PACK).zip:
	mkdir -p $(PACK)
	cp -R pd/* $(PACK)/
	cp -R composerpack/* $(PACK)/
	zip -r $(PACK) $(PACK)

clean:
	rm -rf $(PACK) $(PACK).zip
