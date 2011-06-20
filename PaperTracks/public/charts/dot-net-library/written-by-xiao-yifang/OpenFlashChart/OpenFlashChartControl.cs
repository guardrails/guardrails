using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel;
using System.Web;
using System.Web.Caching;
using System.Web.UI;

namespace OpenFlashChart
{
    [Designer(typeof(ChartControlDesigner)), Description("Chart control for open flash chart"), ToolboxData("<{0}:OpenFlashChartControl runat=\"server\" ></{0}:OpenFlashChartControl>")]
    public class OpenFlashChartControl : Control
    {
        private string width;
        private string height;
        private string externalSWFfile;
        private string externalSWFObjectFile;
        private string loadingmsg;
        private OpenFlashChart chart;
        private string chart_json;
        private bool _enableCache;
        /// <summary>
        /// Used to hold internal chart
        /// </summary>
        public OpenFlashChart Chart
        {
            get
            {
                return chart;
            }
            set
            {
                chart = value;
                chart_json = value.ToString();
                ViewState["chart_json"] = chart_json;
            }
        }
       
        private string ChartJson
        {
            get
            {
                if (ViewState["chart_json"] != null)
                    return ViewState["chart_json"].ToString();
                return chart_json;
            }
        }
        private string datafile;

        [DefaultValue("600px")]
        [Category("Appearance")]
        [PersistenceMode(PersistenceMode.Attribute)]
        public string Width
        {
            get
            {
                width = "600px";
                if (this.ViewState["width"] != null)
                {
                    width = this.ViewState["width"].ToString();
                }
                return width;
            }
            set
            {
                if (!value.EndsWith("%") && !value.EndsWith("px"))
                    value = value + "px";
                this.ViewState["width"] = value;
                width = value;
            }
        }
        [DefaultValue("300px")]
        [Category("Appearance")]
        [PersistenceMode(PersistenceMode.Attribute)]
        public string Height
        {
            get
            {
                height = "300px";
                if (this.ViewState["height"] != null)
                {
                    height = this.ViewState["height"].ToString();
                }
                return height;
            }
            set
            {
                if (!value.EndsWith("%") && !value.EndsWith("px"))
                    value = value + "px";
                this.ViewState["height"] = value;
                height = value;
            }
        }

        [Category("Appearance")]
        [PersistenceMode(PersistenceMode.Attribute)]
        public string ExternalSWFfile
        {
            get
            {
                if (this.ViewState["externalswffile"] != null)
                {
                    externalSWFfile = this.ViewState["externalswffile"].ToString();
                }
                if (!string.IsNullOrEmpty(externalSWFfile))
                {
                    if (externalSWFfile.StartsWith("~"))
                    {
                        externalSWFfile = this.ResolveUrl(externalSWFfile);
                    }
                }
                return externalSWFfile;
            }
            set
            {
                this.ViewState["externalswffile"] = value.Trim();
                externalSWFfile = value.Trim();
            }
        }
        [Category("Appearance")]
        [PersistenceMode(PersistenceMode.Attribute)]
        public string ExternalSWFObjectFile
        {
            get
            {
                if (this.ViewState["externalswfobjectfile"] != null)
                {
                    externalSWFObjectFile = this.ViewState["externalswfobjectfile"].ToString();
                }
                if (!string.IsNullOrEmpty(externalSWFObjectFile))
                {
                    if (externalSWFObjectFile.StartsWith("~"))
                    {
                        externalSWFObjectFile = this.ResolveUrl(externalSWFObjectFile);
                    }
                }
                return externalSWFObjectFile;
            }
            set
            {
                this.ViewState["externalswfobjectfile"] = value.Trim();
                externalSWFObjectFile = value.Trim();
            }
        }


        public string DataFile
        {
            get
            {
                if (this.ViewState["datafile"] != null)
                {
                    datafile = this.ViewState["datafile"].ToString();
                }
                if (!string.IsNullOrEmpty(datafile))
                {
                    if (datafile.StartsWith("~"))
                    {
                        datafile = this.ResolveUrl(datafile);
                    }
                }

                return datafile;
            }
            set
            {
                this.ViewState["datafile"] = value;
                datafile = value;
            }
        }

        public string LoadingMsg
        {
            get { return loadingmsg; }
            set { loadingmsg = value; }
        }

        public bool EnableCache
        {
            get { return _enableCache; }
            set { _enableCache = value; }
        }

        protected override void OnInit(EventArgs e)
        {
            const string key = "swfobject";
            string swfobjectfile = ExternalSWFObjectFile;
            if (string.IsNullOrEmpty(ExternalSWFObjectFile))
                swfobjectfile = Page.ClientScript.GetWebResourceUrl(this.GetType(), "OpenFlashChart.swfobject.js");
            
            if (!this.Page.ClientScript.IsClientScriptBlockRegistered(key))
            {
                this.Page.ClientScript.RegisterClientScriptBlock(this.Page.GetType(), key, "<script type=\"text/javascript\" src=\"" + swfobjectfile + "\"></script>");
            }
            base.OnInit(e);
        }
        public override void RenderControl(HtmlTextWriter writer)
        {
            StringBuilder builder = new StringBuilder();
            if (string.IsNullOrEmpty(ExternalSWFfile))
                ExternalSWFfile = Page.ClientScript.GetWebResourceUrl(this.GetType(), "OpenFlashChart.open-flash-chart.swf");
            builder.AppendFormat("<div id=\"{0}\">", this.ClientID);
            builder.AppendLine("</div>");
            builder.AppendLine("<script type=\"text/javascript\">");
            builder.AppendFormat("swfobject.embedSWF(\"{0}\", \"{1}\", \"{2}\", \"{3}\",\"9.0.0\", \"expressInstall.swf\",",
                ExternalSWFfile, this.ClientID, Width, Height);
            builder.Append("{\"data-file\":\"");
            //if both chart,datafile exists ,chart win.
            if (ChartJson != null)
            {
                if (!EnableCache)
                    Page.Cache.Remove(this.ClientID);
                Page.Cache.Add(this.ClientID, ChartJson, null, Cache.NoAbsoluteExpiration, new TimeSpan(0, 10, 0),
                              CacheItemPriority.Normal, null);
                builder.Append("ofc_handler.aspx?chartjson=" + this.ClientID + "%26ec=" + (EnableCache ? "1" : "0"));
            }
            else
                builder.Append(HttpUtility.UrlEncode(DataFile));
            builder.Append("\"");
            if (!string.IsNullOrEmpty(loadingmsg))
            {
                builder.AppendFormat(",\"loading\":\"{0}\"", loadingmsg);
            }
            builder.Append("});");
            builder.AppendLine("</script>");
           
            writer.Write(builder.ToString());
            base.RenderControl(writer);
        }
    }
}
