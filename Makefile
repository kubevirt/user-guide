find-unref:
	# Ignore _*.md files
	bash -c 'comm -23 <(find . -regex "./[^_].*\.md" | cut -d / -f 2- | sort) <(grep -hRo "[a-zA-Z/:.-]*\.md" | sort -u)'

test:
	[[ "$$(make -s find-unref)" -eq 0 ]]
