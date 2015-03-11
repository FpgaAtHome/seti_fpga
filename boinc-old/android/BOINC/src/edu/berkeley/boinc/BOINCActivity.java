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
package edu.berkeley.boinc;

import edu.berkeley.boinc.client.ClientStatus;
import edu.berkeley.boinc.client.Monitor;
import android.app.Service;
import android.app.TabActivity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Resources;
import android.os.Bundle; 
import android.os.IBinder;
import android.util.Log;  
import android.view.View;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.TabHost;
import android.widget.TabHost.TabSpec;

public class BOINCActivity extends TabActivity {
	
	private final String TAG = "BOINC BOINCActivity"; 
	
	private Monitor monitor;
	private Integer clientSetupStatus = ClientStatus.SETUP_STATUS_LAUNCHING;
	public static ClientStatus clientStatus;
	private Boolean intialStart = true;
	
	private Boolean mIsBound;

	private ServiceConnection mConnection = new ServiceConnection() {
	    public void onServiceConnected(ComponentName className, IBinder service) {
	        // This is called when the connection with the service has been established, getService returns 
	    	// the Monitor object that is needed to call functions.
	        monitor = ((Monitor.LocalBinder)service).getService();
		    mIsBound = true;
		    determineStatus();
	    }

	    public void onServiceDisconnected(ComponentName className) {
	    	// This should not happen
	        monitor = null;
		    mIsBound = false;
	    }
	};
	
