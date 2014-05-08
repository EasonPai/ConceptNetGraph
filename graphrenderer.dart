part of conceptnetgraph;

class GraphRenderer {
 
 ConceptNetGraph container;
 Stage stage;

 GraphRenderer(this.container) {
 }

 init(dynamic stage) {
  this.stage = stage;
  isEdgeReady = false;
  initView();
  initCanvas();
 }

 BitmapData canvasBitmapData;
 Shape canvas;
 // init canvas
 initCanvas() {
  canvas = new Shape();
  canvas.addTo(stage);
  canvas.applyCache(0, 0, stage.stageWidth, stage.stageHeight);
  canvasBitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, true, 0);
  Bitmap canvasCache = new Bitmap(canvasBitmapData);
  canvasCache.addTo(stage);
  
//  canvas.filters = [new DropShadowFilter( 4 , 45 * PI / 180.0 , Color.Black, 4, 4)];
 }

 resize() {
  canvas.applyCache(0, 0, stage.stageWidth, stage.stageHeight, debugBorder: true);
 }

 Sprite mConceptKey;
 List<EdgeObject> listEdgeObj;
 bool isEdgeReady;
 renderEdges(List edges, String conceptKey) {
  isEdgeReady = true;
  if (conceptKey != null) {
   mConceptKey = createNerue(conceptKey);
   mConceptKey.x = 900 / 2;
   mConceptKey.y = 500 / 2;
   mConceptKey.onMouseDown.listen((e) {
    e.target.startDrag(false);
    for (var i = 0; i < listEdgeObj.length; i++) {
     listEdgeObj[i].view.mouseEnabled =  false;
    }
   });
   mConceptKey.onMouseUp.listen((e) {
    e.target.stopDrag();
    for (var i = 0; i < listEdgeObj.length; i++) {
     listEdgeObj[i].view.mouseEnabled =  true;
    }
   });
   mConceptKey.onMouseMove.listen((e) {
    performAutoGraphLayout(0.4, 0.002, true, TransitionFunction.easeOutExponential);
   });
   stage.addChild(mConceptKey);
  }

  listEdgeObj = edges;

  // edge iteration
  for (var i = 0; i < listEdgeObj.length; i++) {

   // edge
   Sprite nerue = createNerue(listEdgeObj[i].edgeEnd);
   nerue.x = 900 / 2;
   nerue.y = 500 / 2;
   // TODO: 
   // filter effect is cool, but performance is not too good
   // nerue.filters = [new DropShadowFilter( 4 , 45 * PI / 180.0 , Color.Black, 4, 4)];
   stage.addChild(nerue);
   listEdgeObj[i].setSprite(nerue);
   nerue.onMouseClick.listen((e) {
//    if(listEdgeObj[i].edgeSurface!=null){
     
     // call js nofity lib
//     notify(listEdgeObj[i].edgeSurface);
     notify(listEdgeObj[i].plainSurface);
//    }
   });

   // relation
   TextField rel = createRel(listEdgeObj[i].edgeRel);
   rel.addTo(stage);
   listEdgeObj[i].setRel(rel);
  }

  enterLayoutEffect(1.2, 0.02, false, TransitionFunction.easeOutElastic);

  debutText.text = "item num: ${stage.numChildren}";
 }

 enterLayoutEffect(num time, num delay, bool random, Function transition) {
  double posX = 0.0;
  double posY = 0.0;
  for (var i = 0; i < listEdgeObj.length; i++) {
     // pose circle
     posY = sin(2 * PI * i / listEdgeObj.length);
     posX = cos(2 * PI * i / listEdgeObj.length);

     listEdgeObj[i].view.alpha = 0.4;
     stage.juggler.tween(listEdgeObj[i].view, time, TransitionFunction.easeOutExponential)
     ..delay = delay * i
     ..animate.x.to(mConceptKey.x + posX * 260)
     ..animate.alpha.to(1);
     
     stage.juggler.tween(listEdgeObj[i].view, time, transition)
       ..delay = random ? listEdgeObj[i].edgeEnd.length * 0.005 : delay * i
       //       ..delay = random? rng.nextInt(20)/1000 : delay*i
       //        ..delay = 0.03*i + rng.nextInt(10)/100
       ..animate.y.to(mConceptKey.y + posY * 260);

     print(listEdgeObj[i].view.name);
     new HttpRequest()
                  ..open("POST", "http://dartserver.herokuapp.com/conceptnet")
                  ..onReadyStateChange.listen((event) {
                          if (event.target.readyState == HttpRequest.DONE) {
//                           print(JSON.decode(event.target.responseText)['numFound']);
//                           stage.juggler.tween((listEdgeObj[i].view as Sprite).getChildAt(0), time, transition)
//                                  ..animate.scaleX.to(1.4)
//                                  ..animate.scaleY.to(1.4);
                          }
                        })
                  ..send("search?start=/c/zh_TW/${listEdgeObj[i].view.name}"); // success
    }
 }
 
 // layout mechanism
 // TODO: using tween is slow-some
 performAutoGraphLayout(num time, num delay, bool random, Function transition) {

  var rng = new Random();
  double posX = 0.0;
  double posY = 0.0;

  for (var i = 0; i < listEdgeObj.length; i++) {
   // pose circle
   posY = sin(2 * PI * i / listEdgeObj.length);
   posX = cos(2 * PI * i / listEdgeObj.length);

   stage.juggler.tween(listEdgeObj[i].view, time, transition)
     ..delay = random ? listEdgeObj[i].edgeEnd.length * 0.005 : delay * i
     //       ..delay = random? rng.nextInt(20)/1000 : delay*i
     //        ..delay = 0.03*i + rng.nextInt(10)/100
     ..animate.x.to(mConceptKey.x + posX * 260)
     ..animate.y.to(mConceptKey.y + posY * 260);

  }
 }

 TextField createRel(String rel) {
  return new TextField()
    ..defaultTextFormat = nerueTextFormat
    ..x = 0
    ..y = 12
    ..width = rel.length * 2
    ..height = 30
    ..cacheAsBitmap = true
    ..autoSize = TextFieldAutoSize.CENTER
    ..mouseEnabled = false
    ..text = rel;
 }

 renderRel() {

  canvas.graphics.clear();
  for (EdgeObject edge in listEdgeObj) {
   canvas.graphics.moveTo(mConceptKey.x + mConceptKey.width / 2, mConceptKey.y + mConceptKey.height / 2);
   canvas.graphics.lineTo(edge.view.x + edge.view.width / 2, edge.view.y + edge.view.height / 2);

   edge
     ..relView.x = ((mConceptKey.x + mConceptKey.width) / 2 + (edge.view.x + edge.view.width / 2)) / 2
     ..relView.y = ((mConceptKey.y + mConceptKey.height / 2) + (edge.view.y + edge.view.height / 2)) / 2;

   edge.relView.rotation = atan2(mConceptKey.y - edge.view.y, mConceptKey.x - edge.view.x);
   
  }
  canvas.graphics.strokeColor( GraphColor.Blue , 1);
  canvas.refreshCache();

 }

 Sprite createNerue(String edgeName) {
  Sprite nerue = new Sprite();
  
  nerue.graphics.beginPath();
  nerue.graphics.rect(0,0, 50 , 50);
  nerue.graphics.closePath();
  nerue.graphics.fillColor( GraphColor.AlphaBlack );
  nerue.applyCache( 0, 0, 50, 50, debugBorder: true);
  nerue.name = edgeName;
  Bitmap cytoderm = new Bitmap(createShellBitmapData());
  cytoderm.x = - cytoderm.width/2;
  cytoderm.y = - cytoderm.height/2;
  nerue.addChild(cytoderm);
//  print("cytoderm.width , cytoderm.height : ${cytoderm.width} / ${cytoderm.height}");

  TextField edgeText = new TextField()
    ..defaultTextFormat = nerueTextFormat
    ..x = 0
    ..width = cytoderm.width
    ..height = cytoderm.height
    ..cacheAsBitmap = false
    ..autoSize = TextFieldAutoSize.CENTER
    ..mouseEnabled = false
//    ..wordWrap = true
    ..text = edgeName
//    ..border = true
    ..addTo(nerue);
  edgeText.y = (cytoderm.height - edgeText.height)/2;

  nerue.onMouseDown.listen((e) {
   e.target.startDrag(false);
  });
  nerue.onMouseUp.listen((e) {
   e.target.stopDrag();
  });

  return nerue;
 }

 TextFormat nerueTextFormat;
 TextFormat debugTextFormat;
 TextField debutText;
 initView() {
  var font = "Open Sans, Helvetica Neue, Helvetica, Arial, sans-serif";
  nerueTextFormat = new TextFormat(font, 12, Color.Black, bold: false);
  debugTextFormat = new TextFormat(font, 12, Color.Black, bold: true);

  debutText = new TextField()
    ..defaultTextFormat = debugTextFormat
    ..x = 10
    ..y = 12
    ..width = 120
    ..height = 50
    ..cacheAsBitmap = false
    ..autoSize = TextFieldAutoSize.LEFT
    ..mouseEnabled = false
    ..text = ""
    ..addTo(stage);
 }

 BitmapData cytoderm_cache;
 Random rngColor = new Random();
 BitmapData createShellBitmapData() {

  if (cytoderm_cache != null) {
   return cytoderm_cache;
  }
  // create cell view
  var cytoderm = new Shape();
  cytoderm.graphics.beginPath();

//  cytoderm.graphics.rectRound(4, 4, 100, 40, 10, 10);
  cytoderm.graphics.circle(25, 25, 25);
  cytoderm.graphics.closePath();
  cytoderm.graphics.fillColor( GraphColor.Blue );
//  cytoderm.graphics.fillColor(  0xFF000000 |  new Random().nextInt(256) << 2 );
//  cytoderm.graphics.strokeColor(Color.AntiqueWhite, 4);

  // render area
//  cytoderm.applyCache( 0, 0, 80, 80, debugBorder: false);

  cytoderm_cache = new BitmapData( 50, 50, true, 0);
  cytoderm_cache.draw(cytoderm);
  cytoderm.graphics.clear();
  return cytoderm_cache;
 }


 render() {
  if (!isEdgeReady) return;
  renderRel();
 }

}

