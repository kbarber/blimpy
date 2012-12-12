#!/bin/sh -x

OSNAME=`uname`
LINUXFLAVOR=`lsb_release -is`
PROG=`basename $0`

Info () {
  echo "$PROG : $*"
}

Fatal () {
  echo "$PROG : FATAL: $*"
  exit 1
}

Info "Begin"
if [ "${OSNAME}" = "FreeBSD" ]; then
  which pkg > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    Info "pkgng is not installed!"
    ftp -V ftp://anonymous:ec2@ftp.freebsd.org/pub/FreeBSD/ports/amd64/packages-9-stable/Latest/pkg.tbz
    pkg_add ./pkg.tbz
    echo "PACKAGESITE : http://pkgbeta.freebsd.org/freebsd-9-amd64/latest/" > /usr/local/etc/pkg.conf
    pkg update -q
    # Update pkgng itself
    pkg install -y pkg
    # Install rsync(1) so we don't have to fall back to tar(1)+scp(1) ever again
    pkg install -y rsync
    # Install puppet so we can get that up and running
    pkg install -y puppet
  fi
else
  case "$LINUXFLAVOR" in
    RedHat*) # Extract the major version number
             VERSION=`lsb_release -ids | sed 's/.*release \([0-9]\).*/\1/'`
             if [ $VERSION -eq 5 ]; then
               rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-6.noarch.rpm
             elif [ $VERSION -eq 6 ]; then
               rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-6.noarch.rpm
             else
               Fatal "Unsupported Red Hat release: $VERSION"
             fi
             # Disable EPEL if for some reason it is configured on this host
             # as we don't want to get some old Puppet from there.
             if [ -f /etc/yum.repos.d/epel.repo ]; then
               yum install -y puppet --disablerepo=epel
             else
               yum install -y puppet
             fi
             ;;
    Ubuntu) export PATH=/var/lib/gems/1.8/bin:/usr/local/bin:$PATH
            which puppet > /dev/null 2>&1
            if [ $? -ne 0 ]; then
              apt-get update
              apt-get install -y ruby1.8 \
                                 ruby1.8-dev \
                                 libopenssl-ruby1.8 \
                                 rubygems
              gem install puppet --version "~> 2.7" --no-ri --no-rdoc
            fi
            ;;
    *) Fatal "Unsupported Linux flavor: $LINUXFLAVOR"
       ;;
  esac
fi
