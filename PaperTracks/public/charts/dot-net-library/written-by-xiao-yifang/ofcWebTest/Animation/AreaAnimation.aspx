<%@ Page Language="C#" AutoEventWireup="true" CodeFile="AreaAnimation.aspx.cs" Inherits="Animation_AreaAnimation" %>

<%@ Register Assembly="OpenFlashChart" Namespace="OpenFlashChart" TagPrefix="cc1" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>无标题页</title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <cc1:OpenFlashChartControl ID="OpenFlashChartControl1" runat="server">
            </cc1:OpenFlashChartControl>
            animation type&nbsp;<asp:DropDownList ID="DropDownList1" runat="server">
                <asp:ListItem>pop-up</asp:ListItem>
                <asp:ListItem>explode</asp:ListItem>
                <asp:ListItem>mid-slide</asp:ListItem>
                <asp:ListItem>drop</asp:ListItem>
                <asp:ListItem>fade-in</asp:ListItem>
                <asp:ListItem>shrink-in</asp:ListItem>
            </asp:DropDownList>cascade<asp:TextBox ID="TextBox1" runat="server">1</asp:TextBox>delay<asp:TextBox
                ID="TextBox2" runat="server">0.5</asp:TextBox><br />
            <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Button" /></div>
    </form>
</body>
</html>
