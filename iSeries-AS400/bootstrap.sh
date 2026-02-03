#!/QOpenSys/usr/bin/ksh

set -eu

# Create a temp directory to extract the stage 2 bootstrap in to
TEMPDIR=/tmp/bootstrap.$$
mkdir -p $TEMPDIR
cd $TEMPDIR


function finished
{
  rc=$?

  cd /tmp
  rm -f $TEMPDIR/*
  rmdir $TEMPDIR
  
  set +eu
  if [ "$rc" = '0' ]
  then
    echo 'Bootstrap succeeded'
  else
    echo 'Bootstrap failed'
  fi
}
trap finished EXIT

VERSION=`uname -v``uname -r`
if [ 0$VERSION -lt 72 ]
then
  echo "This system is too old!"
  echo "IBM i 7.2 or above is required."
  exit 1
fi

if [ ! -e /QOpenSys/var/lib/rpm ]
then
  BOOTSTRAPPED=no
else
  BOOTSTRAPPED=yes

  if [ $# -gt 0 ]
  then
    # Can't merge this with the previous check due to being possibly unset
    if [ $1 = "--yes-this-is-unsupported-but-i-know-what-i-am-doing" ]
    then
      date > /tmp/bootstrap.info
      BOOTSTRAPPED=no
    fi
  fi
fi

if [ $BOOTSTRAPPED = "yes" ]
then
  cat <<EOF
########     ###    ##    ##  ######   ######## ########
##     ##   ## ##   ###   ## ##    ##  ##       ##     ##
##     ##  ##   ##  ####  ## ##        ##       ##     ##
##     ## ##     ## ## ## ## ##   #### ######   ########
##     ## ######### ##  #### ##    ##  ##       ##   ##
##     ## ##     ## ##   ### ##    ##  ##       ##    ##
########  ##     ## ##    ##  ######   ######## ##     ##

This system has already been bootstrapped!

Bootstrapping is a one-time process and should never need to be done again.
Doing so would cause the installation status of everything installed via yum
to become unknown and any software in the bootstrap will overwrite any newer
versions that may have been installed.

If you want to continue anyway, you can re-run bootstrap.sh with the flag
--yes-this-is-unsupported-but-i-know-what-i-am-doing
EOF
  exit 1
fi

# NOTE: the .tar.Z is no longer a compressed GNU tar file, but instead an
# uncompressed PASE tar file containing the stage 2 compresed GNU tar file and
# binaries needed to extract it. The .tar.Z name is kept for compatibility.
/QOpenSys/usr/bin/tar -xf /tmp/bootstrap.tar.Z

# Change to the root directory
cd /

# Extract the bootstrap in to the root
$TEMPDIR/zstd.bin -dc $TEMPDIR/bootstrap-stage2.tar.zst | $TEMPDIR/tar.bin -xf -

# Manually link /bin/bash. If we put it in the bootstrap, it overwrites
# the /bin -> /usr/bin symlink :(
ln -sf /QOpenSys/pkgs/bin/bash /bin/bash

exit 0
