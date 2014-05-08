part of conceptnetgraph;

class ConceptNetGraph {

  String searchKey;
  String searchLang;
  
 GraphRenderer graph;
  ConceptNetGraph() {
   initData();
   
   graph = new GraphRenderer(this);
   
  }
  
  Map root;
  Map mapConceptWorld;
  initData() {
   root = {};
   mapConceptWorld = {};
   listEdgeObj = new List<EdgeObject>();
  }
  
  init(dynamic stage){
   graph.init(stage);
  }

  String conceptKey;
  appendTo(Map data, {Map appendTarget, String conceptKey}) {

    // append to root
    if (appendTarget == null) {
    }

    // set input key
    if (this.conceptKey != null) {
     this.conceptKey = conceptKey;
    }
    
    // render edges
    renderEdges(data , conceptKey);

  }


  List<EdgeObject> listEdgeObj;
  int conceptNumFound;
  renderEdges(Map data, String conceptKey) {
   
   listEdgeObj = [];
   // parse to model
    conceptNumFound = data['numFound'];
    log("-----------------------");
    log("number found: $conceptNumFound");
    List edges = data['edges'];
    for (Map edge in edges) {
      EdgeObject obj = new EdgeObject(edge , conceptKey);
      listEdgeObj.add(obj);
      log("${obj.edgeStart} --> ${obj.edgeRel} --> ${obj.edgeEnd} (${obj.edgeSurface})");
    }

    // parse visual
    graph.renderEdges(listEdgeObj , conceptKey);
    
  }

  // set log interface
  Function log;
  setLogDisplay(Function input) {
    log = input;
  }

  
  render() {
   graph.render();
  }
  
  resize() {
   graph.resize();
  }
  
  String getSearchAPI(String key , String lang) {
    searchKey = key;
    searchLang = lang;
  return "/search?start=/c/${searchLang}/${searchKey}&limit=30";
  }
  
}

class EdgeObject {
 Map data;
 String conceptKey;
 // for local use
  String edgeStart;
  String edgeEnd;
  String edgeRel;
  String edgeSurface;
  String plainSurface;
  int keyIndex;
  var view;
  TextField relView;
 EdgeObject(this.data , this.conceptKey){
  
  // parse info
  edgeStart = (data['start'] as String);
  keyIndex = edgeStart.lastIndexOf(conceptKey);
  if(keyIndex!=-1) edgeStart = edgeStart.substring(keyIndex);
  
  edgeEnd = (data['end'] as String);
  keyIndex = edgeEnd.lastIndexOf("/");
  if(keyIndex!=-1) edgeEnd = edgeEnd.substring(keyIndex+1);
  
  edgeRel = (data['rel'] as String);
  keyIndex = edgeRel.lastIndexOf("/");
  if(keyIndex!=-1) edgeRel = edgeRel.substring(keyIndex+1);
  
  surface = data['surfaceText'];
 }
  
 set surface(String text) {
//      edgeSurface = (edge['surfaceText'] as String)
//        ..replaceAll(new RegExp(r'/[/['), "")
//        ..replaceAll(new RegExp(r'/]/]'), "");
  edgeSurface = text;
  if(text!=null){
   // TODO: learn regex more 
   // filter out all non-latin words
//   plainSurface = text.replaceAll(new RegExp(r'[\W_]'), " "); 
   // this is faster
   plainSurface = text.replaceAll(new RegExp(r'[/\[/\]]'), " "); 
  }
 }
 
  setSprite(dynamic view) {
   this.view = view;
  }
  
  setRel(dynamic view) {
   this.relView = view;
  }
}
class RelationObject {
 
}


