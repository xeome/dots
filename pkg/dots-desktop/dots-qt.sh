# The Qt theme variables, from the one file that sets them. set -a, because a
# plain `.` of KEY=VALUE lines sets shell variables the session never inherits.
set -a
. /usr/lib/environment.d/50-dots-qt.conf
set +a
