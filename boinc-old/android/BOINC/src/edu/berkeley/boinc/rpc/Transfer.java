/*******************************************************************************
 * This file is part of BOINC.
 * http://boinc.berkeley.edu
 * Copyright (C) 2012 University of California
 * 
 * BOINC is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 * 
 * BOINC is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with BOINC.  If not, see <http://www.gnu.org/licenses/>.
 ******************************************************************************/

package edu.berkeley.boinc.rpc;

import java.io.Serializable;

public class Transfer implements Serializable {
	private static final long serialVersionUID = 1L;
	public String name;
	public String project_url;
	public boolean generated_locally;
	public long nbytes;
	public boolean xfer_active;
	public boolean is_upload;
	public int status;
	public long next_request_time;
    public long time_so_far;
	public long bytes_xferred;
    public float xfer_speed;
	public long project_backoff;
}
