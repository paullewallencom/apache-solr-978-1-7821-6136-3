/*
  This script will update documents with a *_id field.
  The prefix will be the first letter of the existing id field, lowercased.
  In order to use this script, The solrconfig.xml must configure a updateRequestProcessorChain,
  and configure it to use this script.
  To trigger the behavior in this script during indexing,
  the update request must include the name of the processor chain in an update.chain param: 

  update.chain=script
*/
function processAdd(cmd) {
    var doc = cmd.solrDoc;
    var id = doc.getFieldValue("id");
    var matches = id.match(/^([A-Z].*):([0-9]+)$/);
    if(matches){
	var fname = matches[1].charAt(0).toLowerCase() + "_id";
	logger.debug("update-script#processAdd: field / id => " + fname + " / " + matches[2]);
	doc.setField(fname, matches[2]);
    }
}

function processDelete(cmd) {
    // no-op
}

function processMergeIndexes(cmd) {
    // no-op
}

function processCommit(cmd) {
    // no-op
    logger.debug("update-script#processCommit");
}

function finish() {
    // no-op
    logger.info("update-script#finish");
}
