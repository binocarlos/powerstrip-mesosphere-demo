.PHONY: test

test:
	vagrant up
	bats/bats test/
	bash test/acceptanceloop.sh
	vagrant destroy -f

