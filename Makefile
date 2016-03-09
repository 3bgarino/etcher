ELECTRON_PACKAGER=./node_modules/.bin/electron-packager
ELECTRON_BUILDER=./node_modules/.bin/electron-builder
ELECTRON_IGNORE=$(shell node -e "console.log(require('./package.json').packageIgnore.join('|'))")
ELECTRON_VERSION=0.36.8
ETCHER_VERSION=$(shell node -e "console.log(require('./package.json').version)")
APPLICATION_NAME=$(shell node -e "console.log(require('./package.json').displayName)")
SIGN_IDENTITY_OSX="Rulemotion Ltd (66H43P8FRG)"
S3_BUCKET="resin-production-downloads"

etcher-release/Etcher-darwin-x64: .
	$(ELECTRON_PACKAGER) . $(APPLICATION_NAME) \
		--platform=darwin \
		--arch=x64 \
		--version=$(ELECTRON_VERSION) \
		--ignore="$(ELECTRON_IGNORE)" \
		--asar \
		--app-version="$(ETCHER_VERSION)" \
		--build-version="$(ETCHER_VERSION)" \
		--helper-bundle-id="io.resin.etcher-helper" \
		--app-bundle-id="io.resin.etcher" \
		--app-category-type="public.app-category.developer-tools" \
		--sign=$(SIGN_IDENTITY_OSX) \
		--icon="assets/icon.icns" \
		--overwrite \
		--out=$(dir $@)

etcher-release/Etcher-linux-ia32: .
	$(ELECTRON_PACKAGER) . $(APPLICATION_NAME) \
		--platform=linux \
		--arch=ia32 \
		--version=$(ELECTRON_VERSION) \
		--ignore="$(ELECTRON_IGNORE)" \
		--asar \
		--app-version="$(ETCHER_VERSION)" \
		--build-version="$(ETCHER_VERSION)" \
		--overwrite \
		--out=$(dir $@)

etcher-release/Etcher-linux-x64: .
	$(ELECTRON_PACKAGER) . $(APPLICATION_NAME) \
		--platform=linux \
		--arch=x64 \
		--version=$(ELECTRON_VERSION) \
		--ignore="$(ELECTRON_IGNORE)" \
		--asar \
		--app-version="$(ETCHER_VERSION)" \
		--build-version="$(ETCHER_VERSION)" \
		--overwrite \
		--out=$(dir $@)

etcher-release/Etcher-win32-ia32: .
	$(ELECTRON_PACKAGER) . $(APPLICATION_NAME) \
		--platform=win32 \
		--arch=ia32 \
		--version=$(ELECTRON_VERSION) \
		--ignore="$(ELECTRON_IGNORE)" \
		--icon="assets/icon.ico" \
		--asar \
		--app-version="$(ETCHER_VERSION)" \
		--build-version="$(ETCHER_VERSION)" \
		--overwrite \
		--out=$(dir $@)

etcher-release/Etcher-win32-x64: .
	$(ELECTRON_PACKAGER) . $(APPLICATION_NAME) \
		--platform=win32 \
		--arch=x64 \
		--version=$(ELECTRON_VERSION) \
		--ignore="$(ELECTRON_IGNORE)" \
		--icon="assets/icon.ico" \
		--asar \
		--app-version="$(ETCHER_VERSION)" \
		--build-version="$(ETCHER_VERSION)" \
		--overwrite \
		--out=$(dir $@)

etcher-release/installers/Etcher.dmg: etcher-release/Etcher-darwin-x64 package.json
	$(ELECTRON_BUILDER) "$</$(APPLICATION_NAME).app" \
		--platform=osx \
		--sign=$(SIGN_IDENTITY_OSX) \
		--out=$(dir $@)

etcher-release/installers/Etcher-linux-x64.tar.gz: etcher-release/Etcher-linux-x64
	mkdir -p $(dir $@)
	tar -zcf $@ $<

etcher-release/installers/Etcher-linux-ia32.tar.gz: etcher-release/Etcher-linux-ia32
	mkdir -p $(dir $@)
	tar -zcf $@ $<

etcher-release/installers/Etcher-x64.exe: etcher-release/Etcher-win32-x64 package.json
	$(ELECTRON_BUILDER) $< \
		--platform=win \
		--out=$(dir $@)win-x64
	mv $(dir $@)win-x64/Etcher\ Setup.exe $@
	rmdir $(dir $@)win-x64

etcher-release/installers/Etcher.exe: etcher-release/Etcher-win32-ia32 package.json
	$(ELECTRON_BUILDER) $< \
		--platform=win \
		--out=$(dir $@)win-ia32
	mv $(dir $@)win-ia32/Etcher\ Setup.exe $@
	rmdir $(dir $@)win-ia32

package-osx: etcher-release/Etcher-darwin-x64
package-linux: etcher-release/Etcher-linux-ia32 etcher-release/Etcher-linux-x64
package-win32: etcher-release/Etcher-win32-ia32 etcher-release/Etcher-win32-x64
package-all: package-osx package-linux package-win32

installer-osx: etcher-release/installers/Etcher.dmg
installer-linux: etcher-release/installers/Etcher-linux-x64.tar.gz etcher-release/installers/Etcher-linux-ia32.tar.gz
installer-win32: etcher-release/installers/Etcher-x64.exe etcher-release/installers/Etcher.exe
installer-all: installer-osx installer-linux installer-win32

S3_UPLOAD=aws s3api put-object \
	--bucket $(S3_BUCKET) \
	--acl public-read \
	--key etcher/$(ETCHER_VERSION)/$(notdir $<) \
	--body $<

upload-linux-x64: etcher-release/installers/Etcher-linux-x64.tar.gz ; $(S3_UPLOAD)
upload-linux-ia32: etcher-release/installers/Etcher-linux-ia32.tar.gz ; $(S3_UPLOAD)
upload-win32-x64: etcher-release/installers/Etcher-x64.exe ; $(S3_UPLOAD)
upload-win32-ia32: etcher-release/installers/Etcher.exe ; $(S3_UPLOAD)

upload-osx: etcher-release/installers/Etcher.dmg ; $(S3_UPLOAD)
upload-linux: upload-linux-x64 upload-linux-ia32
upload-win32: upload-win32-x64 upload-win32-ia32

clean:
	rm -rf etcher-release/
