docs: clean
	scripts/generate_distro_map.sh
	asciibinder package
	mv _package/community docs

clean:
	asciibinder clean
	rm -rf docs

preview:
	asciibinder build -l debug

find-unref:
	# Ignore _*.md files
	bash -c 'comm -23 <(find . -regex "./[^_].*\.adoc" | cut -d / -f 2- | sort) <(grep -hRo "[a-zA-Z/:.-]*\.adoc" | sort -u)'

spellcheck:
	for FN in $$(find . -name \*.adoc); do \
	aspell --personal=.aspell.en.pws --lang=en --encoding=utf-8 list <$$FN ; \
	done | sort -u

test:
	test "$$(make -s find-unref) -eq 0"

netlify: clean
	git branch -D current
	git checkout -b current
	echo '---' > _distro_map.yml
	echo 'kubevirt-community:' >> _distro_map.yml
	echo '    name: KubeVirt' >> _distro_map.yml
	echo '    author: KubeVirt Documentation Team' >> _distro_map.yml
	echo '    site: community' >> _distro_map.yml
	echo '    site_name: Documentation' >> _distro_map.yml
	echo '    site_url: https://kubevirt.io/docs' >> _distro_map.yml
	echo '    branches:' >> _distro_map.yml
	echo '        current:' >> _distro_map.yml
	echo '            name: current' >> _distro_map.yml
	echo '            dir: latest' >> _distro_map.yml

	asciibinder package
	mv _package/community docs
