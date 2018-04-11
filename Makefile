find-unref:
	bash -c 'comm -23 <(find . -name \*.md | cut -d / -f 2- | sort) <(grep -hRo "[a-zA-Z/:.-]*\.md" | sort -u)'
