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
package edu.berkeley.boinc.client;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;
import android.widget.Toast;
import edu.berkeley.boinc.LoginActivity;
import edu.berkeley.boinc.BOINCActivity;
import edu.berkeley.boinc.AppPreferences;
import edu.berkeley.boinc.R;
import edu.berkeley.boinc.rpc.AccountIn;
import edu.berkeley.boinc.rpc.AccountOut;
import edu.berkeley.boinc.rpc.CcStatus;
import edu.berkeley.boinc.rpc.GlobalPreferences;
import edu.berkeley.boinc.rpc.Message;
import edu.berkeley.boinc.rpc.Project;
import edu.berkeley.boinc.rpc.ProjectAttachReply;
import edu.berkeley.boinc.rpc.Result;
import edu.berkeley.boinc.rpc.RpcClient;
import edu.berkeley.boinc.rpc.Transfer;

public class Monitor extends Service {
	
	private final String TAG = "BOINC Monitor Service";
	
	private static ClientStatus clientStatus; //holds the status of the client as determined by the Monitor
	private static AppPreferences appPrefs; //hold the status of the app, controlled by AppPreferences
	
	public static Boolean monitorActive = false;
	public static Boolean clientSetupActive = false;
	
	private String clientName; 
	private String clientCLI; 
	private String clientCABundle; 
	private String authFileName; 
	private String allProjectsList; 
	private String globalOverridePreferences;
	private String clientPath; 
	
	private Boolean started = false;
	private Thread monitorThread = null;
	private Boolean monitorRunning = true;
	
	private Process clientProcess;
	private RpcClient rpc = new RpcClient();

	private final Integer maxDuration = 3000; //maximum polling duration

	
	public static ClientStatus getClientStatus() { //singleton pattern
		if (clientStatus == null) {
			clientStatus = new ClientStatus();
		}
		return clientStatus;
	}
	
	public static AppPreferences getAppPrefs() { //singleton pattern
		if (appPrefs == null) {
			appPrefs = new AppPreferences();
		}
		return appPrefs;
	}

	
	/*
	 * returns this class, allows clients to access this service's functions and attributes.
	 */
	public class LocalBinder extends Binder {
        public Monitor getService() {
            return Monitor.this;
        }
    }
    private final IBinder mBinder = new LocalBinder();

    /*
     * gets called every-time an activity binds to this service, but not the initial start (onCreate and onStartCommand are called there)
     */
    @Override
    public IBinder onBind(Intent intent) {
    	//Log.d(TAG,"onBind");
        return mBinder;
    }
	
    /*
     * onCreate is life-cycle method of service. regardless of bound or started service, this method gets called once upon first creation.
     */
	@Override
    public void onCreate() {
		Log.d(TAG,"onCreate()");
		
		// populate attributes with XML resource values
		clientPath = getString(R.string.client_path); 
		clientName = getString(R.string.client_name); 
		clientCLI = getString(R.string.client_cli); 
		clientCABundle = getString(R.string.client_cabundle); 
		authFileName = getString(R.string.auth_file_name); 
		allProjectsList = getString(R.string.all_projects_list); 
		globalOverridePreferences = getString(R.string.global_prefs_override); 
		
		// initialize singleton helper classes and provide application context
		getClientStatus().setCtx(this);
		getAppPrefs().readPrefs(this);
		
		if(!started) {
			started = true;
	        (new ClientMonitorAsync()).execute(new Integer[0]); //start monitor in new thread
	        Log.d(TAG, "asynchronous monitor started!");
		}
		else {
			Log.d(TAG, "asynchronous monitor NOT started!");
		}

        Toast.makeText(this, "BOINC Monitor Service Starting", Toast.LENGTH_SHORT).show();
	}
	
