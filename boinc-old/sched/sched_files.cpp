// This file is part of BOINC.
// http://boinc.berkeley.edu
// Copyright (C) 2013 University of California
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

#include <regex.h>
#include <stdio.h>
#include <vector>
#include <string>

#include "sched_config.h"
#include "sched_msgs.h"
#include "sched_types.h"
#include "str_util.h"

#include "sched_files.h"

using std::vector;
using std::string;

vector<regex_t> file_delete_regex;
vector<string> file_delete_regex_string;

int init_file_delete_regex() {
    char buf[256];
#ifndef _USING_FCGI_
    FILE* f = fopen("../file_delete_regex", "r");
#else
    FCGI_FILE* f = FCGI::fopen("../file_delete_regex", "r");
#endif

    if (!f) return 0;
    while (fgets(buf, sizeof(buf), f)) {
        strip_whitespace(buf);
        if (!strlen(buf)) continue;
        regex_t re;
        if (regcomp(&re, buf, REG_EXTENDED|REG_NOSUB)) {
            log_messages.printf(MSG_CRITICAL,
                "invalid regular expression in file_delete_regex: %s\n", buf
            );
        } else {
            file_delete_regex.push_back(re);
            file_delete_regex_string.push_back(string(buf));
        }
    }
    return 0;
}

int do_file_delete_regex() {
    for (unsigned int i=0; i<g_request->file_infos.size(); i++) {
        FILE_INFO& fi = g_request->file_infos[i];
        bool found = false;
        for (unsigned int j=0; j<file_delete_regex.size(); j++) {
            regex_t& re = file_delete_regex[j];
            if (regexec(&re, fi.name, 0, NULL, 0)) {
                g_reply->file_deletes.push_back(fi);
                if (config.debug_client_files) {
                    log_messages.printf(MSG_NORMAL,
                        "[client_files] Sticky file %s matched regex %s; deleting\n",
                        fi.name, file_delete_regex_string[j].c_str()
                    );
                }
                found = true;
                break;
            }
        }
        if (config.debug_client_files && !found) {
            log_messages.printf(MSG_NORMAL,
                "[client_files] Sticky file %s didn't match any regex\n", fi.name
            );
        }
    }
    return 0;
}
