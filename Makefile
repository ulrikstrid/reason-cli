ifeq ($(TYPE), bin)
	RELEASE_TAG = "bin-$(shell uname | tr A-Z a-z)"
else
	RELEASE_TAG = $(TYPE)
endif

clean:
	@rm -rf _release

build-release:
	@# Program "fails" if unstaged changes.
	@git diff --exit-code || (echo "" && echo "!!You have unstaged changes. Please clean up first." && exit 1)
	@git diff --cached --exit-code || (echo "" && echo "!!You have staged changes. Please reset them or commit them first." && exit 1);
	@esy release

# Releases to Github
release: build-release
	@cp ./Makefile _release/
	@make \
		RELEASE_TAG="$(RELEASE_TAG)" \
		ORIGIN=`git remote get-url origin` \
		VERSION=`node -p "require('./package.json').version"` \
		-C _release/ \
		_release_continue

define WELCOME_MSG

----------------------------------------------
--- Preparing release $(VERSION)-$(RELEASE_TAG)
----------------------------------------------

endef
export WELCOME_MSG

define ALMOST_DONE_MSG

----------------------------------------------------
-- Almost Done. Complete the following two steps
----------------------------------------------------

Directory _release/ contains a git repository ready
to be pushed under a tag to remote.

1. [REQUIRED] cd _release/

2. git show HEAD
		Make sure you approve of what will be pushed to tag $(VERSION)-$(RELEASE_TAG)

3. Test a local install of the package before publishing:
	  npm install -g ./_release/bin-darwin/

4. Follow the README instructions for publishing to npm.


> Note: If you are pushing an update to an existing tag, you might need to add -f to the push command.

endef
export ALMOST_DONE_MSG

_release_continue:
	@echo "$$WELCOME_MSG"
	@git init .
	@git checkout -b branch-$(VERSION)-$(RELEASE_TAG)
	@git add .
	@git remote add origin $(ORIGIN)
	@git fetch --tags --depth=1
	@git commit -m "Preparing release $(VERSION)-$(RELEASE_TAG)"
	@# Return code is inverted to receive boolean return value',
	@(git tag --delete "$(VERSION)-$(RELEASE_TAG)" &> /dev/null) \
	 	|| echo "Tag $(VERSION)-$(RELEASE_TAG) doesn't yet exist, creating it now."
	@git tag -a "$(VERSION)-$(RELEASE_TAG)" -m "$(VERSION)-$(RELEASE_TAG)"
	@echo "$$ALMOST_DONE_MSG"
