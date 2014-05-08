// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the COPYING file.

library conceptnetgraph;

import 'dart:html';
import 'package:stagexl/stagexl.dart';
import 'package:stats/stats.dart';
import 'dart:convert';
import 'package:bootjack/bootjack.dart';
import 'dart:js';
import 'dart:math';

part 'conceptnetgraph.dart';
part 'graphrenderer.dart';


var api_url_str = "http://dartserver.herokuapp.com/conceptnet";
// debug
//var api_url = "http://0.0.0.0:9999/conceptnet";

void main() {
  Bootjack.useDefault(); // use all
  initUI();
  initCanvas();
  initListeners();
  initConceptNet();
  initLoop();
  initUtils();
}



ConceptNetGraph conceptnet;
initConceptNet() {
  conceptnet = new ConceptNetGraph();
  conceptnet.init(stage);
}
initUtils() {
  conceptnet.setLogDisplay(log);
}

Stage stage;
RenderLoop renderLoop = new RenderLoop();
Sprite touchDetector;
Shape shapCanvas;
BitmapData bitmapDataCanvas;
num stageWidth, stageHeight;
initCanvas() {
  // setup html canvas & stage
  stage = new Stage(document.querySelector('#stage'), webGL: true);
  stage.scaleMode = StageScaleMode.NO_SCALE;
  stage.align = StageAlign.TOP_LEFT;
  renderLoop.addStage(stage);

  stageWidth = num.parse(document.querySelector('#stage').getAttribute('width'));
  stageHeight = num.parse(document.querySelector('#stage').getAttribute('height'));

  stage.onResize.listen((e) {
    conceptnet.resize();
    //   (document.querySelector('#stage') as CanvasElement).width = document.window.
    //   stageWidth = num.parse(document.querySelector('#stage').getAttribute('width'));
    //   stageHeight = num.parse(document.querySelector('#stage').getAttribute('height'));
    //   log('stageWidth/stageHeight > ${stageWidth} / ${stageHeight}');
    //     log('stage.width stage.height > ${stage.width} / ${stage.height}');

    //   touchDetector.graphics.clear();
    //   touchDetector.graphics.beginPath();
    //     touchDetector.graphics.rect(0, 0, stageWidth, stageHeight);
    //     touchDetector.graphics.closePath();
    //     touchDetector.graphics.fillColor(Color.LightGreen);
    //     touchDetector.graphics.strokeColor(Color.LightGray, 5);
    //     touchDetector.applyCache(0, 0, stageWidth, stageHeight);
  });
  // add bg
  touchDetector = new Sprite();
  touchDetector.graphics.beginPath();
  touchDetector.graphics.rect(0, 0, stageWidth, stageHeight);
  touchDetector.graphics.closePath();
  touchDetector.graphics.fillColor(Color.WhiteSmoke);
  touchDetector.applyCache(0, 0, stageWidth, stageHeight);
  touchDetector.addTo(stage);

  // setup canvas
  shapCanvas = new Shape();
  shapCanvas.addTo(stage);
  bitmapDataCanvas = new BitmapData(stageWidth, stageHeight, true, 0);
  Bitmap bitmapCanvasCache = new Bitmap(bitmapDataCanvas);
  //  bitmapCanvasCache.addTo(stage);
}

Modal modalConceptnetJson;
String stringConceptnetJson;
TextAreaElement textAreaResult;

JsObject mJsRoot;
InputElement search_text;
SelectElement select_language;
String searchAPI;
ButtonElement btnGetConcept;
initUI() {

  //TODO: solve stage blink problem
  // document.querySelector('#stage').style.removeProperty('display');
  // -------------------------------------------------------------------------
  // setup javascript
  // -------------------------------------------------------------------------
  mJsRoot = new JsObject(context['js_root']);
  mJsRoot.callMethod('init');
  
// find search key string
 search_text = querySelector("#search-text");
 select_language = querySelector("#language-select");
 btnGetConcept = querySelector("#get_concept");

  // setup modal ui
  textAreaResult = querySelector("#modal_conceptnet_json__textarea");
  Element elementJson = querySelector('#modal_conceptnet_json');
  modalConceptnetJson = new Modal(elementJson, backdrop: 'true', keyboard: true);

  btnGetConcept.onClick.listen((event) {
    btnGetConcept.disabled = true;
    event.preventDefault();
    mJsRoot.callMethod('start_progressjs', ["#search-text"]);
    
    searchAPI = conceptnet.getSearchAPI(search_text.value , select_language.value);

    HttpRequest httpRequest = new HttpRequest()
        ..open("POST", api_url_str)
        ..onReadyStateChange.listen((event) {
          if (event.target.readyState == HttpRequest.DONE) {
            mJsRoot.callMethod('end_progressjs', ["#search-text"]);
            btnGetConcept.disabled = false;
            stringConceptnetJson = event.target.responseText;
            textAreaResult.value = stringConceptnetJson;
            conceptnet.appendTo(JSON.decode(stringConceptnetJson), conceptKey: search_text.value);
          }
        })
        ..send(searchAPI); // success
  });
}


String findSearchKey(String api_string) {

  // String filterKey = "start=/c/en/";
  //        int startindex = api.indexOf(filterKey);
  //        if(startindex == -1){
  //         resultText.text = "api format malform!";
  //         return;
  //        }
  //        String searchKey = findSearchKey();
  //          api_string.substring(startindex + filterKey.length);
  return 'empty';
}

EventStreamSubscription listenerTouchDown;
initListeners() {
  // start listener
  listenerTouchDown = touchDetector.onMouseDown.listen((e) {
  });
}

initLoop() {
  // measure the fps
  Stats stats = new Stats();
  document.querySelector('#fpsMeter').append(stats.container);
  stage.onEnterFrame.listen((EnterFrameEvent e) {
    stats.end();
    stats.begin();
    conceptnet.render();
  });
}

notify(String msg) {
  mJsRoot.callMethod('notification', [msg]);
}

String logString = "";
var log = (var info) {
  logString += "\n" + info.toString();
  print(logString);
};
