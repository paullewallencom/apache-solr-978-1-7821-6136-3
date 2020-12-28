/*
   Copyright 2011 David Smiley -- david.w.smiley at gmail.com

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
(function ($) {

AjaxSolr.AutocompleteTermWidget = AjaxSolr.AbstractTextWidget.extend({
  init: function () {
    var self = this;

    $(this.target).find('input').bind('keydown', function(e) {
      if (e.which == 13) {
        var q = $(this).val();
        if (self.set(q)) {
          self.manager.doRequest(0);
        }
      }
    });
    
    $(this.target).find('input').autocomplete({
      source: function( request, response ) {
        var field = self.field;
        
        //**Note: The /termsSuggest2 request handler already has most of the parameters we want.**
        var params = {};
        //-- take the query string and split out the last word from the words before it.
        var qInput = $(self.target).find('input').val().trim();
        var qFilter = "";//before the last word
        var qPrefix = qInput;//the last word
        var lastSpace = qInput.lastIndexOf(' ');
        if (lastSpace > -1) {
          qFilter = qInput.substring(0,lastSpace);
          qPrefix = qInput.substring(lastSpace+1);
          params['fq'] = self.field + ':' + AjaxSolr.Parameter.escapeValue(qFilter);//this phrases it,
        }
        qPrefix = qPrefix.toLowerCase();
        
        //get filter queries in effect now
        var fqsUrl = '';
        var storeParamsFq = self.manager.store.params['fq'];
        if (storeParamsFq !== undefined) {
          for (var i = 0, l = storeParamsFq.length; i < l; i++) {
            fqsUrl += '&'+storeParamsFq[i].string();
          }
        }

        
        //Note that the field must be analyzed appropriately for this to work well (no stemming). We will suffice with minimal stemming
        // for the sake of this demo but keep this in mind for doing things the right way.
        params['facet.field'] = field;
        params['facet.prefix'] = qPrefix;
                
        $.ajax({
          url: self.manager.solrUrl + 'termsSuggest2?wt=json&json.nl=arrarr&json.wrf=?'+fqsUrl,
          dataType: "jsonp",
          data: params,
          success: function( data ) {
            response( $.map( data.facet_counts.facet_fields[field], function( term ) {
              var q = (qFilter ? qFilter + " " : "") + term[0];
              return {
                label: q + " (" + term[1] + ")",
                value: q,
              }
            }));
          }
        });
      },
      minLength: 2,
      select: function( event, ui ) {
        if (self.set(ui.item.value)) {
          self.manager.doRequest(0);
        }      
      },
    });

  },

});

})(jQuery);
