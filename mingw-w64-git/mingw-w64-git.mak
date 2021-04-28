include Makefile

git-wrapper$(X): git-wrapper.o git.res
	$(QUIET_LINK)$(CC) $(ALL_LDFLAGS) $(COMPAT_CFLAGS) \
		-fno-stack-protector -Wall -o $@ $^ -lshell32 -lshlwapi

git-wrapper.o: %.o: ../%.c GIT-PREFIX
	$(QUIET_CC)$(CC) $(ALL_CFLAGS) $(COMPAT_CFLAGS) \
		-fno-stack-protector -o $*.o -c -Wall -Wwrite-strings $<

git-bash.res git-cmd.res git-wrapper.res gitk.res compat-bash.res: \
		%.res: ../%.rc
	$(QUIET_RC)$(RC) -i $< -o $@

git-bash.exe cmd/gitk.exe cmd/git-gui.exe: ALL_LDFLAGS += -mwindows

git-bash.exe git-cmd.exe compat-bash.exe: %.exe: %.res

cmd/gitk.exe cmd/git-gui.exe: gitk.res

git-bash.exe git-cmd.exe compat-bash.exe \
cmd/git.exe cmd/gitk.exe cmd/git-gui.exe: \
		%.exe: git-wrapper.o git.res
	@mkdir -p cmd
	$(QUIET_LINK)$(CC) $(ALL_LDFLAGS) $(COMPAT_CFLAGS) -o $@ $^ -lshlwapi

edit-git-bash$(X): edit-git-bash.o
	$(QUIET_LINK)$(CC) $(ALL_LDFLAGS) $(COMPAT_CFLAGS) \
		-fno-stack-protector -Wall -o $@ $^

edit-git-bash.o: %.o: ../%.c GIT-PREFIX
	$(QUIET_CC)$(CC) $(ALL_CFLAGS) $(COMPAT_CFLAGS) \
		-fno-stack-protector -o $*.o -c -Wall -Wwrite-strings $<

print-builtins:
	@echo $(BUILT_INS)

strip-all: strip
	$(STRIP) $(STRIP_OPTS) \
		contrib/credential/wincred/git-credential-wincred.exe \
		cmd/git{,-gui,k}.exe compat-bash.exe git-{bash,cmd,wrapper}.exe

install-pdbs:
	$(INSTALL) -d -m 755 '$(DESTDIR_SQ)$(bindir_SQ)'
	$(INSTALL) -d -m 755 '$(DESTDIR_SQ)$(gitexec_instdir_SQ)'
	$(INSTALL) -d -m 755 '$(DESTDIR_SQ)/cmd'
	$(INSTALL) -m 644 git.pdb '$(DESTDIR_SQ)$(bindir_SQ)'
	$(INSTALL) -m 644 $(patsubst %.exe,%.pdb,$(PROGRAMS)) \
		contrib/credential/wincred/git-credential-wincred.pdb \
		'$(DESTDIR_SQ)$(gitexec_instdir_SQ)'
	$(INSTALL) -m 644 cmd/git{,-gui,k}.pdb '$(DESTDIR_SQ)/cmd'
	$(INSTALL) -m 644 git-{bash,cmd,wrapper}.pdb '$(DESTDIR_SQ)'

sign-executables:
ifeq (,$(SIGNTOOL))
	@echo Skipping code-signing
else
	@eval $(SIGNTOOL) $(filter %.exe,$(ALL_PROGRAMS)) $(SCALAR_EXE) $(CMD_SCALAR_EXE) \
		contrib/credential/wincred/git-credential-wincred.exe git.exe \
		cmd/git{,-gui,k}.exe compat-bash.exe git-{bash,cmd,wrapper}.exe
endif

install-mingit-busybox-test-artifacts:
	install -m755 -d '$(DESTDIR_SQ)/usr/bin'
	printf '%s\n%s\n' >'$(DESTDIR_SQ)/usr/bin/perl' \
		"#!/mingw64/bin/busybox sh" \
		"exec \"$(shell cygpath -am /usr/bin/perl.exe)\" \"\$$@\""

	install -m755 -d '$(DESTDIR_SQ)'
	printf '%s%s\n%s\n%s\n%s\n%s\n' >'$(DESTDIR_SQ)/init.bat' \
		"PATH=$(DESTDIR_WINDOWS)\\$(MINGW_PREFIX)\\bin;" \
		"C:\\WINDOWS;C:\\WINDOWS\\system32" \
		"@set GIT_TEST_INSTALLED=$(DESTDIR_MIXED)/$(MINGW_PREFIX)/bin" \
		"@`echo "$(DESTDIR_WINDOWS)" | sed 's/:.*/:/'`" \
		"@cd `echo "$(DESTDIR_WINDOWS)" | sed 's/^.://'`\\test-git\\t" \
		"@echo Now, run 'helper\\test-run-command testsuite'"

	install -m755 -d '$(DESTDIR_SQ)/test-git'
	sed 's/^\(NO_PERL\|NO_PYTHON\)=.*/\1=YesPlease/' \
		<GIT-BUILD-OPTIONS >'$(DESTDIR_SQ)/test-git/GIT-BUILD-OPTIONS'

	install -m755 -d '$(DESTDIR_SQ)/test-git/t/helper'
	install -m755 $(TEST_PROGRAMS) '$(DESTDIR_SQ)/test-git/t/helper'
	(cd t && $(TAR) cf - t[0-9][0-9][0-9][0-9] diff-lib) | \
	(cd '$(DESTDIR_SQ)/test-git/t' && $(TAR) xf -)
	install -m755 t/t556x_common t/*.sh '$(DESTDIR_SQ)/test-git/t'

	install -m755 -d '$(DESTDIR_SQ)/test-git/templates'
	(cd templates && $(TAR) cf - blt) | \
	(cd '$(DESTDIR_SQ)/test-git/templates' && $(TAR) xf -)

	# po/build/locale for t0200
	install -m755 -d '$(DESTDIR_SQ)/test-git/po/build/locale'
	(cd po/build/locale && $(TAR) cf - .) | \
	(cd '$(DESTDIR_SQ)/test-git/po/build/locale' && $(TAR) xf -)

	# git-daemon.exe for t5802, git-http-backend.exe for t5560
	install -m755 -d '$(DESTDIR_SQ)/$(MINGW_PREFIX)/bin'
	install -m755 git-daemon.exe git-http-backend.exe \
		'$(DESTDIR_SQ)/$(MINGW_PREFIX)/bin'

	# git-upload-archive (dashed) for t5000
	install -m755 -d '$(DESTDIR_SQ)/$(MINGW_PREFIX)/bin'
	install -m755 git-upload-archive.exe '$(DESTDIR_SQ)/$(MINGW_PREFIX)/bin'

	# git-difftool--helper for t7800
	install -m755 -d '$(DESTDIR_SQ)/$(MINGW_PREFIX)/libexec/git-core'
	install -m755 git-difftool--helper \
		'$(DESTDIR_SQ)/$(MINGW_PREFIX)/libexec/git-core'