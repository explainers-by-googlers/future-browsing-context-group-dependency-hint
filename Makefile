SHELL=/bin/bash

bikeshed_files = index.bs

.PHONY: clean spec

spec: $(bikeshed_files:.bs=.html)

clean:
	rm -f $(bikeshed_files:.bs=.html) README.html

README.html: README.md
	pandoc -f gfm --metadata title="Explainer" -s -o $@ $<

%.html: %.bs
	@ (HTTP_STATUS=$$(curl https://api.csswg.org/bikeshed/ \
	                       --output $@ \
	                       --write-out "%{http_code}" \
	                       --header "Accept: text/plain, text/html" \
												 -F die-on=warning \
	                       -F file=@$<) && \
	[[ "$$HTTP_STATUS" -eq "200" ]]) || ( \
		echo ""; cat $@; echo ""; \
		rm -f $@; \
		exit 22 \
	);
