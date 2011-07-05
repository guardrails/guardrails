using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Web;
using System.Web.UI;

namespace OpenFlashChart.WebHandler
{
   public class ofcHandler: IHttpHandler
    {
       /// <summary>
       /// Enables processing of HTTP Web requests by a custom HttpHandler that implements the <see cref="T:System.Web.IHttpHandler" /> interface.
       /// </summary>
       /// <param name="context">An <see cref="T:System.Web.HttpContext" /> object that provides references to the intrinsic server objects (for example, Request, Response, Session, and Server) used to service HTTP requests. </param>
       public void ProcessRequest(HttpContext context)
       {
           using (TextWriter writer = new HtmlTextWriter(context.Response.Output))
           {
               string chartID = context.Request.QueryString["chartjson"];
               if (chartID == null)
                   return;
               string chartjson = (string)context.Cache[chartID];
               context.Response.Clear();
               context.Response.CacheControl = "no-cache";
               
               writer.Write(chartjson);
           }
       }

       /// <summary>
       /// Gets a value indicating whether another request can use the <see cref="T:System.Web.IHttpHandler" /> instance.
       /// </summary>
       /// <returns>
       /// true if the <see cref="T:System.Web.IHttpHandler" /> instance is reusable; otherwise, false.
       /// </returns>
       public bool IsReusable
       {
           get { return true;}
       }
    }
}
