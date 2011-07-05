<%@ Page Language="C#" AutoEventWireup="true" CodeFile="stackbar.aspx.cs" Inherits="stackbar" %>

<%@ Register Assembly="OpenFlashChart" Namespace="OpenFlashChart" TagPrefix="cc1" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>无标题页</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <cc1:openflashchartcontrol id="OpenFlashChartControl1" runat="server" datafile="datafile/stackbar.aspx"></cc1:openflashchartcontrol>
    
    </div>
    </form>
</body>
</html>