class GraphColor {
  static const int AlphaBlack = 0x33374140;
 static const int Black = 0xFF374140;
 static const int Blue = 0xFFAFDADB;
}


//class Relation extends DisplayObjectContainer {
// Shape lineVector;
// Bitmap head;
// Relation() {
//  mouseEnabled = false;
//  lineVector = new Shape();
//  addChild(lineVector);
//
//  Shape headVector = new Shape();
//  headVector.graphics.beginPath();
//  headVector.graphics.moveTo(25, 10);
//  headVector.graphics.lineTo(0, 20);
//  headVector.graphics.quadraticCurveTo(10, 10, 0, 0);
//  //    headVector.graphics.lineTo(0,0);
//  headVector.graphics.lineTo(25, 10);
//  headVector.graphics.closePath();
//  headVector.graphics.fillColor(Color.Black);
//
//  // Being tested that cache with BitmapData improves performance
//  BitmapData canvasBitmapData = new BitmapData(25, 20, true, 0);
//  canvasBitmapData.draw(headVector);
//  headVector.graphics.clear();
//
//  head = new Bitmap(canvasBitmapData);
//  head
//    ..pivotX = 25
//    ..pivotY = 10;
//  addChild(head);
//
// }
//
// var startpoint;
// var endpoint;
// var bodyLength;
// void pointTo(int x, int y, int x2, int y2) {
//  startpoint = new Point(x, y);
//  endpoint = new Point(x2, y2);
//  bodyLength = startpoint.distanceTo(endpoint);
//
//  lineVector.graphics.clear();
//  lineVector.graphics.beginPath();
//  lineVector.graphics.moveTo(x, y);
//  lineVector.graphics.lineTo(x2 - (head.width / bodyLength) * (x2 - x), y2 - (head.width / bodyLength) * (y2 - y));
//  lineVector.graphics.closePath();
//  lineVector.graphics.strokeColor(Color.Black, 5, JointStyle.BEVEL, CapsStyle.SQUARE);
//  head.rotation = atan2(y2 - y, x2 - x);
//  head.x = x2;
//  head.y = y2;
// }
//
// void endDraw() {
//
//  print('${lineVector.width} , ${lineVector.height}');
//  BitmapData bitmapData = new BitmapData(800, 500, true, 0);
//  bitmapData.draw(lineVector);
//  Bitmap body = new Bitmap(bitmapData);
//  //   body ..x = startpoint.x ..y = startpoint.y;
//  addChild(body);
//  lineVector.graphics.clear();
//  removeChild(lineVector);
//
// }
//}
