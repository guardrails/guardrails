using System;
using System.Collections.Generic;
using System.Text;

namespace JsonFx.Json
{
    [AttributeUsage(AttributeTargets.All, AllowMultiple=false)]
    public class JsonPropertyAttribute:JsonNameAttribute
    {
        public JsonPropertyAttribute():base()
        { }
        public JsonPropertyAttribute(string jsonname):base(jsonname)
        {
            
        }
    }
}
