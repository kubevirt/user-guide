find-unref:
	# Ignore _*.md files
	bash -c 'comm -23 <(find . -regex "./[^_].*\.md" | cut -d / -f 2- | sort) <(grep -hRo "[a-zA-Z/:.-]*\.md" | sort -u)'

spellcheck:
	for FN in $$(find . -name \*.md); do \
	aspell --personal=.aspell.en.pws --lang=en --encoding=utf-8 list <$$FN ; \
	done | sort -u

test:
	test "$$(make -s find-unref) -eq 0"
