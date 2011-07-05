<%@ Page Language="C#" AutoEventWireup="true"  CodeFile="Default.aspx.cs" Inherits="_Default" %>

<%@ Register Assembly="OpenFlashChart" Namespace="OpenFlashChart" TagPrefix="cc1" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>无标题页</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <cc1:OpenFlashChartControl ID="OpenFlashChartControl1" runat="server" EnableCache="false" LoadingMsg="test loading...">
        </cc1:OpenFlashChartControl>
        <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="ChangeChartTitle" />
        <asp:Button ID="Button2" runat="server" OnClick="Button2_Click" Text="RestoreDefaultTitle" /></div>
        &amp;&amp;
    </form>
</body>
</html>
