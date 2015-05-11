.PHONY: test

test:
	vagrant up
	bats/bats test/
	vagrant destroy -f

