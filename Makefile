CARP_SRC    != find . -name 'hostname.carp[0-9]*' | grep -E 'hostname.carp[0-9]+$$' | sed -e 's,\./,,'
ISAKMPD_SRC != find isakmpd/ -type f | sed -e 's,\./,,'
PF_SRC      != ls pf.conf*
RSYNC_OPTS=-auPq

ISAKMPD_SRC += ipsec.conf

.for _carp in ${CARP_SRC}
DYN_TARGETS += backup.${_carp}
.endfor

include remote.mk

.if defined(REMOTE) && empty(REMOTE)
.	undef REMOTE
.endif

all: show backup.pf.conf backup.Makefile backup.apply_sysctl backup.sysctl.conf backup.rc.conf.local backup.ipsec.conf backup.mail_diff backup.update_carp.sh $(DYN_TARGETS)

show:
	echo Remote: $(REMOTE)
	echo DYN_SRC: $(DYN_TARGETS)

backup.pf.conf: $(PF_SRC)
	echo "=> PF"
	echo " Check"
	pfctl -nf pf.conf
	echo " Apply"
	pfctl -f pf.conf
	echo " Mail diff"
	/etc/mail_diff pf.conf
.if defined(REMOTE)
	echo " Sync with $(REMOTE)"
	rsync $(RSYNC_OPTS) pf.conf* $(REMOTE):/etc/
	echo " Apply on $(REMOTE)"
	ssh $(REMOTE) pfctl -f /etc/pf.conf
.endif
	echo " Backup pf.conf"
	cp pf.conf backup.pf.conf
.if defined(REMOTE)
	echo " Backup backup.pf.conf on $(REMOTE)"
	rsync $(RSYNC_OPTS) backup.pf.conf $(REMOTE):/etc/backup.pf.conf
.endif
	echo

backup.Makefile: Makefile
	echo "=> Makefile"
	echo " Mail diff"
	/etc/mail_diff Makefile
.if defined(REMOTE)
	echo " Sync Makefile to $(REMOTE)"
	rsync $(RSYNC_OPTS) /etc/Makefile $(REMOTE):/etc/Makefile
.endif
	echo " Backup Makefile"
	cp Makefile $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.apply_sysctl: apply_sysctl
	echo "=> apply_sysctl"
	echo " Mail diff"
	/etc/mail_diff apply_sysctl
.if defined(REMOTE)
	echo " Sync apply_sysctl"
	rsync $(RSYNC_OPTS) /etc/apply_sysctl $(REMOTE):/etc/apply_sysctl
.endif
	echo " Backup apply_sysctl"
	cp apply_sysctl $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.update_carp.sh: update_carp.sh
	echo "=> update_carp.sh"
	echo " Mail diff"
	/etc/mail_diff update_carp.sh
.if defined(REMOTE)
	echo " Sync update_carp.sh"
	rsync $(RSYNC_OPTS) /etc/update_carp.sh $(REMOTE):/etc/update_carp.sh
.endif
	echo " Backup update_carp.sh"
	cp update_carp.sh $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.sysctl.conf: sysctl.conf backup.apply_sysctl
	echo "=> sysctl.conf"
	echo " Apply sysctl config"
	/etc/apply_sysctl
	echo " Mail diff"
	/etc/mail_diff sysctl.conf
.if defined(REMOTE)
	echo " Sync sysctl.conf to $(REMOTE)"
	rsync $(RSYNC_OPTS) /etc/sysctl.conf $(REMOTE):/etc/sysctl.conf
	echo " Apply sysctl config on $(REMOTE)"
	ssh $(REMOTE) /etc/apply_sysctl
.endif
	echo " Backup sysctl.conf"
	cp sysctl.conf $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.rc.conf.local: rc.conf.local
	echo "=> rc.conf.local"
	echo " Mail diff"
	/etc/mail_diff rc.conf.local
.if defined(REMOTE)
	echo " Sync rc.conf.local to $(REMOTE)"
	rsync $(RSYNC_OPTS) /etc/rc.conf.local $(REMOTE):/etc/rc.conf.local
.endif
	echo " Backup rc.conf.local"
	cp rc.conf.local $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.mail_diff: mail_diff
	echo "=> mail_diff"
	echo " Mail diff"
	/etc/mail_diff mail_diff
.if defined(REMOTE)
	echo " Sync mail_diff to $(REMOTE)"
	rsync $(RSYNC_OPTS) /etc/mail_diff $(REMOTE):/etc/mail_diff
.endif
	echo " Backup mail_diff"
	cp mail_diff $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo

backup.ipsec.conf: $(ISAKMPD_SRC)
	echo "=> IPSec"
	echo " Check"
	ipsecctl -nf ipsec.conf
	echo " Apply"
	ipsecctl -f ipsec.conf
	echo " Mail diff"
	/etc/mail_diff ipsec.conf
.if defined(REMOTE)
	echo " Sync with $(REMOTE)"
	rsync $(RSYNC_OPTS) ipsec.conf $(REMOTE):/etc/
	rsync $(RSYNC_OPTS) isakmpd/ $(REMOTE):/etc/isakmpd/
	echo " Apply on $(REMOTE)"
	ssh $(REMOTE) ipsecctl -f /etc/ipsec.conf
.endif
	echo " Backup ipsec.conf"
	cp ipsec.conf backup.ipsec.conf
.if defined(REMOTE)
	echo " Backup backup.ipsec.conf on $(REMOTE)"
	rsync $(RSYNC_OPTS) backup.ipsec.conf $(REMOTE):/etc/backup.ipsec.conf
.endif
	echo

.for _carp in ${CARP_SRC}
backup.${_carp}: ${_carp}
	echo "=> ${_carp}"
	echo " Applying changes"
	sh /etc/netstart ${_carp:C/hostname\.//}
	echo " Mail diff"
	/etc/mail_diff ${_carp}
.if defined(REMOTE)
	echo " Sync ${_carp} to $(REMOTE)"
	rsync $(RSYNC_OPTS) /etc/${_carp} $(REMOTE):/etc/${_carp}
	echo " Reconfigure advskew"
	ssh $(REMOTE) /etc/update_carp.sh ${_carp}
	echo " Apply netstart config on $(REMOTE)"
	ssh $(REMOTE) sh /etc/netstart ${_carp:C/hostname\.//}
.endif
	echo " Backup ${_carp}"
	cp ${_carp} $@
.if defined(REMOTE)
	rsync $(RSYNC_OPTS) /etc/$@ $(REMOTE):/etc/$@
.endif
	echo
.endfor



clean:
	rm -f backup.pf.conf backup.Makefile backup.apply_sysctl backup.sysctl.conf backup.rc.conf.local $(DYN_TARGETS)

.SILENT:

