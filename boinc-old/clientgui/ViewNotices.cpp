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

#if defined(__GNUG__) && !defined(__APPLE__)
#pragma implementation "ViewNotices.h"
#endif

#include "stdwx.h"
#include "BOINCGUIApp.h"
#include "BOINCBaseFrame.h"
#include "MainDocument.h"
#include "AdvancedFrame.h"
#include "BOINCTaskCtrl.h"
#include "ViewNotices.h"
#include "NoticeListCtrl.h"
#include "BOINCInternetFSHandler.h"
#include "Events.h"
#include "error_numbers.h"


#include "res/mess.xpm"


IMPLEMENT_DYNAMIC_CLASS(CViewNotices, CBOINCBaseView)

BEGIN_EVENT_TABLE (CViewNotices, CBOINCBaseView)
    EVT_NOTICELIST_ITEM_DISPLAY(CViewNotices::OnLinkClicked)
    EVT_BUTTON( ID_LIST_RELOADNOTICES, CViewNotices::OnRetryButton )
END_EVENT_TABLE ()


CViewNotices::CViewNotices()
{}


CViewNotices::CViewNotices(wxNotebook* pNotebook) :
    CBOINCBaseView(pNotebook)
{
    //
    // Setup View
    //
    wxFlexGridSizer* itemReloadButtonSizer = new wxFlexGridSizer(1, 2, 0, 0);
    itemReloadButtonSizer->AddGrowableCol(1);
   
    m_ReloadNoticesText = new wxStaticText(this, wxID_ANY,
                            _("One or more items failed to load from the Internet."),
                            wxDefaultPosition, wxDefaultSize, 0
                            );

    itemReloadButtonSizer->Add(m_ReloadNoticesText, 1, wxALL, 5);
    
    m_ReloadNoticesButton = new wxButton(
                                    this, ID_LIST_RELOADNOTICES,
                                    _("Retry now"),
                                    wxDefaultPosition, wxDefaultSize, 0
                                    );

    itemReloadButtonSizer->Add(m_ReloadNoticesButton, 1, wxALL, 5);

    wxFlexGridSizer* itemFlexGridSizer = new wxFlexGridSizer(2, 1, 1, 0);
    wxASSERT(itemFlexGridSizer);

    itemFlexGridSizer->AddGrowableRow(1);
    itemFlexGridSizer->AddGrowableCol(0);

    itemFlexGridSizer->Add(itemReloadButtonSizer, 1, wxGROW|wxALL, 1);

	m_pHtmlListPane = new CNoticeListCtrl(this);
	wxASSERT(m_pHtmlListPane);

    itemFlexGridSizer->Add(m_pHtmlListPane, 1, wxGROW|wxALL, 1);

    SetSizer(itemFlexGridSizer);
    
    m_FetchingNoticesText = new wxStaticText(
                                    this, wxID_ANY, 
                                    _("Fetching notices; please wait..."), 
                                    wxPoint(20, 20), wxDefaultSize, 0
                                    );

    m_NoNoticesText = new wxStaticText(
                                    this, wxID_ANY, 
                                    _("There are no notices at this time."), 
                                    wxPoint(20, 20), wxDefaultSize, 0
                                    );
    m_FetchingNoticesText->Hide();
    m_NoNoticesText->Hide();
    m_ReloadNoticesText->Hide();
    m_ReloadNoticesButton->Hide();
    
    m_bMissingItems =  false;
}


CViewNotices::~CViewNotices() {
}


wxString& CViewNotices::GetViewName() {
    static wxString strViewName(wxT("Notices"));
    return strViewName;
}


wxString& CViewNotices::GetViewDisplayName() {
    static wxString strViewName(_("Notices"));
    return strViewName;
}


const char** CViewNotices::GetViewIcon() {
    return mess_xpm;
}


int CViewNotices::GetViewRefreshRate() {
    return 10;
}

int CViewNotices::GetViewCurrentViewPage() {
    return VW_NOTIF;
}


bool CViewNotices::OnSaveState(wxConfigBase* WXUNUSED(pConfig)) {
    return true;
}


bool CViewNotices::OnRestoreState(wxConfigBase* WXUNUSED(pConfig)) {
    return true;
}


void CViewNotices::OnListRender(wxTimerEvent& WXUNUSED(event)) {
    wxLogTrace(wxT("Function Start/End"), wxT("CViewNotices::OnListRender - Function Begin"));

    static bool s_bInProgress = false;
    static wxString strLastMachineName = wxEmptyString;
    wxString strNewMachineName = wxEmptyString;
    bool bMissingItems;
    CC_STATUS status;
    CMainDocument* pDoc = wxGetApp().GetDocument();
    wxFileSystemHandler *internetFSHandler = wxGetApp().GetInternetFSHandler();
    
    wxASSERT(pDoc);
	wxASSERT(m_pHtmlListPane);
    wxASSERT(wxDynamicCast(pDoc, CMainDocument));
    wxASSERT(internetFSHandler);
    
    if (s_bInProgress) return;
    s_bInProgress = true;

    if (pDoc->IsConnected()) {
        pDoc->GetConnectedComputerName(strNewMachineName);
        if (strLastMachineName != strNewMachineName) {
            strLastMachineName = strNewMachineName;
            m_FetchingNoticesText->Show();
            m_NoNoticesText->Hide();
            ((CBOINCInternetFSHandler*)internetFSHandler)->ClearCache();
            m_pHtmlListPane->Clear();
            if (m_bMissingItems) {
                m_ReloadNoticesText->Hide();
                m_ReloadNoticesButton->Hide();
                m_bMissingItems = false;
                Layout();
            }
        }
    } else {
        m_pHtmlListPane->Clear();
    }

    // Don't call Freeze() / Thaw() here because it causes an unnecessary redraw
    m_pHtmlListPane->UpdateUI();

    bMissingItems = ((CBOINCInternetFSHandler*)internetFSHandler)->ItemsFailedToLoad();
    if (bMissingItems != m_bMissingItems) {
        m_ReloadNoticesText->Show(bMissingItems);
        m_ReloadNoticesButton->Show(bMissingItems);
        Layout();
        m_bMissingItems = bMissingItems;
    }
    
    m_FetchingNoticesText->Show(m_pHtmlListPane->m_bDisplayFetchingNotices);
    m_NoNoticesText->Show(m_pHtmlListPane->m_bDisplayEmptyNotice);
    pDoc->UpdateUnreadNoticeState();

    s_bInProgress = false;

    wxLogTrace(wxT("Function Start/End"), wxT("CViewNotices::OnListRender - Function End"));
}


void CViewNotices::OnLinkClicked( NoticeListCtrlEvent& event ) {
    if (event.GetURL().StartsWith(wxT("http://"))) {
		wxLaunchDefaultBrowser(event.GetURL());
    }
}


void CViewNotices::OnRetryButton( wxCommandEvent& ) {
    m_ReloadNoticesText->Hide();
    m_ReloadNoticesButton->Hide();
    m_bMissingItems = false;
    Layout();
    ReloadNotices();
}


void CViewNotices::ReloadNotices() {
    wxFileSystemHandler *internetFSHandler = wxGetApp().GetInternetFSHandler();
    if (internetFSHandler) {
        ((CBOINCInternetFSHandler*)internetFSHandler)->UnchacheMissingItems();
        m_pHtmlListPane->Clear();
        m_FetchingNoticesText->Show();
        m_NoNoticesText->Hide();
    }
}
