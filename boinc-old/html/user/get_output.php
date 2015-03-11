<?php

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

// handler for output file requests from remote job submission.
// See http://boinc.berkeley.edu/trac/wiki/RemoteJobs

require_once("../inc/util.inc");
require_once("../inc/result.inc");
require_once("../inc/submit_util.inc");

// get a single output file
//
function get_output_file($instance_name, $file_num, $auth_str) {
    $result = BoincResult::lookup_name(BoincDb::escape_string($instance_name));
    if (!$result) die("no job instance $instance_name");
    $workunit = BoincWorkunit::lookup_id($result->workunitid);
    if (!$workunit) die("no job $result->workunitid");
    $batch = BoincBatch::lookup_id($workunit->batch);
    if (!$batch) die("no batch $workunit->batch");
    $user = BoincUser::lookup_id($batch->user_id);
    if (!$user) die("no user $batch->user_id");
    $x = md5($user->authenticator.$result->name);
    if ($x != $auth_str) die("bad auth str");

    $names = get_outfile_names($result);
    if ($file_num >= count($names)) {
        die("bad file num: $file_num > ".count($names));
    }
    $name = $names[$file_num];

    $fanout = parse_config(get_config(), "<uldl_dir_fanout>");
    $upload_dir = parse_config(get_config(), "<upload_dir>");

    $path = dir_hier_path($name, $upload_dir, $fanout);
    if (!is_file($path)) die("no such file $path");
    do_download($path);    
}

// get all the output files of a batch (canonical instances only)
// and make a zip of all of them
//
function get_batch_output_files($auth_str) {
    $batch_id = get_int('batch_id', true);
    if ($batch_id) {
        $batch = BoincBatch::lookup_id($batch_id);
        if (!$batch) die("no batch $batch_id");
    } else {
        $batch_name = get_int('batch_name');
        $batch_name = BoincDb::escape_string($batch_name);
        $batch = BoincBatch::lookup("name='$batch_name'");
        if (!$batch) die("no batch $batch_name");
    }

    $user = BoincUser::lookup_id($batch->user_id);
    if (!$user) die("no user $batch->user_id");
    $x = md5($user->authenticator.$batch->id);
    if ($x != $auth_str) die("bad auth str");

    $zip_basename = tempnam("/tmp", "boinc_batch_");
    $zip_filename = $zip_basename.".zip";
    $fanout = parse_config(get_config(), "<uldl_dir_fanout>");
    $upload_dir = parse_config(get_config(), "<upload_dir>");

    $wus = BoincWorkunit::enum("batch=$batch->id");
    foreach ($wus as $wu) {
        if (!$wu->canonical_resultid) continue;
        $result = BoincResult::lookup_id($wu->canonical_resultid);
        $names = get_outfile_names($result);
        foreach ($names as $name) {
            $path = dir_hier_path($name, $upload_dir, $fanout);
            if (is_file($path)) {
                system(" nice -9 zip -jq $zip_basename $path");
            }
        }
    }
    do_download($zip_filename);
    unlink($zip_filename);
}

// return a single output file of a WU's canonical instance
//
function get_wu_output_file($wu_name, $file_num, $auth_str) {
    $wu_name = BoincDb::escape_string($wu_name);
    $wu = BoincWorkunit::lookup("name='$wu_name'");
    if (!$wu) die("no workunit $wu_name");
    $batch = BoincBatch::lookup_id($wu->batch);
    if (!batch) die("no batch $wu->batch");
    $user = BoincUser::lookup_id($batch->user_id);
    if (!$user) die("no user $batch->user_id");
    if ($user->authenticator != $auth_str) die("bad auth str: x=$x, auth_str=$auth_str");
    $fanout = parse_config(get_config(), "<uldl_dir_fanout>");
    $upload_dir = parse_config(get_config(), "<upload_dir>");
    if (!$wu->canonical_resultid) die("no canonical result for wu $wu->name");
    $result = BoincResult::lookup_id($wu->canonical_resultid);
    $names = get_outfile_names($result);
    $path = dir_hier_path($names[$file_num], $upload_dir, $fanout);
    if (file_exists($path)) {
        do_download($path);
    } else {
        echo "no such file: $path";
    }
}

// return a zip of all the output files of a workunit's canonical instance
//
function get_wu_output_files($wu_id, $auth_str) {
    $wu = BoincWorkunit::lookup_id($wu_id);
    if (!$wu) die("no workunit $wu_id");
    $batch = BoincBatch::lookup_id($wu->batch);
    if (!batch) die("no batch $wu->batch");
    $user = BoincUser::lookup_id($batch->user_id);
    if (!$user) die("no user $batch->user_id");
    $x = md5($user->authenticator.$wu_id);
    echo "user authenticator= $user->authenticator, wu_id=$wu_id<br/>";
    if ($x != $auth_str) die("bad auth str: x=$x, auth_str=$auth_str");

    $zip_basename = tempnam("/tmp", "boinc_wu_".$wu->name."_");
    $zip_filename = $zip_basename.".zip";
    $fanout = parse_config(get_config(), "<uldl_dir_fanout>");
    $upload_dir = parse_config(get_config(), "<upload_dir>");

    if (!$wu->canonical_resultid) die("no canonical result for wu $wu->name");
    $result = BoincResult::lookup_id($wu->canonical_resultid);
    $names = get_outfile_names($result);
    foreach ($names as $name) {
        $path = dir_hier_path($name, $upload_dir, $fanout);
        if (is_file($path)) {
            system("nice -9 zip -jq $zip_basename $path");
        }
    }
    do_download($zip_filename);
    unlink($zip_filename);
    unlink($zip_basename);
}

$cmd = get_str('cmd');
$auth_str = get_str('auth_str');
switch ($cmd) {
case 'result_file';
    $result_name = get_str('result_name');
    $file_num = get_int('file_num');
    get_output_file($result_name, $file_num, $auth_str);
    break;
case 'batch_files':
    get_batch_output_files($auth_str);
    break;
case 'workunit_file':
    $file_num = get_int('file_num');
    $wu_name = get_str('wu_name');
    get_wu_output_file($wu_name, $file_num, $auth_str);
    break;
case 'workunit_files':
    $wu_id = get_int('wu_id');
    get_wu_output_files($wu_id, $auth_str);
    break;
default:
    echo "bad command\n";
}
?>