	private BroadcastReceiver mClientStatusChangeRec = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context,Intent intent) {
			Log.d(TAG, "ClientStatusChange - onReceive()");

			determineStatus();
		}
	};
	private IntentFilter ifcsc = new IntentFilter("edu.berkeley.boinc.clientstatuschange");
	
    @Override
    public void onCreate(Bundle savedInstanceState) {  
        Log.d(TAG, "onCreate()"); 

        super.onCreate(savedInstanceState);  
        setContentView(R.layout.main);  
         
        
        //bind monitor service
        doBindService();
        
        setupTabLayout();
    }
    
	@Override
	protected void onDestroy() {
    	Log.d(TAG, "onDestroy()");
	    doUnbindService();
	    super.onDestroy();
	}

	@Override
	protected void onResume() { // gets called by system every time activity comes to front. after onCreate upon first creation
    	Log.d(TAG, "onResume()");
	    super.onResume();
	    registerReceiver(mClientStatusChangeRec, ifcsc);
	    layout();
	}

	@Override
	protected void onPause() { // gets called by system every time activity loses focus.
    	Log.d(TAG, "onPause()");
	    super.onPause();
	    unregisterReceiver(mClientStatusChangeRec);
	}

	private void doBindService() {
	    // Establish a connection with the service, onServiceConnected gets called when
		bindService(new Intent(this, Monitor.class), mConnection, Service.BIND_AUTO_CREATE);
	}

	private void doUnbindService() {
	    if (mIsBound) {
	        // Detach existing connection.
	        unbindService(mConnection);
	        mIsBound = false;
	    }
	}
    
    public static void logMessage(Context ctx, String tag, String message) {
        Intent testLog = new Intent();
        testLog.setAction("edu.berkeley.boinc.log");
        testLog.putExtra("message", message);   
        testLog.putExtra("tag", tag);
        ctx.sendBroadcast(testLog);
    }
    
    // tests whether status is available and whether it changed since the last event.
    private void determineStatus() {
    	Integer newStatus = -1;
    	try {
			if(mIsBound) { 
				newStatus = Monitor.getClientStatus().setupStatus;
				Log.d(TAG,"determineStatus() old clientSetupStatus: " + clientSetupStatus + " - newStatus: " + newStatus);
				if(newStatus != clientSetupStatus) { //only act, when status actually different form old status
					clientSetupStatus = newStatus;
					layout();
				}
				if(intialStart && (clientSetupStatus == ClientStatus.SETUP_STATUS_NOPROJECT)) { // if it is first start and no project attached, show login activity
					startActivity(new Intent(this,LoginActivity.class));
					intialStart = false;
				}
			} 
    	} catch (Exception e) {}
    }
    
    private void layout() {
    	TabHost tabLayout = (TabHost) findViewById(android.R.id.tabhost);
    	LinearLayout launchingLayout = (LinearLayout) findViewById(R.id.main_launching);
    	LinearLayout errorLayout = (LinearLayout) findViewById(R.id.main_error);
    	//TextView noProjectWarning = (TextView) findViewById(R.id.noproject_warning);
    	HorizontalScrollView noProjectWarning = (HorizontalScrollView) findViewById(R.id.noproject_warning_wrapper);
    	switch (clientSetupStatus) {
    	case ClientStatus.SETUP_STATUS_AVAILABLE:
    		noProjectWarning.setVisibility(View.GONE);
        	launchingLayout.setVisibility(View.GONE);
        	errorLayout.setVisibility(View.GONE);
    		tabLayout.setVisibility(View.VISIBLE);
    		break;
    	case ClientStatus.SETUP_STATUS_ERROR:
    		tabLayout.setVisibility(View.GONE); 
        	launchingLayout.setVisibility(View.GONE);
        	errorLayout.setVisibility(View.VISIBLE);
    		break;
    	case ClientStatus.SETUP_STATUS_LAUNCHING:
    		tabLayout.setVisibility(View.GONE); 
        	errorLayout.setVisibility(View.GONE);
        	launchingLayout.setVisibility(View.VISIBLE);
    		break;
    	case ClientStatus.SETUP_STATUS_NOPROJECT:
        	launchingLayout.setVisibility(View.GONE);
        	errorLayout.setVisibility(View.GONE);
    		tabLayout.setVisibility(View.VISIBLE);
    		noProjectWarning.setVisibility(View.VISIBLE);
    		break;
    	default:
    		Log.w(TAG, "could not layout status: " + clientSetupStatus);
    		break;
    	}
    	
    }
    
    /*
     * setup tab layout.
     * which tabs should be set up is defined in resources file: /res/values/configuration.xml
     */
    private void setupTabLayout() {
    	
    	Resources res = getResources();
    	TabHost tabHost = getTabHost();
        
    	if(res.getBoolean(R.bool.tab_status)) {
	        TabSpec statusSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_status));
	        statusSpec.setIndicator(getResources().getString(R.string.tab_status), getResources().getDrawable(R.drawable.icon_status_tab));
	        Intent statusIntent = new Intent(this, StatusActivity.class);
	        statusSpec.setContent(statusIntent);
	        tabHost.addTab(statusSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_projects)) {
	        TabSpec projectsSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_projects));
	        projectsSpec.setIndicator(getResources().getString(R.string.tab_projects), getResources().getDrawable(R.drawable.icon_projects_tab));
	        Intent projectsIntent = new Intent(this, ProjectsActivity.class);
	        projectsSpec.setContent(projectsIntent);
	        tabHost.addTab(projectsSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_tasks)) {
	        TabSpec tasksSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_tasks));
	        tasksSpec.setIndicator(getResources().getString(R.string.tab_tasks), getResources().getDrawable(R.drawable.icon_tasks_tab));
	        Intent tasksIntent = new Intent(this, TasksActivity.class);
	        tasksSpec.setContent(tasksIntent);
	        tabHost.addTab(tasksSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_transfers)) {
	        TabSpec transSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_transfers));
	        transSpec.setIndicator(getResources().getString(R.string.tab_transfers), getResources().getDrawable(R.drawable.icon_trans_tab));
	        Intent transIntent = new Intent(this, TransActivity.class);
	        transSpec.setContent(transIntent);
	        tabHost.addTab(transSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_preferences)) {
	        TabSpec prefsSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_preferences));
	        prefsSpec.setIndicator(getResources().getString(R.string.tab_preferences), getResources().getDrawable(R.drawable.icon_prefs_tab));
	        Intent prefsIntent = new Intent(this, PrefsActivity.class);
	        prefsSpec.setContent(prefsIntent);
	        tabHost.addTab(prefsSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_messages)) {
	        TabSpec msgsSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_eventlog));
	        msgsSpec.setIndicator(getResources().getString(R.string.tab_eventlog), getResources().getDrawable(R.drawable.icon_msgs_tab));
	        Intent msgsIntent = new Intent(this, EventLogActivity.class);
	        msgsSpec.setContent(msgsIntent);
	        tabHost.addTab(msgsSpec);
    	}
        
    	if(res.getBoolean(R.bool.tab_debug)) {
	        TabSpec debugSpec = tabHost.newTabSpec(getResources().getString(R.string.tab_debug));
	        debugSpec.setIndicator(getResources().getString(R.string.tab_debug), getResources().getDrawable(R.drawable.icon_debug_tab));
	        Intent debugIntent = new Intent(this, DebugActivity.class);
	        debugSpec.setContent(debugIntent);
	        tabHost.addTab(debugSpec);
        }
    	
        Log.d(TAG, "tab layout setup done");

        BOINCActivity.logMessage(this, TAG, "tab setup finished");
    }

	// triggered by click on noproject_warning, starts login activity
	public void noProjectClicked(View view) {
		Log.d(TAG, "noProjectClicked()");
		startActivity(new Intent(this, LoginActivity.class));
	}
    
	
	//gets called when user clicks on retry of error_layout
	//has to be public in order to get triggered by layout component
	public void reinitClient(View view) {
		if(!mIsBound) return;
		Log.d(TAG, "reinitClient()");
		monitor.restartMonitor(); //start over with setup of client
	}
}
