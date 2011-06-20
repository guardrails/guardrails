<%@ Page Language="C#" AutoEventWireup="true" CodeFile="Tooltip.aspx.cs" Inherits="Tooltip" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>无标题页</title>
 <script type="text/javascript" src="swfobject.js"></script>

    <script type="text/javascript">
swfobject.embedSWF("open-flash-chart.swf", "my_chart", "100%", "500",
  "9.0.0", "expressInstall.swf",
  {"data-file":"datafile/Tooltip.aspx"}
  );
    </script>

</head>
<body>
    <form id="form1" runat="server">
        <div id="my_chart">
        </div>
    </form>
</body>
</html>
