VER_LATEST=$(shell curl https://github.com/kubevirt/kubevirt/releases/latest -v 2>&1 | grep Location | grep -o "v[0-9.]\+")

find-unref:
	# Ignore _*.md files
	bash -c 'comm -23 <(find . -regex "./[^_].*\.md" | cut -d / -f 2- | sort) <(grep -hRo "[a-zA-Z/:.-]*\.md" | sort -u)'

find-unreviewed:
	for FN in $$(find . -name \*.md); do \
	grep -L "Verified with version: $(VER_LATEST)" $$FN ; \
	done | sort -u

spellcheck:
	for FN in $$(find . -name \*.md); do \
	aspell --personal=.aspell.en.pws --lang=en --encoding=utf-8 list <$$FN ; \
	done | sort -u

test:
	test "$$(make -s find-unref) -eq 0"
	test "$$(make -s find-unreviewed) -eq 0"
