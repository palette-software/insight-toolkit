%define serviceuser insight
%define servicehome /etc/palette-insight-server


# Disable the stupid stuff rpm distros include in the build process by default:
#   Disable any prep shell actions. replace them with simply 'true'
%define __spec_prep_post true
%define __spec_prep_pre true
#   Disable any build shell actions. replace them with simply 'true'
%define __spec_build_post true
%define __spec_build_pre true
#   Disable any install shell actions. replace them with simply 'true'
%define __spec_install_post true
%define __spec_install_pre true
#   Disable any clean shell actions. replace them with simply 'true'
%define __spec_clean_post true
%define __spec_clean_pre true
# Disable checking for unpackaged files ?
#%undefine __check_files

# Use md5 file digest method.
# The first macro is the one used in RPM v4.9.1.1
%define _binary_filedigest_algorithm 1
# This is the macro I find on OSX when Homebrew provides rpmbuild (rpm v5.4.14)
%define _build_binary_file_digest_algo 1

# Use bzip2 payload compression
%define _binary_payload w9.bzdio


Name: palette-insight-toolkit
Version: %version
Epoch: 400
Release: %buildrelease
Summary: Palette Insight Toolkit
AutoReqProv: no
# Seems specifying BuildRoot is required on older rpmbuild (like on CentOS 5)
# fpm passes '--define buildroot ...' on the commandline, so just reuse that.
#BuildRoot: %buildroot
# Add prefix, must not end with / except for root (/)

Prefix: /

Group: default
License: commercial
Vendor: palette-software.net
URL: http://www.palette-software.com
Packager: Palette Developers <developers@palette-software.com>

# Add the user for the service & setup SELinux
# ============================================

Requires(pre): /usr/sbin/useradd, /usr/bin/getent

Requires: sudo cronie
# Required by palette-insight-website and palette-insight-loadtables
Requires: python35u python35u-pip

%pre
# Create the 'insight' sudoer without tty and passwordless user
useradd %{serviceuser}
FILE=/etc/sudoers
TMP_FILE=/tmp/insight-sudoers.tmp
cp -a ${FILE} ${TMP_FILE}
for LINE in "insight ALL=(ALL) NOPASSWD:ALL" "Defaults: insight !requiretty"; do
    grep -q "$LINE" "$TMP_FILE" || echo "$LINE" | sudo tee --append "$TMP_FILE"
done
# Validate the file that we are going to overwrite /etc/sudoers with
visudo -cf ${TMP_FILE}
VISUDO_EXIT_CODE=$?
if [ ${VISUDO_EXIT_CODE} -ne 0 ]; then
    echo "Failed to add %{serviceuser} to sudoers!"
    exit ${VISUDO_EXIT_CODE}
fi
# Apply our sudoers file with passwordless insight user
mv ${TMP_FILE} ${FILE}

%post
crontab -u insight /opt/insight-toolkit/insight-toolkit-cron

# On CentOS 6 the python3 and pip3 symlinks are not created by default
ln -s /usr/bin/python3.5 /usr/bin/python3
ln -s /usr/bin/pip3.5 /usr/bin/pip3

%postun
# noop

%description
Palette Insight Toolkit

%prep
# noop

%build
# noop

%install
# noop

%clean
# noop

%files
%defattr(-,insight,insight,-)

# Reject config files already listed or parent directories, then prefix files
# with "/", then make sure paths with spaces are quoted.
# /usr/local/bin/palette-insight-server
/opt/insight-toolkit
%dir /var/log/insight-toolkit
%dir /var/lib/palette

%changelog
