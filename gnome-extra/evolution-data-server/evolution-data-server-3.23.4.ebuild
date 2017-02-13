# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python2_7 python3_{4,5} pypy )
VALA_USE_DEPEND="vapigen"

inherit db-use flag-o-matic gnome2 python-any-r1 systemd vala virtualx cmake-utils

DESCRIPTION="Evolution groupware backend"
HOMEPAGE="https://wiki.gnome.org/Apps/Evolution"

# Note: explicitly "|| ( LGPL-2 LGPL-3 )", not "LGPL-2+".
LICENSE="|| ( LGPL-2 LGPL-3 ) BSD Sleepycat"
SLOT="0/59" # subslot = libcamel-1.2 soname version

IUSE="api-doc-extras berkdb +gtk google +introspection ipv6 ldap kerberos vala +weather"
REQUIRED_USE="vala? ( introspection )"

KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x86-solaris"

# sys-libs/db is only required for migrating from <3.13 versions
# gdata-0.15.1 is required for google tasks
# berkdb needed only for migrating old calendar data, bug #519512
RDEPEND="
	>=app-crypt/gcr-3.4
	>=app-crypt/libsecret-0.5[crypt]
	>=dev-db/sqlite-3.7.17:=
	>=dev-libs/glib-2.46:2
	>=dev-libs/libgdata-0.10:=
	>=dev-libs/libical-0.43:=
	>=dev-libs/libxml2-2
	>=dev-libs/nspr-4.4:=
	>=dev-libs/nss-3.9:=
	>=net-libs/libsoup-2.42:2.4

	dev-libs/icu:=
	sys-libs/zlib:=
	virtual/libiconv

	berkdb? ( >=sys-libs/db-4:= )
	gtk? (
		>=app-crypt/gcr-3.4[gtk]
		>=x11-libs/gtk+-3.10:3
	)
	google? (
		>=dev-libs/json-glib-1.0.4
		>=dev-libs/libgdata-0.15.1:=
		>=net-libs/webkit-gtk-2.11.91:4
	)
	>=net-libs/gnome-online-accounts-3.8:=
	introspection? ( >=dev-libs/gobject-introspection-0.9.12:= )
	kerberos? ( virtual/krb5:= )
	ldap? ( >=net-nds/openldap-2:= )
	weather? ( >=dev-libs/libgweather-3.10:2= )
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	dev-util/gdbus-codegen
	dev-util/gperf
	>=dev-util/gtk-doc-am-1.14
	>=dev-util/intltool-0.35.5
	>=gnome-base/gnome-common-2
	>=sys-devel/gettext-0.17
	virtual/pkgconfig
	vala? ( $(vala_depend) )
"

# Some tests fail due to missings locales.
# Also, dbus tests are flacky, bugs #397975 #501834
# It looks like a nightmare to disable those for now.
RESTRICT="test"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	use vala && vala_src_prepare
	gnome2_src_prepare
}

src_configure() {
	# /usr/include/db.h is always db-1 on FreeBSD
	# so include the right dir in CPPFLAGS
	use berkdb && append-cppflags "-I$(db_includedir)"


        local mycmakeargs=(
                -DENABLE_UOA=OFF
        )
	cmake-utils_src_configure
}

src_test() {
	unset ORBIT_SOCKETDIR
	unset SESSION_MANAGER
	virtx emake check
}

src_install() {
	addwrite /usr/share/glib-2.0/schemas/org.gnome.Evolution.DefaultSources.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/org.gnome.evolution-data-server.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/org.gnome.evolution-data-server.calendar.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/org.gnome.evolution.eds-shell.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/org.gnome.evolution-data-server.addressbook.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/org.gnome.evolution.shell.network-config.gschema.xml
	addwrite /usr/share/glib-2.0/schemas/

	cmake-utils_src_install

	if use ldap; then
		insinto /etc/openldap/schema
		doins "${FILESDIR}"/calentry.schema
		dosym /usr/share/${PN}/evolutionperson.schema /etc/openldap/schema/evolutionperson.schema
	fi
}
