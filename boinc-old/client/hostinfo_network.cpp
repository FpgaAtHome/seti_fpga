// This file is part of BOINC.
// http://boinc.berkeley.edu
// Copyright (C) 2008 University of California
//
// BOINC is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// BOINC is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with BOINC.  If not, see <http://www.gnu.org/licenses/>.

#include "cpp.h"

#ifdef _WIN32
#include "boinc_win.h"
#define getpid _getpid
#else 
#include "config.h"
#include <cstdio>
#include <cstring>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif
#if HAVE_NETDB_H
#include <netdb.h>
#endif
#if HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#endif

#ifdef __APPLE__
#include <Carbon/Carbon.h>
#endif

#include "str_util.h"
#include "str_replace.h"
#include "parse.h"
#include "util.h"
#include "file_names.h"
#include "error_numbers.h"

#include "client_msgs.h"

#include "hostinfo.h"

#ifdef ANDROID
// Returns TRUE if host is currently using a wifi connection
// used on Android devices to prevent usage of data plans.
// if value cant be read, default return false
//
bool HOST_INFO::host_wifi_online() {
    char wifi_state[64];

    strcpy(wifi_state, "");

    // location in Android 2.3
    FILE *f = fopen("/sys/class/net/eth0/operstate", "r");
    if (!f) {
        // location in Android 4
        f = fopen("/sys/class/net/wlan0/operstate", "r");
    }

    if (f) {
        fgets(wifi_state, 64, f);
        fclose(f);
    } else {
        msg_printf(0, MSG_INFO, "HOST_INFO::host_wifi_online(): wifi adapter not found!\n");
        return false;
    }

    if (strstr(wifi_state,"up")) {
        return true;
    }
    return false;
}
#endif //ANDROID

// get domain name and IP address of this host
//
int HOST_INFO::get_local_network_info() {
    struct sockaddr_storage s;
    
    strcpy(domain_name, "");
    strcpy(ip_addr, "");

    // it seems like we should use getdomainname() instead of gethostname(),
    // but on FC6 it returns "(none)".
    //
    if (gethostname(domain_name, 256)) {
        return ERR_GETHOSTBYNAME;
    }
    int retval = resolve_hostname(domain_name, s);
    if (retval) return retval;
#ifdef _WIN32
    sockaddr_in* sin = (sockaddr_in*)&s;
    strlcpy(ip_addr, inet_ntoa(sin->sin_addr), sizeof(ip_addr));
#else
    if (s.ss_family == AF_INET) {
        sockaddr_in* sin = (sockaddr_in*)&s;
        inet_ntop(AF_INET, (void*)(&sin->sin_addr), ip_addr, 256);
    } else {
        sockaddr_in6* sin = (sockaddr_in6*)&s;
        inet_ntop(AF_INET6, (void*)(&sin->sin6_addr), ip_addr, 256);
    }
#endif
    return 0;
}

// make a random string using time of day and host info.
// Not recommended for password generation;
// use as a last resort if more secure methods fail
//
void HOST_INFO::make_random_string(const char* salt, char* out) {
    char buf[1024];

#ifdef ANDROID
    sprintf(buf, "%f%s%s%f%s",
        dtime(), domain_name, ip_addr, d_free, salt
    );
#else
    sprintf(buf, "%d%.15e%s%s%f%s",
        getpid(), dtime(), domain_name, ip_addr, d_free, salt
    );
#endif
    md5_block((const unsigned char*) buf, (int)strlen(buf), out);
}

// make a host cross-project ID.
// Should be unique across hosts with very high probability
//
void HOST_INFO::generate_host_cpid() {
    make_random_string("", host_cpid);
}

