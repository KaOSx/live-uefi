all:

install: all
	# install to sbin since script only usable by root
	install -D -m 755 mkkdeosiso $(DESTDIR)/usr/sbin/mkkdeosiso
	install -D -m 755 mkkdeosroot $(DESTDIR)/usr/sbin/mkkdeosroot
	install -D -m 755 build.sh $(DESTDIR)/usr/sbin/build
	install -D -m 755 overlay-pkgs.sh $(DESTDIR)/usr/bin/overlay-pkgs
	# testiso can be used by anyone
	install -D -m 755 testiso $(DESTDIR)/usr/bin/testiso
	# hooks/install are needed by mkinitcpio
	install -D -m 644 hooks/kdeosiso $(DESTDIR)/usr/lib/initcpio/hooks/kdeosiso
	install -D -m 644 install/kdeosiso $(DESTDIR)/usr/lib/initcpio/install/kdeosiso
	install -D -m 644 hooks/kdeosiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/hooks/kdeosiso_pxe_nbd
	install -D -m 644 install/kdeosiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/install/kdeosiso_pxe_nbd
	install -D -m 644 hooks/kdeosiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/hooks/kdeosiso_loop_mnt
	install -D -m 644 install/kdeosiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/install/kdeosiso_loop_mnt
	install -D -m 644 install/kdeosiso_kms $(DESTDIR)/usr/lib/initcpio/install/kdeosiso_kms	
	# install helpers
	install -d -m 755 $(DESTDIR)/usr/share/kdeosiso/
	install -D -m 755 functions/messages $(DESTDIR)/usr/share/kdeosiso/functions/messages
	install -D -m 755 functions/colors $(DESTDIR)/usr/share/kdeosiso/functions/colors

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkkdeosiso
	rm -f $(DESTDIR)/usr/sbin/mkkdeosroot
	rm -f $(DESTDIR)/usr/sbin/build
	rm -f $(DESTDIR)/usr/bin/overlay-pkgs
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/kdeosiso
	rm -f $(DESTDIR)/usr/lib/initcpio/install/kdeosiso
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/kdeosiso_pxe_nbd
	rm -f $(DESTDIR)/usr/lib/initcpio/install/kdeosiso_pxe_nbd
	rm -rf $(DESTDIR)/usr/share/kdeosiso/