    /*
     * this should not be reached
    */
    @Override
    public void onDestroy() {
    	Log.d(TAG,"onDestroy()");
    	
        // Cancel the persistent notification.
    	//
    	((NotificationManager)getSystemService(Service.NOTIFICATION_SERVICE)).cancel(getResources().getInteger(R.integer.autostart_notification_id));
        
    	// Abort the ClientMonitorAsync thread
    	//
    	monitorRunning = false;
		monitorThread.interrupt();
    	
    	// Now we can safely stop the client
    	//
		quitClient();
        
        Toast.makeText(this, "BOINC Monitor Service Stopped", Toast.LENGTH_SHORT).show();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {	
    	//this gets called after startService(intent) (either by BootReceiver or AndroidBOINCActivity, depending on the user's autostart configuration)
    	Log.d(TAG, "onStartCommand()");
		/*
		 * START_NOT_STICKY is now used and replaced START_STICKY in previous implementations.
		 * Lifecycle events - e.g. killing apps by calling their "onDestroy" methods, or killing an app in the task manager - does not effect the non-Dalvik code like the native BOINC Client.
		 * Therefore, it is not necessary for the service to get reactivated. When the user navigates back to the app (BOINC Manager), the service gets re-started from scratch.
		 * Con: After user navigates back, it takes some time until current Client status is present.
		 * Pro: Saves RAM/CPU.
		 * 
		 * For detailed service documentation see
		 * http://android-developers.blogspot.com.au/2010/02/service-api-changes-starting-with.html
		 */
		return START_NOT_STICKY;
    }

    //sends broadcast about login (or register) result for login activity
	private void sendLoginResultBroadcast(Integer type, Integer result, String message) {
        Intent loginResults = new Intent();
        loginResults.setAction("edu.berkeley.boinc.loginresults");
        loginResults.putExtra("type", type);
        loginResults.putExtra("result", result);
        loginResults.putExtra("message", message);
        getApplicationContext().sendBroadcast(loginResults,null);
	}
	
    public void restartMonitor() {
    	if(Monitor.monitorActive) { //monitor is already active, launch cancelled
    		BOINCActivity.logMessage(getApplicationContext(), TAG, "monitor active - restart cancelled");
    	}
    	else {
        	Log.d(TAG,"restart monitor");
        	(new ClientMonitorAsync()).execute(new Integer[0]);
    	}
    }
    
    public void forceRefresh() {
    	Log.d(TAG,"forceRefresh()");
    	if(monitorThread != null) {
    		monitorThread.interrupt();
    	}
    }
    
    public void quitClient() {
    	(new ShutdownClientAsync()).execute();
    }
    
    public void attachProjectAsync(String url, String name, String email, String pwd) {
		Log.d(TAG,"attachProjectAsync");
		String[] param = new String[4];
		param[0] = url;
		param[1] = name;
		param[2] = email;
		param[3] = pwd;
		(new ProjectAttachAsync()).execute(param);
    }
    
	public void setRunMode(Integer mode) {
		//execute in different thread, in order to avoid network communication in main thread and therefore ANR errors
		(new WriteClientRunModeAsync()).execute(mode);
	}
	
	public void setPrefs(GlobalPreferences globalPrefs) {
		//execute in different thread, in order to avoid network communication in main thread and therefore ANR errors
		(new WriteClientPrefsAsync()).execute(globalPrefs);
	}
	
	public String readAuthToken() {
		File authFile = new File(clientPath+authFileName);
    	StringBuffer fileData = new StringBuffer(100);
    	char[] buf = new char[1024];
    	int read = 0;
    	try{
    		BufferedReader br = new BufferedReader(new FileReader(authFile));
    		while((read=br.read(buf)) != -1){
    	    	String readData = String.valueOf(buf, 0, read);
    	    	fileData.append(readData);
    	    	buf = new char[1024];
    	    }
    		br.close();
    	}
    	catch (FileNotFoundException fnfe) {
    		Log.e(TAG, "auth file not found",fnfe);
    	}
    	catch (IOException ioe) {
    		Log.e(TAG, "ioexception",ioe);
    	}

		String authKey = fileData.toString();
		Log.d(TAG, "authKey: " + authKey);
		return authKey;
	}
	
	public Boolean attachProject(String url, String name, String authenticator) {
    	Boolean success = false;
    	success = rpc.projectAttach(url, authenticator, name); //asynchronous call to attach project
    	if(success) { //only continue if attach command did not fail
    		// verify success of projectAttach with poll function
    		success = false;
    		Integer counter = 0;
    		Integer sleepDuration = 500; //in milliseconds
    		Integer maxLoops = maxDuration / sleepDuration;
    		while(!success && (counter < maxLoops)) {
    			try {
    				Thread.sleep(sleepDuration);
    			} catch (Exception e) {}
    			counter ++;
    			ProjectAttachReply reply = rpc.projectAttachPoll();
    			Integer result = reply.error_num;
    			if(result == 0) {
    				success = true;
    			}
    		}
    	}
    	return success;
    }
	
	public Boolean checkProjectAttached(String url) {
		//TODO
		return false;
	}
	
	public AccountOut lookupCredentials(String url, String id, String pwd) {
    	Integer retval = -1;
    	AccountOut auth = null;
    	AccountIn credentials = new AccountIn();
    	credentials.email_addr = id;
    	credentials.passwd = pwd;
    	credentials.url = url;
    	Boolean success = rpc.lookupAccount(credentials); //asynch
    	if(success) { //only continue if lookupAccount command did not fail
    		//get authentication token from lookupAccountPoll
    		Integer counter = 0;
    		Integer sleepDuration = 500; //in milliseconds
    		Integer maxLoops = maxDuration / sleepDuration;
    		Boolean loop = true;
    		while(loop && (counter < maxLoops)) {
    			loop = false;
    			try {
    				Thread.sleep(sleepDuration);
    			} catch (Exception e) {}
    			counter ++;
    			auth = rpc.lookupAccountPoll();
    			if(auth==null) {
    				return null;
    			}
    			if (auth.error_num == -204) {
    				loop = true; //no result yet, keep looping
    			}
    			else {
    				//final result ready
    				retval = auth.error_num;
    				if(auth.error_num == 0) { 
        				Log.d(TAG, "credentials verification result, retrieved authenticator: " + auth.authenticator);
    				}
    			}
    		}
    	}
    	Log.d(TAG, "lookupCredentials returns " + retval);
    	return auth;
    }
	
	public Boolean detachProject(String url){
		return rpc.projectOp(RpcClient.PROJECT_DETACH, url);
	}
	
	public void detachProjectAsync(String url){
		Log.d(TAG, "detachProjectAsync");
		String[] param = new String[1];
		param[0] = url;
		(new ProjectDetachAsync()).execute(param);
	}
    
	public Boolean abortTransfer(String url, String name){
		return rpc.transferOp(RpcClient.TRANSFER_ABORT, url, name);
	}
	
	public void abortTransferAsync(String url, String name){
		Log.d(TAG, "abortTransferAsync");
		String[] param = new String[2];
		param[0] = url;
		param[1] = name;
		(new TransferAbortAsync()).execute(param);
	}
    
	public Boolean updateProject(String url){
		return rpc.projectOp(RpcClient.PROJECT_UPDATE, url);
	}
	
	public void updateProjectAsync(String url){
		Log.d(TAG, "updateProjectAsync");
		String[] param = new String[1];
		param[0] = url;
		(new ProjectUpdateAsync()).execute(param);
	}
    
	public Boolean retryTransfer(String url, String name){
		return rpc.transferOp(RpcClient.TRANSFER_RETRY, url, name);
	}
	
	public void retryTransferAsync(String url, String name){
		Log.d(TAG, "retryTransferAsync");
		String[] param = new String[2];
		param[0] = url;
		param[1] = name;
		(new TransferRetryAsync()).execute(param);
	}
    
    public void createAccountAsync(String url, String email, String userName, String pwd, String teamName) {
		Log.d(TAG,"createAccountAsync");
		String[] param = new String[5];
		param[0] = url;
		param[1] = email;
		param[2] = userName;
		param[3] = pwd;
		param[4] = teamName;
		(new CreateAccountAsync()).execute(param);
    }
	
	public AccountOut createAccount(String url, String email, String userName, String pwd, String teamName) {
		AccountIn information = new AccountIn();
		information.url = url;
		information.email_addr = email;
		information.user_name = userName;
		information.passwd = pwd;
		information.team_name = teamName;
		
		AccountOut auth = null;
		
    	Boolean success = rpc.createAccount(information); //asynchronous call to attach project
    	if(success) { //only continue if attach command did not fail
    		// verify success of projectAttach with poll function
    		Integer counter = 0;
    		Integer sleepDuration = 500; //in milliseconds
    		Integer maxLoops = maxDuration / sleepDuration;
    		Boolean loop = true;
    		while(loop && (counter < maxLoops)) {
    			loop = false;
    			try {
    				Thread.sleep(sleepDuration);
    			} catch (Exception e) {}
    			counter ++;
    			auth = rpc.createAccountPoll();
    			if(auth==null) {
    				return null;
    			}
    			if (auth.error_num == -204) {
    				loop = true; //no result yet, keep looping
    			}
    			else {
    				//final result ready
    				if(auth.error_num == 0) { 
        				Log.d(TAG, "account creation result, retrieved authenticator: " + auth.authenticator);
    				}
    			}
    		}
    	}
    	return auth;
	}
	
	private final class ClientMonitorAsync extends AsyncTask<Integer, String, Boolean> {

		private final String TAG = "BOINC ClientMonitorAsync";
		private final Boolean showRpcCommands = false;
		
		// Frequency of which the monitor updates client status via RPC, to often can cause reduced performance!
		private Integer refreshFrequency = getResources().getInteger(R.integer.monitor_refresh_rate_ms);
		
		@Override
		protected Boolean doInBackground(Integer... params) {
			// Save current thread, to interrupt sleep from outside...
			monitorThread = Thread.currentThread();
			while(monitorRunning) {
				publishProgress("doInBackground() monitor loop...");
				
				if(!rpc.connectionAlive()) { //check whether connection is still alive
					// If connection is not working, either client has not been set up yet or client crashed.
					(new ClientSetupAsync()).execute();
				} else {
					if(showRpcCommands) Log.d(TAG, "getCcStatus");
					CcStatus status = rpc.getCcStatus();
					/*
					if(showRpcCommands) Log.d(TAG, "getState"); 
					CcState state = rpc.getState();
					*/
					if(showRpcCommands) Log.d(TAG, "getResults");
					ArrayList<Result>  results = rpc.getResults();
					if(showRpcCommands) Log.d(TAG, "getProjects");
					ArrayList<Project>  projects = rpc.getProjectStatus();
					if(showRpcCommands) Log.d(TAG, "getTransers");
					ArrayList<Transfer>  transfers = rpc.getFileTransfers();
					if(showRpcCommands) Log.d(TAG, "getGlobalPrefsWorkingStruct");
					GlobalPreferences clientPrefs = rpc.getGlobalPrefsWorkingStruct();
					ArrayList<Message> msgs = new ArrayList<Message>();
					Integer count = rpc.getMessageCount();
					msgs = rpc.getMessages(count - 250); //get the most recent 250 messages
					if(showRpcCommands) Log.d(TAG, "getMessages, count: " + count);
					
					if( (status != null) && (results != null) && (projects != null) && (transfers != null) &&
					    (clientPrefs != null)
					) {
						Monitor.clientStatus.setClientStatus(status, results, projects, transfers, clientPrefs, msgs);
					} else {
						BOINCActivity.logMessage(getApplicationContext(), TAG, "client status connection problem");
					}
					
			        Intent clientStatus = new Intent();
			        clientStatus.setAction("edu.berkeley.boinc.clientstatus");
			        getApplicationContext().sendBroadcast(clientStatus);
				}
				
	    		try {
	    			Thread.sleep(refreshFrequency);
	    		} catch(InterruptedException e) {}
			}

			return true;
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate() " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			Log.d(TAG, "onPostExecute() monitor exit"); 
			Monitor.monitorActive = false;
		}
	}
	
	private final class ClientSetupAsync extends AsyncTask<Void,String,Boolean> {
		private final String TAG = "BOINC ClientSetupAsync";
		
		private Integer retryRate = getResources().getInteger(R.integer.monitor_setup_connection_retry_rate_ms);
		private Integer retryAttempts = getResources().getInteger(R.integer.monitor_setup_connection_retry_attempts);
		
		@Override
		protected void onPreExecute() {
			if(Monitor.clientSetupActive) { // setup is already running, cancel execution...
				cancel(false);
			} else {
				Log.d(TAG, "onPreExecute - running setup.");
				Monitor.clientSetupActive = true;
				getClientStatus().setupStatus = ClientStatus.SETUP_STATUS_LAUNCHING;
				getClientStatus().fire();
			}
		}
		
		@Override
		protected Boolean doInBackground(Void... params) {
			return startUp();
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			Monitor.clientSetupActive = false;
			if(success) {
				Log.d(TAG, "onPostExecute - setup completed successfully"); 
				getClientStatus().setupStatus = ClientStatus.SETUP_STATUS_AVAILABLE;
				// do not fire new client status here, wait for ClientMonitorAsync to retrieve initial status
				forceRefresh();
			} else {
				Log.d(TAG, "onPostExecute - setup experienced an error"); 
				getClientStatus().setupStatus = ClientStatus.SETUP_STATUS_ERROR;
				getClientStatus().fire();
			}
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate - " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
		
		private Boolean startUp() {

			String clientProcessName = clientPath + clientName;
			Integer clientPid = null;

			String md5AssetClient = ComputeMD5Asset(clientName);
			publishProgress("Hash of client (Asset): '" + md5AssetClient + "'");

			String md5InstalledClient = ComputeMD5File(clientPath + clientName);
			publishProgress("Hash of client (File): '" + md5InstalledClient + "'");

			// If client hashes do not match, we need to install the one that is a part
			// of the package. Shutdown the currently running client if needed.
			//
			if (md5InstalledClient.compareToIgnoreCase(md5AssetClient) != 0) {

				// Determine if BOINC is already running.
				//
				clientPid = getPidForProcessName(clientProcessName);
				if(clientPid != null) {

					// Do not just kill the client on the first attempt.  That leaves dangling 
					// science applications running which causes repeated spawning of applications.
					// Neither the UI or client are happy and each are trying to recover from the
					// situation.  Instead send SIGQUIT and give the client time to clean up.
					//
					publishProgress("Gracefully shutting down BOINC client (" + clientPid +")");
					android.os.Process.sendSignal(clientPid, android.os.Process.SIGNAL_QUIT);

					// Wait for up to 15 seconds for the client to shutdown gracefully
					//
					for (Integer i = 0; i <= 15; i++) {
						clientPid = getPidForProcessName(clientProcessName);
						if(clientPid != null) {
							publishProgress("Waiting on BOINC client (" + clientPid + ") to shutdown");
							try {
								Thread.sleep(1000);
							} catch (Exception e) {}
						} else {
							break;
						}
					}

					// If the client has not shutdown by now, force terminate it
					//
					clientPid = getPidForProcessName(clientProcessName);
					if(clientPid != null) {
						publishProgress("Forcefully terminating BOINC client (" + clientPid + ")");
						android.os.Process.killProcess(clientPid);
						clientPid = null;
					}	
				}

				// Install BOINC client software
				//
		        if(!installClient()) {
		        	publishProgress("BOINC client installation failed!");
		        	return false;
		        }
			}
			
			
			// Start the BOINC client if we need to.
			//
			clientPid = getPidForProcessName(clientProcessName);
			if(clientPid == null) {
	        	publishProgress("Starting the BOINC client");
				if (!runClient()) {
		        	publishProgress("BOINC client failed to start");
					return false;
				}
			}

			
			// Try to connect to executed Client in loop
			//
			Boolean connected = false;
			Integer counter = 0;
			while(!connected && (counter < retryAttempts)) {
				publishProgress("Attempting BOINC client connection...");
				connected = connectClient();
				counter++;

				try {
					Thread.sleep(retryRate);
				} catch (Exception e) {}
			}
			
			return connected;
		}
		
	    // Executes the BOINC client using the Java Runtime exec method.
		//
	    private Boolean runClient() {
	    	Boolean success = false;
	    	try { 
	    		String[] cmd = new String[2];
	    		
	    		cmd[0] = clientPath + clientName;
	    		cmd[1] = "--daemon";
	    		
	        	clientProcess = Runtime.getRuntime().exec(cmd, null, new File(clientPath));
	        	success = true;
	    	} catch (IOException e) {
	    		Log.d(TAG, "Starting BOINC client failed with exception: " + e.getMessage());
	    		Log.e(TAG, "IOException", e);
	    	}
	    	return success;
	    }

		private Boolean connectClient() {
			Boolean success = false;
			
	        success = connect();
	        if(!success) {
	        	publishProgress("connection failed!");
	        	return success;
	        }
	        
	        //authorize
	        success = authorize();
	        if(!success) {
	        	publishProgress("authorization failed!");
	        }
	        return success;
		}
		
		// Copies the binaries of BOINC client from assets directory into 
		// storage space of this application
		//
	    private Boolean installClient(){

			installFile(clientName, true, true);
			installFile(clientCLI, true, true);
			installFile(clientCABundle, true, false);
			installFile(allProjectsList, true, false);
			installFile(globalOverridePreferences, false, false);
	    	
			//TODO return proper status
	    	return true; 
	    }
	    
		private Boolean installFile(String file, Boolean override, Boolean executable) {
	    	Boolean success = false;
	    	byte[] b = new byte [1024];
    		int count; 
			
    		try {
    			Log.d(TAG, "installing: " + file);
    			
	    		File target = new File(clientPath + file);
	    		
	    		// Check path and create it
	    		File installDir = new File(clientPath);
	    		if(!installDir.exists()) {
	    			installDir.mkdir();
	    			installDir.setWritable(true); 
	    		}
	    		
	    		// Delete old target
	    		if(override && target.exists()) {
	    			target.delete();
	    		}
	    		
	    		// Copy file from the asset manager to clientPath
	    		InputStream asset = getApplicationContext().getAssets().open(file); 
	    		OutputStream targetData = new FileOutputStream(target); 
	    		while((count = asset.read(b)) != -1){ 
	    			targetData.write(b, 0, count);
	    		}
	    		asset.close(); 
	    		targetData.flush(); 
	    		targetData.close();

	    		success = true; //copy succeeded without exception
	    		
	    		// Set executable, if requested
	    		Boolean isExecutable = false;
	    		if(executable) {
	    			target.setExecutable(executable);
	    			isExecutable = target.canExecute();
	    			success = isExecutable; // return false, if not executable
	    		}

	    		publishProgress("install of " + file + " successfull. executable: " + executable + "/" + isExecutable);
	    		
	    	} catch (IOException e) {  
	    		Log.d(TAG, "IOException: " + e.getMessage());
	    		Log.e(TAG, "IOException", e);
	    		
	    		publishProgress("install of " + file + " failed.");
	    	}
			
			return success;
		}

	    // Connects to running BOINC client.
	    //
	    private Boolean connect() {
	    	return rpc.open("127.0.0.1", 31416);
	    }
	    
	    // Authorizes this application as valid RPC Manager by reading auth token from file 
	    // and making RPC call.
	    //
	    private Boolean authorize() {
	    	String authKey = readAuthToken();
			
			//trigger client rpc
			return rpc.authorize(authKey); 
	    }
		
		// Get PID for process name using native 'ps' console command
	    //
	    private Integer getPidForProcessName(String processName) {
	    	int count;
	    	char[] buf = new char[1024];
	    	StringBuffer sb = new StringBuffer();
	    	
	    	//run ps and read output
	    	try {
		    	Process p = Runtime.getRuntime().exec("ps");
		    	p.waitFor();
		    	InputStreamReader isr = new InputStreamReader(p.getInputStream());
		    	while((count = isr.read(buf)) != -1)
		    	{
		    	    sb.append(buf, 0, count);
		    	}
	    	} catch (Exception e) {
	    		Log.d(TAG, "Exception: " + e.getMessage());
	    		Log.e(TAG, "Exception", e);
	    	}
	    	
	    	//parse output into hashmap
	    	HashMap<String,Integer> pMap = new HashMap<String, Integer>();
	    	String [] processLinesAr = sb.toString().split("\n");
	    	for(String line : processLinesAr)
	    	{
	    		Integer pid;
	    		String packageName;
	    	    String [] comps = line.split("[\\s]+");
	    	    if(comps.length != 9) {continue;}     
	    	    pid = Integer.parseInt(comps[1]);
	    	    packageName = comps[8];
	    	    pMap.put(packageName, pid);
	    	    //Log.d(TAG,"added: " + packageName + pid); 
	    	}
	    	
	    	// Find required pid
	    	return pMap.get(processName);
	    }

	    // Compute MD5 of the requested asset
	    //
	    private String ComputeMD5Asset(String file) {
	    	byte[] b = new byte [1024];
    		int count; 
			
    		try {
    			MessageDigest md5 = MessageDigest.getInstance("MD5");

    			InputStream asset = getApplicationContext().getAssets().open(file); 
	    		while((count = asset.read(b)) != -1){ 
	    			md5.update(b, 0, count);
	    		}
	    		asset.close();
	    		
				byte[] md5hash = md5.digest();
				StringBuilder sb = new StringBuilder();
				for (int i = 0; i < md5hash.length; ++i) {
					sb.append(String.format("%02x", md5hash[i]));
				}
	    		
	    		return sb.toString();
	    	} catch (IOException e) {  
	    		Log.d(TAG, "IOException: " + e.getMessage());
	    		Log.e(TAG, "IOException", e);
	    	} catch (NoSuchAlgorithmException e) {
	    		Log.d(TAG, "NoSuchAlgorithmException: " + e.getMessage());
	    		Log.e(TAG, "NoSuchAlgorithmException", e);
			}
			
			return "";
	    }

	    // Compute MD5 of the requested file
	    //
	    private String ComputeMD5File(String file) {
	    	byte[] b = new byte [1024];
    		int count; 
			
    		try {
    			MessageDigest md5 = MessageDigest.getInstance("MD5");

	    		File target = new File(file);
	    		InputStream asset = new FileInputStream(target); 
	    		while((count = asset.read(b)) != -1){ 
	    			md5.update(b, 0, count);
	    		}
	    		asset.close();

				byte[] md5hash = md5.digest();
				StringBuilder sb = new StringBuilder();
				for (int i = 0; i < md5hash.length; ++i) {
					sb.append(String.format("%02x", md5hash[i]));
				}
	    		
	    		return sb.toString();
	    	} catch (IOException e) {  
	    		Log.d(TAG, "IOException: " + e.getMessage());
	    		Log.e(TAG, "IOException", e);
	    	} catch (NoSuchAlgorithmException e) {
	    		Log.d(TAG, "NoSuchAlgorithmException: " + e.getMessage());
	    		Log.e(TAG, "NoSuchAlgorithmException", e);
			}
			
			return "";
	    }
	}
	
	private final class ProjectAttachAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "ProjectAttachAsync";
		
		private String url;
		private String projectName;
		private String email;
		private String pwd;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			this.projectName = params[1];
			this.email = params[2];
			this.pwd = params[3];
			Log.d(TAG+"-doInBackground","attachProjectAsync started with: " + url + "-" + projectName + "-" + email + "-" + pwd);
			
			AccountOut auth = lookupCredentials(url,email,pwd);
			
			if(auth == null) {
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_LOGIN,-1,"null");
				Log.d(TAG, "verification failed - exit");
				return false;
			}
			
			if(auth.error_num != 0) { // an error occured
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_LOGIN,auth.error_num,auth.error_msg);
				Log.d(TAG, "verification failed - exit");
				return false;
			}
			Boolean attach = attachProject(url, email, auth.authenticator); 
			if(attach) {
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_LOGIN,0,"Successful!");
			}
			return attach;
		}
	}
	
	private final class CreateAccountAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "CreateAccountAsync";
		
		private String url;
		private String email;
		private String userName;
		private String pwd;
		private String teamName;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			this.email = params[1];
			this.userName = params[2];
			this.pwd = params[3];
			this.teamName = params[4];
			Log.d(TAG+"-doInBackground","creating account with: " + url + "-" + email + "-" + userName + "-" + pwd + "-" + teamName);
			
			
			AccountOut auth = createAccount(url, email, userName, pwd, teamName);
			
			if(auth == null) {
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_REGISTRATION,-1,"null");
				Log.d(TAG, "verification failed - exit");
				return false;
			}
			
			if(auth.error_num != 0) { // an error occured
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_REGISTRATION,auth.error_num,auth.error_msg);
				Log.d(TAG, "verification failed - exit");
				return false;
			}
			Boolean attach = attachProject(url, email, auth.authenticator); 
			if(attach) {
				sendLoginResultBroadcast(LoginActivity.BROADCAST_TYPE_REGISTRATION,0,"Successful!");
			}
			return attach;
		}
	}
	
	private final class ProjectDetachAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "ProjectDetachAsync";
		
		private String url;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			Log.d(TAG+"-doInBackground","ProjectDetachAsync url: " + url);
			
			Boolean detach = rpc.projectOp(RpcClient.PROJECT_DETACH, url);
			if(detach) {
				Log.d(TAG, "successful.");
			}
			return detach;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}
	}

	private final class ProjectUpdateAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "ProjectUpdateAsync";
		
		private String url;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			Log.d(TAG, "doInBackground() - ProjectUpdateAsync url: " + url);
			
			Boolean update = rpc.projectOp(RpcClient.PROJECT_UPDATE, url);
			if(update) {
				Log.d(TAG, "successful.");
			}
			return update;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}
	}

	private final class TransferAbortAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "TransferAbortAsync";
		
		private String url;
		private String name;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			this.name = params[0];
			publishProgress("doInBackground() - TransferAbortAsync url: " + url + " Name: " + name);
			
			Boolean abort = rpc.transferOp(RpcClient.TRANSFER_ABORT, url, name);
			if(abort) {
				Log.d(TAG, "successful.");
			}
			return abort;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate - " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
	}

	private final class TransferRetryAsync extends AsyncTask<String,String,Boolean> {

		private final String TAG = "TransferRetryAsync";
		
		private String url;
		private String name;
		
		@Override
		protected Boolean doInBackground(String... params) {
			this.url = params[0];
			this.name = params[1];
			publishProgress("doInBackground() - TransferRetryAsync url: " + url + " Name: " + name);
			
			Boolean retry = rpc.transferOp(RpcClient.TRANSFER_RETRY, url, name);
			if(retry) {
				publishProgress("successful.");
			}
			return retry;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate - " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
	}

	private final class WriteClientPrefsAsync extends AsyncTask<GlobalPreferences,Void,Boolean> {

		private final String TAG = "WriteClientPrefsAsync";
		@Override
		protected Boolean doInBackground(GlobalPreferences... params) {
			Log.d(TAG, "doInBackground");
			Boolean retval1 = rpc.setGlobalPrefsOverrideStruct(params[0]); //set new override settings
			Boolean retval2 = rpc.readGlobalPrefsOverride(); //trigger reload of override settings
			Log.d(TAG,retval1.toString() + retval2);
			if(retval1 && retval2) {
				Log.d(TAG, "successful.");
				return true;
			}
			return false;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}
	}
	
	private final class WriteClientRunModeAsync extends AsyncTask<Integer, String, Boolean> {

		private final String TAG = "WriteClientRunModeAsync";
		
		@Override
		protected Boolean doInBackground(Integer... params) {
			Boolean success = rpc.setRunMode(params[0], 0);
        	publishProgress("run mode set to " + params[0] + " returned " + success);
			return success;
		}
		
		@Override
		protected void onPostExecute(Boolean success) {
			forceRefresh();
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate - " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
	}
	
	private final class ShutdownClientAsync extends AsyncTask<Void, String, Boolean> {

		private final String TAG = "ShutdownClientAsync";

		@Override
		protected Boolean doInBackground(Void... params) {
	    	Boolean success = rpc.quit();
        	publishProgress("Graceful shutdown returned " + success);
			if(!success) {
				clientProcess.destroy();
	        	publishProgress("Process killed");
			}
			return success;
		}

		@Override
		protected void onProgressUpdate(String... arg0) {
			Log.d(TAG, "onProgressUpdate - " + arg0[0]);
			BOINCActivity.logMessage(getApplicationContext(), TAG, arg0[0]);
		}
	}
}
