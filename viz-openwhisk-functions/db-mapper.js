// Ignore deleted documents from Cloudant
function main(params) {
    if(params.deleted) {
        return { "error" : "Ignoring Deleted Document."};
    }
    params.docid = params.id;
    return params;
}
